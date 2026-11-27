import type { Request, Response, NextFunction } from 'express';
import { reviewService } from './review.service.js';

export class ReviewController {
  public async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const review = await reviewService.create(req.user!.id, req.body);
      res.status(201).json({ data: review, message: 'Review added successfully' });
    } catch (err) {
      next(err);
    }
  }

  public async listForArtisan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await reviewService.listForArtisan(String(req.params.artisanId), req.query as any);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}

export const reviewController = new ReviewController();
