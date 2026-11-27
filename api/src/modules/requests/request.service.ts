import mongoose from 'mongoose';
import { ServiceRequest, type IServiceRequest } from './request.model.js';
import { Quote } from '../quotes/quote.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { Review } from '../reviews/review.model.js';
import { NotFoundError, ForbiddenError, ConflictError } from '../../core/errors/app-error.js';
import { formatPaginatedResult, type PaginatedResult } from '../../core/utils/pagination.js';
import { wsManager } from '../../core/websocket/ws-server.js';
import { notificationService } from '../notifications/notification.service.js';
import type { CreateRequestInput, UpdateRequestInput, RequestQuery } from './request.schema.js';

type Role = 'client' | 'artisan' | 'admin';
type Status = IServiceRequest['status'];

const CLIENT_FIELDS = 'fullName email phone profilePicture';
const CATEGORY_FIELDS = 'name slug icon';

/** Allowed status transitions. `completed` and `cancelled` are terminal. */
const TRANSITIONS: Record<Status, Status[]> = {
  pending: ['cancelled'],
  accepted: ['in_progress', 'completed', 'cancelled'],
  in_progress: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
};

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const QUOTE_ARTISAN_POPULATE = {
  path: 'artisanId',
  populate: [
    { path: 'userId', select: 'fullName email phone profilePicture isVerified' },
    { path: 'category', select: 'name' },
  ],
};

export class ServiceRequestService {
  /** Adds quotesCount, the accepted quote and (for artisans) their own quote to each request. */
  private async enrich(requests: any[], viewerRole?: Role, artisanProfileId?: string) {
    if (requests.length === 0) return requests;
    const ids = requests.map((r) => r._id);

    const [counts, accepted, mine, reviews] = await Promise.all([
      Quote.aggregate([
        { $match: { requestId: { $in: ids } } },
        { $group: { _id: '$requestId', count: { $sum: 1 } } },
      ]),
      Quote.find({ requestId: { $in: ids }, status: 'accepted' }).populate(QUOTE_ARTISAN_POPULATE).lean(),
      viewerRole === 'artisan' && artisanProfileId
        ? Quote.find({ requestId: { $in: ids }, artisanId: artisanProfileId }).lean()
        : Promise.resolve([]),
      Review.find({ requestId: { $in: ids } }).select('requestId rating comment createdAt').lean(),
    ]);

    const countBy = new Map(counts.map((c) => [c._id.toString(), c.count as number]));
    const acceptedBy = new Map(accepted.map((q) => [q.requestId.toString(), q]));
    const mineBy = new Map((mine as any[]).map((q) => [q.requestId.toString(), q]));
    const reviewBy = new Map(reviews.map((r) => [r.requestId.toString(), r]));

    return requests.map((r) => ({
      ...r,
      quotesCount: countBy.get(r._id.toString()) ?? 0,
      acceptedQuote: acceptedBy.get(r._id.toString()) ?? null,
      review: reviewBy.get(r._id.toString()) ?? null,
      ...(viewerRole === 'artisan' ? { myQuote: mineBy.get(r._id.toString()) ?? null } : {}),
    }));
  }

  private async artisanProfileOf(userId: string) {
    return ArtisanProfile.findOne({ userId }).select('_id category city').lean();
  }

  public async list(query: RequestQuery, currentUserId?: string, userRole?: Role): Promise<PaginatedResult<any>> {
    const { page, limit, search, city, categoryId, status, scope, allCategories } = query;
    const filter: Record<string, any> = {};
    let artisanProfileId: string | undefined;

    if (userRole === 'client') {
      // A client only ever sees their own requests.
      filter.clientId = currentUserId;
    } else if (userRole === 'artisan') {
      const profile = await this.artisanProfileOf(currentUserId!);
      if (!profile) throw new ForbiddenError('Artisan profile not found');
      artisanProfileId = profile._id.toString();

      if (scope === 'missions') {
        const acceptedQuotes = await Quote.find({ artisanId: profile._id, status: 'accepted' })
          .select('requestId')
          .lean();
        filter._id = { $in: acceptedQuotes.map((q) => q.requestId) };
      } else {
        filter.status = 'pending';
        if (!categoryId && allCategories !== 'true' && profile.category) {
          filter.categoryId = profile.category;
        }
      }
    }

    if (city) filter.city = new RegExp(escapeRegex(city), 'i');
    if (categoryId) filter.categoryId = categoryId;
    if (status && !(userRole === 'artisan' && scope !== 'missions')) filter.status = status;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [{ title: regex }, { description: regex }];
    }

