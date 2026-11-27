import type { Request, Response, NextFunction } from 'express';
import { chatService } from './chat.service.js';

export class ChatController {
  public async startOrGet(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const conversation = await chatService.getOrCreateConversation(req.user!.id, req.user!.role, req.body);
      res.status(200).json({ data: conversation });
    } catch (err) {
      next(err);
    }
  }

  public async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const conversations = await chatService.listUserConversations(req.user!.id);
      res.status(200).json({ data: conversations });
    } catch (err) {
      next(err);
    }
  }

  public async getOne(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const conversation = await chatService.getConversation(String(req.params.conversationId), req.user!.id);
      res.status(200).json({ data: conversation });
    } catch (err) {
      next(err);
    }
  }

  public async getMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const messages = await chatService.getMessages(String(req.params.conversationId), req.user!.id);
      res.status(200).json({ data: messages });
    } catch (err) {
      next(err);
    }
  }

  public async send(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const message = await chatService.sendMessage(
        String(req.params.conversationId),
        req.user!.id,
        req.body
      );
      res.status(201).json({ data: message });
    } catch (err) {
      next(err);
    }
  }

  public async markRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await chatService.markRead(String(req.params.conversationId), req.user!.id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  }

  public async unreadCount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const count = await chatService.unreadCount(req.user!.id);
      res.status(200).json({ data: { unreadCount: count } });
    } catch (err) {
      next(err);
    }
  }
}

export const chatController = new ChatController();
