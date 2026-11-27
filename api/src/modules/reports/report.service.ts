import mongoose from 'mongoose';
import { Report, ModerationLog, type ReportTargetType } from './report.model.js';
import { ServiceRequest } from '../requests/request.model.js';
import { Quote } from '../quotes/quote.model.js';
import { Review } from '../reviews/review.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { Conversation, Message } from '../chat/chat.model.js';
import { NotFoundError } from '../../core/errors/app-error.js';
import { formatPaginatedResult, type PaginatedResult } from '../../core/utils/pagination.js';
import type {
  AdminReportsQuery,
  CreateReportInput,
  DismissReportInput,
} from './report.schema.js';

export class ReportService {
  private async fetchTargetSnapshot(
    targetType: ReportTargetType,
    targetId: string
  ): Promise<Record<string, unknown>> {
    if (targetType === 'request') {
      const reqDoc = await ServiceRequest.findById(targetId)
        .populate('clientId', 'fullName email')
        .lean();
      if (!reqDoc) throw new NotFoundError('Service request');
      const client = reqDoc.clientId as any;
      return {
        title: reqDoc.title,
        description: reqDoc.description,
        city: reqDoc.city,
        status: reqDoc.status,
        authorName: client?.fullName ?? null,
      };
    }

    if (targetType === 'review') {
      const reviewDoc = await Review.findById(targetId)
        .populate('clientId', 'fullName email')
        .lean();
      if (!reviewDoc) throw new NotFoundError('Review');
      const client = reviewDoc.clientId as any;
      return {
        rating: reviewDoc.rating,
        comment: reviewDoc.comment,
        artisanId: reviewDoc.artisanId?.toString(),
        authorName: client?.fullName ?? null,
      };
    }

    const messageDoc = await Message.findById(targetId)
      .populate('senderId', 'fullName email')
      .lean();
    if (!messageDoc) throw new NotFoundError('Message');
    const sender = messageDoc.senderId as any;
    return {
      text: messageDoc.text,
      conversationId: messageDoc.conversationId?.toString(),
      authorName: sender?.fullName ?? null,
    };
  }

  public async createReport(reporterId: string, input: CreateReportInput) {
    const targetSnapshot = await this.fetchTargetSnapshot(input.targetType, input.targetId);

    const report = await Report.create({
      reporterId,
      targetType: input.targetType,
      targetId: input.targetId,
      reason: input.reason,
      description: input.description ?? '',
      status: 'pending',
      targetSnapshot,
    });

    return report.populate('reporterId', 'fullName email role');
  }

