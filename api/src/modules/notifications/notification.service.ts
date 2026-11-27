import mongoose from 'mongoose';
import { Notification, type NotificationType } from './notification.model.js';
import { NotFoundError } from '../../core/errors/app-error.js';
import { formatPaginatedResult } from '../../core/utils/pagination.js';
import { wsManager } from '../../core/websocket/ws-server.js';
import type { NotificationQuery } from './notification.schema.js';

type Id = string | mongoose.Types.ObjectId;

export interface NotifyInput {
  type: NotificationType;
  title: string;
  body?: string;
  data?: Record<string, unknown>;
}

export class NotificationService {
  /**
   * Persists a notification for one user and pushes it in real time.
   * Never throws: a notification failure must not break the business action that triggered it.
   */
  public async notify(userId: Id, input: NotifyInput): Promise<void> {
    try {
      const notification = await Notification.create({
        userId,
        type: input.type,
        title: input.title,
        body: input.body ?? '',
        data: input.data ?? {},
      });
      const unreadCount = await Notification.countDocuments({ userId, isRead: false });
      wsManager.broadcastToUser(userId.toString(), 'notification:new', {
        notification: notification.toObject(),
        unreadCount,
      });
    } catch (err) {
      console.error('Failed to create notification', err);
    }
  }

  public async notifyMany(userIds: Id[], input: NotifyInput): Promise<void> {
    const unique = [...new Set(userIds.map((id) => id.toString()))];
    await Promise.all(unique.map((id) => this.notify(id, input)));
  }

  public async list(userId: string, query: NotificationQuery) {
    const { page, limit, unreadOnly } = query;
    const filter: Record<string, unknown> = { userId };
    if (unreadOnly === 'true') filter.isRead = false;

    const [items, total, unreadCount] = await Promise.all([
      Notification.find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Notification.countDocuments(filter),
      Notification.countDocuments({ userId, isRead: false }),
    ]);

    return { ...formatPaginatedResult(items, total, page, limit), unreadCount };
  }

  public async unreadCount(userId: string): Promise<number> {
    return Notification.countDocuments({ userId, isRead: false });
  }

  public async markRead(notificationId: string, userId: string) {
    // Scoped to the owner: another user's notification is reported as not found.
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true },
      { new: true }
    );
    if (!notification) throw new NotFoundError('Notification');
    return notification;
  }

  public async markAllRead(userId: string): Promise<number> {
    const result = await Notification.updateMany({ userId, isRead: false }, { isRead: true });
    return result.modifiedCount;
  }
}

export const notificationService = new NotificationService();
