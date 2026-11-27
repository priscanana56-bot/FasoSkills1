import { User } from '../auth/auth.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { ServiceRequest } from '../requests/request.model.js';
import { Quote } from '../quotes/quote.model.js';
import { Category } from '../categories/category.model.js';
import { Report } from '../reports/report.model.js';

export class AdminService {
  public async getStats() {
    const [
      userCounts,
      artisanCounts,
      requestCounts,
      quoteStats,
      categoryCounts,
      reportCounts,
      requestsByCategory,
      artisansByCity,
    ] = await Promise.all([
      User.aggregate([
        { $group: { _id: '$role', count: { $sum: 1 } } },
      ]),
      ArtisanProfile.aggregate([
        {
          $group: {
            _id: {
              $cond: [
                { $eq: ['$isVerified', true] },
                'verified',
                {
                  $cond: [
                    { $eq: ['$verificationStatus', 'rejected'] },
                    'rejected',
                    'pending',
                  ],
                },
              ],
            },
            count: { $sum: 1 },
          },
        },
      ]),
      ServiceRequest.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      Quote.aggregate([
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 },
            totalAmount: { $sum: '$amount' },
          },
        },
      ]),
      Category.aggregate([
        { $group: { _id: '$isActive', count: { $sum: 1 } } },
      ]),
      Report.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      ServiceRequest.aggregate([
        { $group: { _id: '$categoryId', count: { $sum: 1 } } },
        {
          $lookup: {
            from: 'categories',
            localField: '_id',
            foreignField: '_id',
            as: 'category',
          },
        },
        { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            _id: 0,
            categoryId: '$_id',
            name: { $ifNull: ['$category.name', 'Autre'] },
            slug: { $ifNull: ['$category.slug', 'autre'] },
            count: 1,
          },
        },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      ArtisanProfile.aggregate([
        {
          $group: {
            _id: '$city',
            count: { $sum: 1 },
            verifiedCount: { $sum: { $cond: ['$isVerified', 1, 0] } },
          },
        },
        {
          $project: {
            _id: 0,
            city: '$_id',
            count: 1,
            verifiedCount: 1,
          },
        },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
    ]);

    const toCountMap = (rows: Array<{ _id: any; count: number }>) => {
      const map: Record<string, number> = {};
      for (const row of rows) {
        map[String(row._id)] = row.count;
      }
      return map;
    };

    const usersMap = toCountMap(userCounts);
    const artisansMap = toCountMap(artisanCounts);
    const requestsMap = toCountMap(requestCounts);
    const categoriesMap = toCountMap(categoryCounts);
    const reportsMap = toCountMap(reportCounts);

    let quotesTotal = 0;
    let quotesPending = 0;
    let quotesAccepted = 0;
    let quotesRejected = 0;
    let totalAcceptedAmount = 0;
    let totalAllQuoteAmount = 0;

    for (const row of quoteStats) {
      quotesTotal += row.count;
      totalAllQuoteAmount += row.totalAmount;
      if (row._id === 'pending') quotesPending = row.count;
      if (row._id === 'accepted') {
        quotesAccepted = row.count;
        totalAcceptedAmount = row.totalAmount;
      }
      if (row._id === 'rejected') quotesRejected = row.count;
    }

    const usersTotal =
      (usersMap.client ?? 0) + (usersMap.artisan ?? 0) + (usersMap.admin ?? 0);
    const artisansTotal =
      (artisansMap.verified ?? 0) +
      (artisansMap.pending ?? 0) +
      (artisansMap.rejected ?? 0);
    const requestsTotal =
      (requestsMap.pending ?? 0) +
      (requestsMap.accepted ?? 0) +
      (requestsMap.in_progress ?? 0) +
      (requestsMap.completed ?? 0) +
      (requestsMap.cancelled ?? 0);

    return {
      users: {
        total: usersTotal,
        clients: usersMap.client ?? 0,
        artisans: usersMap.artisan ?? 0,
        admins: usersMap.admin ?? 0,
      },
      artisans: {
        total: artisansTotal,
        verified: artisansMap.verified ?? 0,
        pending: artisansMap.pending ?? 0,
        rejected: artisansMap.rejected ?? 0,
      },
      requests: {
        total: requestsTotal,
        pending: requestsMap.pending ?? 0,
        inProgress: (requestsMap.in_progress ?? 0) + (requestsMap.accepted ?? 0),
        completed: requestsMap.completed ?? 0,
        cancelled: requestsMap.cancelled ?? 0,
      },
      quotes: {
        total: quotesTotal,
        pending: quotesPending,
        accepted: quotesAccepted,
        rejected: quotesRejected,
        totalAcceptedAmount,
        averageAmount: quotesTotal > 0 ? Math.round(totalAllQuoteAmount / quotesTotal) : 0,
      },
      categories: {
        total: (categoriesMap.true ?? 0) + (categoriesMap.false ?? 0),
        active: categoriesMap.true ?? 0,
      },
      reports: {
        total:
          (reportsMap.pending ?? 0) +
          (reportsMap.dismissed ?? 0) +
          (reportsMap.action_taken ?? 0),
        pending: reportsMap.pending ?? 0,
      },
      charts: {
        requestsByCategory,
        artisansByCity,
        requestsByStatus: [
          { status: 'pending', count: requestsMap.pending ?? 0 },
          {
            status: 'in_progress',
            count: (requestsMap.in_progress ?? 0) + (requestsMap.accepted ?? 0),
          },
          { status: 'completed', count: requestsMap.completed ?? 0 },
          { status: 'cancelled', count: requestsMap.cancelled ?? 0 },
        ],
      },
    };
  }
}

export const adminService = new AdminService();
