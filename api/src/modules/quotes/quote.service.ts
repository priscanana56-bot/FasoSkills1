import { Quote } from './quote.model.js';
import { ServiceRequest } from '../requests/request.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { NotFoundError, ForbiddenError, ConflictError, ValidationError } from '../../core/errors/app-error.js';
import { formatPaginatedResult, type PaginatedResult } from '../../core/utils/pagination.js';
import { wsManager } from '../../core/websocket/ws-server.js';
import { notificationService } from '../notifications/notification.service.js';
import type { CreateQuoteInput, QuoteQuery, MyQuotesQuery } from './quote.schema.js';

function formatAmount(amount: number): string {
  return `${Math.round(amount).toLocaleString('fr-FR')} FCFA`;
}

export class QuoteService {
  public async create(userId: string, data: CreateQuoteInput) {
    const artisan = await ArtisanProfile.findOne({ userId });
    if (!artisan) {
      throw new ForbiddenError('Only registered artisans can propose quotes');
    }

    const request = await ServiceRequest.findById(data.requestId);
    if (!request) throw new NotFoundError('Service request');
    if (request.status !== 'pending') {
      throw new ConflictError('Cannot submit a quote to a closed or ongoing request');
    }

    const existingQuote = await Quote.findOne({ requestId: request._id, artisanId: artisan._id });
    if (existingQuote) {
      throw new ConflictError('You have already submitted a quote for this request');
    }

    const quote = await Quote.create({
      requestId: request._id,
      artisanId: artisan._id,
      amount: data.amount,
      estimatedDays: data.estimatedDays,
      message: data.message || '',
      status: 'pending',
    });

    const populated = await quote.populate([
      {
        path: 'artisanId',
        populate: [
          { path: 'userId', select: 'fullName email phone profilePicture isVerified' },
          { path: 'category', select: 'name' },
        ],
      },
    ]);

    // WebSocket real-time notification to client
    wsManager.broadcastToUser(request.clientId.toString(), 'quote:received', {
      requestId: request._id,
      quote: populated,
    });
    wsManager.broadcastToRoom(`request:${request._id}`, 'quote:received', populated);
    const artisanName = (populated.artisanId as any)?.userId?.fullName ?? 'Un artisan';
    await notificationService.notify(request.clientId, {
      type: 'quote:received',
      title: 'Nouveau devis reçu',
      body: `${artisanName} propose ${formatAmount(data.amount)} pour « ${request.title} ».`,
      data: { requestId: request._id.toString(), quoteId: quote._id.toString() },
    });

    return populated;
  }

