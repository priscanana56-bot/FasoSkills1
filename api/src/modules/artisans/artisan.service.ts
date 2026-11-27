import mongoose from 'mongoose';
import { ArtisanProfile } from './artisan.model.js';
import { User } from '../auth/auth.model.js';
import { NotFoundError, ForbiddenError, ConflictError } from '../../core/errors/app-error.js';
import { formatPaginatedResult, type PaginatedResult } from '../../core/utils/pagination.js';
import { wsManager } from '../../core/websocket/ws-server.js';
import { notificationService } from '../notifications/notification.service.js';
import { Quote } from '../quotes/quote.model.js';
import { ServiceRequest } from '../requests/request.model.js';
import type {
  AdminArtisansQuery,
  ArtisanQuery,
  UpdateArtisanProfileInput,
} from './artisan.schema.js';

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export class ArtisanService {
  public async list(query: ArtisanQuery): Promise<PaginatedResult<any>> {
    const { page, limit, search, city, categoryId, minRating } = query;
    const filter: Record<string, any> = {};

    if (city) filter.city = new RegExp(escapeRegex(city), 'i');
    if (categoryId) filter.category = categoryId;
    if (minRating) filter.rating = { $gte: minRating };

    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      // Match the artisan's name as well as their trade and bio.
      const users = await User.find({ role: 'artisan', fullName: regex }).select('_id').lean();
      filter.$or = [
        { specialty: regex },
        { bio: regex },
        ...(users.length > 0 ? [{ userId: { $in: users.map((u) => u._id) } }] : []),
      ];
    }

    const skip = (page - 1) * limit;

    const [profiles, total] = await Promise.all([
      ArtisanProfile.find(filter)
        .populate('userId', 'fullName email phone profilePicture isVerified')
        .populate('category', 'name slug icon')
        .sort({ rating: -1, completedJobs: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      ArtisanProfile.countDocuments(filter),
    ]);

    return formatPaginatedResult(profiles, total, page, limit);
  }

  public async getById(id: string) {
    const profile = await ArtisanProfile.findById(id)
      .populate('userId', 'fullName email phone profilePicture isVerified createdAt')
      .populate('category', 'name slug icon');
    if (!profile) throw new NotFoundError('Artisan profile');
    return profile;
  }

  public async updateProfile(
    profileId: string,
    userId: string,
    userRole: string,
    data: UpdateArtisanProfileInput
  ) {
    const profile = await ArtisanProfile.findById(profileId);
    if (!profile) throw new NotFoundError('Artisan profile');

    // Object-level authorization: Only the artisan owner or an admin can edit
    if (profile.userId.toString() !== userId && userRole !== 'admin') {
      throw new ForbiddenError('You can only update your own artisan profile');
    }

    if (data.specialty !== undefined) profile.specialty = data.specialty;
    if (data.city !== undefined) profile.city = data.city;
    if (data.categoryId !== undefined) profile.category = data.categoryId as any;
    if (data.experienceYears !== undefined) profile.experienceYears = data.experienceYears;
    if (data.bio !== undefined) profile.bio = data.bio;
    if (data.availability !== undefined) profile.availability = data.availability;
    if (data.documents !== undefined) {
      profile.documents = data.documents.map((doc) => ({
        name: doc.name,
        type: doc.type,
        url: doc.url,
        uploadedAt: new Date(),
      }));
    }

    if (profile.specialty && profile.city && profile.category) {
      profile.profileStatus = 'complete';
    }

    await profile.save();
    return profile.populate([
      { path: 'userId', select: 'fullName email phone profilePicture isVerified' },
      { path: 'category', select: 'name slug icon' },
    ]);
  }

  public async verifyArtisan(profileId: string, adminUserId: string) {
    const profile = await ArtisanProfile.findById(profileId);
    if (!profile) throw new NotFoundError('Artisan profile');

    if (profile.isVerified || profile.verificationStatus === 'verified') {
      throw new ConflictError('Artisan is already verified');
    }

    profile.isVerified = true;
    profile.verificationStatus = 'verified';
    profile.rejectionReason = undefined;
    profile.verifiedAt = new Date();
    profile.verifiedBy = new mongoose.Types.ObjectId(adminUserId);
    profile.rejectedAt = undefined;
    profile.rejectedBy = undefined;
    await profile.save();

    await User.findByIdAndUpdate(profile.userId, { isVerified: true });

    const populated = await profile.populate([
      { path: 'userId', select: 'fullName email phone profilePicture isVerified createdAt' },
      { path: 'category', select: 'name slug icon' },
    ]);

    wsManager.broadcastToUser(profile.userId.toString(), 'artisan:verified', {
      artisanProfileId: profile._id.toString(),
      isVerified: true,
    });
    await notificationService.notify(profile.userId, {
      type: 'artisan:verified',
      title: 'Profil vérifié ✅',
      body: 'Votre profil artisan a été validé. Les clients voient maintenant votre badge vérifié.',
      data: { artisanProfileId: profile._id.toString() },
    });

    return populated;
  }

  public async rejectArtisan(profileId: string, adminUserId: string, reason: string) {
    const profile = await ArtisanProfile.findById(profileId);
    if (!profile) throw new NotFoundError('Artisan profile');

    profile.isVerified = false;
    profile.verificationStatus = 'rejected';
    profile.rejectionReason = reason;
    profile.rejectedAt = new Date();
    profile.rejectedBy = new mongoose.Types.ObjectId(adminUserId);
    await profile.save();

    await User.findByIdAndUpdate(profile.userId, { isVerified: false });

    const populated = await profile.populate([
      { path: 'userId', select: 'fullName email phone profilePicture isVerified createdAt' },
      { path: 'category', select: 'name slug icon' },
    ]);

    wsManager.broadcastToUser(profile.userId.toString(), 'artisan:rejected', {
      artisanProfileId: profile._id.toString(),
      reason,
    });
    await notificationService.notify(profile.userId, {
      type: 'artisan:rejected',
      title: 'Vérification refusée',
      body: `Motif : ${reason}`,
      data: { artisanProfileId: profile._id.toString() },
    });

    return populated;
  }

  public async getByUserId(userId: string) {
    const profile = await ArtisanProfile.findOne({ userId })
      .populate('userId', 'fullName email phone profilePicture isVerified createdAt')
      .populate('category', 'name slug icon');
    if (!profile) throw new NotFoundError('Artisan profile');
    return profile;
  }

  /** Dashboard counters for the logged-in artisan. */
  public async statsForUser(userId: string) {
    const profile = await ArtisanProfile.findOne({ userId }).lean();
    if (!profile) throw new NotFoundError('Artisan profile');

    const [quoteRows, acceptedQuotes] = await Promise.all([
      Quote.aggregate([
        { $match: { artisanId: profile._id } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      Quote.find({ artisanId: profile._id, status: 'accepted' })
        .populate('requestId', 'status')
        .select('amount requestId')
        .lean(),
    ]);
    const quotesBy = Object.fromEntries(quoteRows.map((r) => [r._id, r.count as number]));

    let activeMissions = 0;
    let earnings = 0;
    for (const q of acceptedQuotes as any[]) {
      const status = q.requestId?.status;
      if (status === 'in_progress' || status === 'accepted') activeMissions += 1;
      if (status === 'completed') earnings += q.amount;
    }

    const openRequests = await ServiceRequest.countDocuments({
      status: 'pending',
      ...(profile.category ? { categoryId: profile.category } : {}),
    });

    return {
      openRequests,
      pendingQuotes: quotesBy.pending ?? 0,
      acceptedQuotes: quotesBy.accepted ?? 0,
      rejectedQuotes: quotesBy.rejected ?? 0,
      activeMissions,
      completedJobs: profile.completedJobs,
      rating: profile.rating,
      reviewsCount: profile.reviewsCount,
      earnings,
      verificationStatus: profile.verificationStatus,
      profileStatus: profile.profileStatus,
    };
  }

  public async adminList(query: AdminArtisansQuery): Promise<PaginatedResult<any>> {
    const { status, q, page, limit } = query;
    const filter: Record<string, any> = {};

    if (status === 'pending') {
      filter.isVerified = false;
      filter.verificationStatus = { $ne: 'rejected' };
    } else if (status === 'verified') {
      filter.isVerified = true;
    }

    if (q) {
      const regex = new RegExp(escapeRegex(q), 'i');
      const matchingUsers = await User.find({
        $or: [{ fullName: regex }, { email: regex }, { phone: regex }],
      })
        .select('_id')
        .lean();
      const userIds = matchingUsers.map((u) => u._id);

      filter.$or = [
        { specialty: regex },
        { bio: regex },
        { city: regex },
        ...(userIds.length > 0 ? [{ userId: { $in: userIds } }] : []),
      ];
    }

    const skip = (page - 1) * limit;

    const [profiles, total] = await Promise.all([
      ArtisanProfile.find(filter)
        .populate('userId', 'fullName email phone profilePicture isVerified createdAt')
        .populate('category', 'name slug icon')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      ArtisanProfile.countDocuments(filter),
    ]);

    return formatPaginatedResult(profiles, total, page, limit);
  }
}

export const artisanService = new ArtisanService();
