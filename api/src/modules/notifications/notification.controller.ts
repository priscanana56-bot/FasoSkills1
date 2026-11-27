import type { Request, Response, NextFunction } from 'express';
import { notificationService } from './notification.service.js';

export class NotificationController {
  public async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await notificationService.list(req.user!.id, req.query as any);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  public async unreadCount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const count = await notificationService.unreadCount(req.user!.id);
      res.status(200).json({ data: { unreadCount: count } });
    } catch (err) {
      next(err);
    }
  }

  public async markRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const notification = await notificationService.markRead(String(req.params.id), req.user!.id);
      res.status(200).json({ data: notification });
    } catch (err) {
      next(err);
    }
  }

  public async markAllRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updated = await notificationService.markAllRead(req.user!.id);
      res.status(200).json({ data: { updated } });
    } catch (err) {
      next(err);
    }
  }
}

export const notificationController = new NotificationController();