  public async listForRequest(requestId: string, userId: string, userRole: string, query: QuoteQuery): Promise<PaginatedResult<any>> {
    const request = await ServiceRequest.findById(requestId);
    if (!request) throw new NotFoundError('Service request');

    // Rule: Only the requester (or artisan author, or admin) sees quotes for this request
    const isOwner = request.clientId.toString() === userId;
    const isAdmin = userRole === 'admin';

    let filter: Record<string, any> = { requestId };

    if (!isOwner && !isAdmin) {
      // If user is an artisan, they can only see their own quote for this request
      const artisan = await ArtisanProfile.findOne({ userId });
      if (!artisan) throw new ForbiddenError('Unauthorized to view quotes for this request');
      filter.artisanId = artisan._id;
    }

    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;

    const [quotes, total] = await Promise.all([
      Quote.find(filter)
        .populate({
          path: 'artisanId',
          populate: [
            { path: 'userId', select: 'fullName email phone profilePicture isVerified' },
            { path: 'category', select: 'name' },
          ],
        })
        .sort({ amount: 1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Quote.countDocuments(filter),
    ]);

    return formatPaginatedResult(quotes, total, page, limit);
  }

  public async accept(quoteId: string, userId: string) {
    const quote = await Quote.findById(quoteId).populate('artisanId');
    if (!quote) throw new NotFoundError('Quote');
    if (quote.status !== 'pending') {
      throw new ConflictError('Only a pending quote can be accepted');
    }

    const request = await ServiceRequest.findById(quote.requestId);
    if (!request) throw new NotFoundError('Service request');

    // Object-level authorization: Only the client who created the request can accept a quote
    if (request.clientId.toString() !== userId) {
      throw new ForbiddenError('Only the request owner can accept a quote');
    }

    // Rule: One accepted quote per request
    if (request.status !== 'pending') {
      throw new ConflictError('A quote has already been accepted or the request is no longer pending');
    }

    // Atomically claim the request before changing any quote.
    // This compare-and-set prevents two concurrent accept requests from winning.
    const claimedRequest = await ServiceRequest.findOneAndUpdate(
      {
        _id: request._id,
        status: 'pending',
        acceptedQuoteId: { $exists: false },
      },
      {
        $set: {
          status: 'in_progress',
          acceptedQuoteId: quote._id,
        },
      },
      { new: true }
    );
    if (!claimedRequest) {
      throw new ConflictError('A quote has already been accepted or the request is no longer pending');
    }

    // Atomically mark this quote accepted as part of the request claim.
    // If it fails, roll the request back so another valid quote can still be accepted.
    const acceptedQuote = await Quote.findOneAndUpdate(
      { _id: quote._id, requestId: request._id, status: 'pending' },
      { $set: { status: 'accepted' } },
      { new: true }
    ).populate({
      path: 'artisanId',
      populate: [
        { path: 'userId', select: 'fullName email phone profilePicture isVerified' },
        { path: 'category', select: 'name' },
      ],
    });
    if (!acceptedQuote) {
      await ServiceRequest.updateOne(
        { _id: request._id, acceptedQuoteId: quote._id },
        { $set: { status: 'pending' }, $unset: { acceptedQuoteId: 1 } }
      );
      throw new ConflictError('This quote is no longer available');
    }

    const others = await Quote.find({ requestId: request._id, _id: { $ne: acceptedQuote._id }, status: 'pending' })
      .populate('artisanId', 'userId')
      .lean();
    await Quote.updateMany(
      { requestId: request._id, _id: { $ne: acceptedQuote._id } },
      { status: 'rejected' }
    );
    await notificationService.notifyMany(
      others.map((o: any) => o.artisanId?.userId).filter(Boolean),
      {
        type: 'quote:rejected',
        title: 'Devis non retenu',
        body: `Le client a choisi un autre artisan pour « ${request.title} ».`,
        data: { requestId: request._id.toString() },
      }
    );

    const artisan: any = acceptedQuote.artisanId;
    if (artisan && artisan.userId) {
      // WebSocket notification to the artisan that quote was accepted!
      wsManager.broadcastToUser(artisan.userId.toString(), 'quote:accepted', {
        requestId: request._id,
        quoteId: acceptedQuote._id,
      });
      await notificationService.notify(artisan.userId, {
        type: 'quote:accepted',
        title: 'Devis accepté 🎉',
        body: `Votre devis pour « ${request.title} » a été accepté. La mission commence !`,
        data: { requestId: request._id.toString(), quoteId: acceptedQuote._id.toString() },
      });
    }
    wsManager.broadcastToRoom(`request:${request._id}`, 'request:in_progress', {
      requestId: request._id,
      acceptedQuoteId: acceptedQuote._id,
    });

    return acceptedQuote;
  }

  /** Client declines one quote; the request stays open for others. */
  public async reject(quoteId: string, userId: string) {
    const quote = await Quote.findById(quoteId).populate('artisanId', 'userId');
    if (!quote) throw new NotFoundError('Quote');
    const request = await ServiceRequest.findById(quote.requestId);
    if (!request) throw new NotFoundError('Service request');
    if (request.clientId.toString() !== userId) {
      throw new ForbiddenError('Only the request owner can decline a quote');
    }
    if (quote.status !== 'pending') {
      throw new ConflictError('Only a pending quote can be declined');
    }
    quote.status = 'rejected';
    await quote.save();

    const artisan: any = quote.artisanId;
    if (artisan?.userId) {
      await notificationService.notify(artisan.userId, {
        type: 'quote:rejected',
        title: 'Devis refusé',
        body: `Le client a refusé votre devis pour « ${request.title} ».`,
        data: { requestId: request._id.toString(), quoteId: quote._id.toString() },
      });
    }
    return quote;
  }

  /** Artisan withdraws their own pending quote. */
  public async withdraw(quoteId: string, userId: string) {
    const artisan = await ArtisanProfile.findOne({ userId }).select('_id');
    if (!artisan) throw new ForbiddenError('Only registered artisans can withdraw quotes');
    const quote = await Quote.findById(quoteId);
    if (!quote) throw new NotFoundError('Quote');
    if (quote.artisanId.toString() !== artisan._id.toString()) {
      throw new ForbiddenError('You can only withdraw your own quote');
    }
    if (quote.status !== 'pending') {
      throw new ConflictError('Only a pending quote can be withdrawn');
    }
    await quote.deleteOne();
  }

  /** All quotes sent by the current artisan, with their request. */
  public async listMine(userId: string, query: MyQuotesQuery): Promise<PaginatedResult<any>> {
    const artisan = await ArtisanProfile.findOne({ userId }).select('_id');
    if (!artisan) throw new ForbiddenError('Only registered artisans have quotes');
    const filter: Record<string, any> = { artisanId: artisan._id };
    if (query.status) filter.status = query.status;
    const { page, limit } = query;
    const [quotes, total] = await Promise.all([
      Quote.find(filter)
        .populate({
          path: 'requestId',
          populate: [
            { path: 'clientId', select: 'fullName phone profilePicture' },
            { path: 'categoryId', select: 'name slug icon' },
          ],
        })
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Quote.countDocuments(filter),
    ]);
    return formatPaginatedResult(quotes, total, page, limit);
  }
}

export const quoteService = new QuoteService();