  public async listReports(query: AdminReportsQuery): Promise<PaginatedResult<any>> {
    const { type, status, page, limit } = query;
    const filter: Record<string, any> = {};

    if (type) filter.targetType = type;
    if (status && status !== 'all') filter.status = status;

    const skip = (page - 1) * limit;

    const [reports, total] = await Promise.all([
      Report.find(filter)
        .populate('reporterId', 'fullName email role')
        .populate('resolvedBy', 'fullName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Report.countDocuments(filter),
    ]);

    // Batch-hydrate live targets so the admin moderation screen sees up-to-date content
    const requestIds = reports
      .filter((r) => r.targetType === 'request')
      .map((r) => r.targetId);
    const reviewIds = reports
      .filter((r) => r.targetType === 'review')
      .map((r) => r.targetId);
    const messageIds = reports
      .filter((r) => r.targetType === 'message')
      .map((r) => r.targetId);

    const [requests, reviews, messages] = await Promise.all([
      requestIds.length > 0
        ? ServiceRequest.find({ _id: { $in: requestIds } })
            .populate('clientId', 'fullName email')
            .populate('categoryId', 'name')
            .lean()
        : Promise.resolve([]),
      reviewIds.length > 0
        ? Review.find({ _id: { $in: reviewIds } })
            .populate('clientId', 'fullName email')
            .lean()
        : Promise.resolve([]),
      messageIds.length > 0
        ? Message.find({ _id: { $in: messageIds } })
            .populate('senderId', 'fullName email')
            .lean()
        : Promise.resolve([]),
    ]);

    const targetMap = new Map<string, any>();
    for (const item of [...requests, ...reviews, ...messages]) {
      targetMap.set(item._id.toString(), item);
    }

    const enriched = reports.map((report) => ({
      ...report,
      target: targetMap.get(report.targetId.toString()) ?? null,
    }));

    return formatPaginatedResult(enriched, total, page, limit);
  }

  public async updateReportStatus(
    reportId: string,
    adminId: string,
    input: DismissReportInput
  ) {
    const report = await Report.findById(reportId);
    if (!report) throw new NotFoundError('Report');

    report.status = input.status;
    report.resolvedBy = new mongoose.Types.ObjectId(adminId);
    report.resolvedAt = new Date();
    if (input.resolutionNote !== undefined) {
      report.resolutionNote = input.resolutionNote;
    }

    await report.save();

    await ModerationLog.create({
      adminId: new mongoose.Types.ObjectId(adminId),
      action: 'dismiss_report',
      targetType: 'report',
      targetId: report._id,
      reason: input.resolutionNote || 'Report dismissed by administrator',
      targetSnapshot: {
        reportedTargetType: report.targetType,
        reportedTargetId: report.targetId.toString(),
      },
    });

    return report.populate([
      { path: 'reporterId', select: 'fullName email role' },
      { path: 'resolvedBy', select: 'fullName email' },
    ]);
  }

  public async deleteContent(
    type: ReportTargetType,
    id: string,
    adminId: string,
    reason?: string
  ): Promise<void> {
    const targetSnapshot = await this.fetchTargetSnapshot(type, id);
    const effectiveReason = reason || 'Removed by administrator during moderation';

    if (type === 'request') {
      await ServiceRequest.deleteOne({ _id: id });
      await Quote.deleteMany({ requestId: id });
    } else if (type === 'review') {
      const review = await Review.findByIdAndDelete(id);
      if (review) {
        // Recalculate artisan's aggregate rating after review removal
        const remainingReviews = await Review.find({ artisanId: review.artisanId }).lean();
        const reviewsCount = remainingReviews.length;
        const avgRating =
          reviewsCount > 0
            ? Number(
                (
                  remainingReviews.reduce((sum, r) => sum + r.rating, 0) / reviewsCount
                ).toFixed(1)
              )
            : 0;

        await ArtisanProfile.findByIdAndUpdate(review.artisanId, {
          rating: avgRating,
          reviewsCount,
        });
      }
    } else if (type === 'message') {
      const deletedMsg = await Message.findByIdAndDelete(id);
      if (deletedMsg) {
        const latestMsg = await Message.findOne({ conversationId: deletedMsg.conversationId })
          .sort({ createdAt: -1 })
          .lean();
        await Conversation.findByIdAndUpdate(deletedMsg.conversationId, {
          lastMessage: latestMsg ? latestMsg.text : '',
          lastMessageAt: latestMsg ? latestMsg.createdAt : new Date(),
        });
      }
    }

    await Report.updateMany(
      { targetType: type, targetId: id, status: 'pending' },
      {
        status: 'action_taken',
        resolvedBy: new mongoose.Types.ObjectId(adminId),
        resolvedAt: new Date(),
        resolutionNote: effectiveReason,
      }
    );

    await ModerationLog.create({
      adminId: new mongoose.Types.ObjectId(adminId),
      action: 'delete_content',
      targetType: type,
      targetId: new mongoose.Types.ObjectId(id),
      reason: effectiveReason,
      targetSnapshot,
    });
  }

  public async listModerationLogs(page = 1, limit = 20): Promise<PaginatedResult<any>> {
    const safeLimit = Math.min(Math.max(limit, 1), 50);
    const safePage = Math.max(page, 1);
    const skip = (safePage - 1) * safeLimit;

    const [logs, total] = await Promise.all([
      ModerationLog.find()
        .populate('adminId', 'fullName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(safeLimit)
        .lean(),
      ModerationLog.countDocuments(),
    ]);

    return formatPaginatedResult(logs, total, safePage, safeLimit);
  }
}

export const reportService = new ReportService();