    const skip = (page - 1) * limit;
    const [requests, total] = await Promise.all([
      ServiceRequest.find(filter)
        .populate('clientId', CLIENT_FIELDS)
        .populate('categoryId', CATEGORY_FIELDS)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      ServiceRequest.countDocuments(filter),
    ]);

    const enriched = await this.enrich(requests, userRole, artisanProfileId);
    return formatPaginatedResult(enriched, total, page, limit);
  }

  /** Object-level read authorization (A7). */
  public async getById(id: string, userId?: string, userRole?: Role) {
    const request = await ServiceRequest.findById(id)
      .populate('clientId', CLIENT_FIELDS)
      .populate('categoryId', CATEGORY_FIELDS)
      .lean();
    if (!request) throw new NotFoundError('Service request');

    let artisanProfileId: string | undefined;
    if (userRole === 'client' && (request.clientId as any)._id.toString() !== userId) {
      throw new ForbiddenError('You can only view your own service requests');
    }
    if (userRole === 'artisan') {
      const profile = await this.artisanProfileOf(userId!);
      if (!profile) throw new ForbiddenError('Artisan profile not found');
      artisanProfileId = profile._id.toString();
      const hasQuoted = await Quote.exists({ requestId: request._id, artisanId: profile._id });
      if (request.status !== 'pending' && !hasQuoted) {
        throw new ForbiddenError('This request is no longer open');
      }
    }

    const [enriched] = await this.enrich([request], userRole, artisanProfileId);
    return enriched;
  }

  public async create(clientId: string, data: CreateRequestInput) {
    const request = await ServiceRequest.create({
      clientId,
      categoryId: data.categoryId,
      title: data.title,
      description: data.description,
      city: data.city,
      address: data.address || '',
      photos: data.photos || [],
      status: 'pending',
    });

    const populated = await request.populate([
      { path: 'clientId', select: 'fullName email phone' },
      { path: 'categoryId', select: CATEGORY_FIELDS },
    ]);

    // Only artisans of the matching category are told about a new request.
    const artisans = await ArtisanProfile.find({ category: data.categoryId }).select('userId').lean();
    const artisanUserIds = artisans.map((a) => a.userId.toString());
    for (const uid of artisanUserIds) {
      wsManager.broadcastToUser(uid, 'request:created', populated);
    }
    await notificationService.notifyMany(artisanUserIds, {
      type: 'request:new',
      title: 'Nouvelle demande dans votre métier',
      body: `${data.title} — ${data.city}`,
      data: { requestId: request._id.toString() },
    });

    return populated;
  }

  /** The artisan whose quote was accepted for this request, if any. */
  private async assignedArtisanUserId(request: IServiceRequest): Promise<string | null> {
    if (!request.acceptedQuoteId) return null;
    const quote = await Quote.findById(request.acceptedQuoteId).populate('artisanId', 'userId').lean();
    const artisan: any = quote?.artisanId;
    return artisan?.userId ? artisan.userId.toString() : null;
  }

  public async update(requestId: string, userId: string, userRole: Role, data: UpdateRequestInput) {
    const request = await ServiceRequest.findById(requestId);
    if (!request) throw new NotFoundError('Service request');

    const isOwner = request.clientId.toString() === userId;
    const isAdmin = userRole === 'admin';
    const assignedArtisan = await this.assignedArtisanUserId(request);
    const isAssignedArtisan = userRole === 'artisan' && assignedArtisan === userId;

    // Object-level authorization (A7)
    if (!isOwner && !isAdmin && !isAssignedArtisan) {
      throw new ForbiddenError('You can only update your own service requests');
    }

    const editsContent =
      data.title !== undefined || data.description !== undefined || data.city !== undefined || data.address !== undefined;
    if (editsContent) {
      if (!isOwner && !isAdmin) throw new ForbiddenError('Only the client can edit the request details');
      if (request.status !== 'pending') throw new ConflictError('Only a pending request can be edited');
    }

    const previousStatus = request.status;
    if (data.status !== undefined && data.status !== request.status) {
      if (!TRANSITIONS[request.status].includes(data.status)) {
        throw new ConflictError(`Cannot change status from ${request.status} to ${data.status}`);
      }
      // The assigned artisan may only report the job as completed.
      if (isAssignedArtisan && !isOwner && !isAdmin && data.status !== 'completed') {
        throw new ForbiddenError('An artisan can only mark the job as completed');
      }
      request.status = data.status;
    }

    if (data.title !== undefined) request.title = data.title;
    if (data.description !== undefined) request.description = data.description;
    if (data.city !== undefined) request.city = data.city;
    if (data.address !== undefined) request.address = data.address;

    await request.save();

    if (previousStatus !== request.status) {
      await this.onStatusChanged(request, userId, assignedArtisan);
    }

    const updated = await request.populate([
      { path: 'clientId', select: 'fullName email phone' },
      { path: 'categoryId', select: CATEGORY_FIELDS },
    ]);

    // Notify requester and artisans in real-time via WebSocket
    wsManager.broadcastToRoom(`request:${requestId}`, 'request:updated', updated);
    wsManager.broadcastToUser(request.clientId.toString(), 'request:updated', updated);
    if (assignedArtisan) wsManager.broadcastToUser(assignedArtisan, 'request:updated', updated);

    return updated;
  }

  private async onStatusChanged(request: IServiceRequest, actorId: string, assignedArtisan: string | null) {
    const requestId = request._id.toString();
    const clientId = request.clientId.toString();

    if (request.status === 'completed') {
      if (request.acceptedQuoteId) {
        const quote = await Quote.findById(request.acceptedQuoteId).select('artisanId').lean();
        if (quote) await ArtisanProfile.findByIdAndUpdate(quote.artisanId, { $inc: { completedJobs: 1 } });
      }
      const target = actorId === clientId ? assignedArtisan : clientId;
      if (target) {
        await notificationService.notify(target, {
          type: 'request:completed',
          title: 'Mission terminée',
          body: actorId === clientId
            ? `Le client a confirmé la fin de « ${request.title} ».`
            : `L'artisan a marqué « ${request.title} » comme terminée. Laissez un avis !`,
          data: { requestId },
        });
      }
    }

    if (request.status === 'cancelled') {
      // Tell every artisan who quoted that the request is closed.
      const quotes = await Quote.find({ requestId: request._id }).populate('artisanId', 'userId').lean();
      const artisanUserIds = quotes
        .map((q: any) => q.artisanId?.userId?.toString())
        .filter((id: string | undefined): id is string => !!id && id !== actorId);
      await Quote.updateMany({ requestId: request._id, status: 'pending' }, { status: 'rejected' });
      await notificationService.notifyMany(artisanUserIds, {
        type: 'request:cancelled',
        title: 'Demande annulée',
        body: `Le client a annulé « ${request.title} ».`,
        data: { requestId },
      });
    }
  }

  public async cancel(requestId: string, userId: string, userRole: Role) {
    return this.update(requestId, userId, userRole, { status: 'cancelled' });
  }

  /** Client-side counters for the home screen. */
  public async clientStats(clientId: string) {
    const rows = await ServiceRequest.aggregate([
      { $match: { clientId: new mongoose.Types.ObjectId(clientId) } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const by = Object.fromEntries(rows.map((r) => [r._id, r.count]));
    return {
      pending: by.pending ?? 0,
      inProgress: (by.in_progress ?? 0) + (by.accepted ?? 0),
      completed: by.completed ?? 0,
      cancelled: by.cancelled ?? 0,
      total: rows.reduce((s, r) => s + r.count, 0),
    };
  }
}

export const serviceRequestService = new ServiceRequestService();

