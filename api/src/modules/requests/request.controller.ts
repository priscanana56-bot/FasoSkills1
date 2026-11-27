import type { Request, Response, NextFunction } from 'express';
import { serviceRequestService } from './request.service.js';

export class ServiceRequestController {
  public async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await serviceRequestService.list(
        req.query as any,
        req.user?.id,
        req.user?.role
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  public async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const request = await serviceRequestService.getById(
        String(req.params.id),
        req.user!.id,
        req.user!.role
      );
      res.status(200).json({ data: request });
    } catch (err) {
      next(err);
    }
  }

  public async stats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await serviceRequestService.clientStats(req.user!.id);
      res.status(200).json({ data: stats });
    } catch (err) {
      next(err);
    }
  }

  public async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const request = await serviceRequestService.create(req.user!.id, req.body);
      res.status(201).json({ data: request, message: 'Request created successfully' });
    } catch (err) {
      next(err);
    }
  }

  public async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const request = await serviceRequestService.update(
        String(req.params.id),
        req.user!.id,
        req.user!.role,
        req.body
      );
      res.status(200).json({ data: request, message: 'Request updated' });
    } catch (err) {
      next(err);
    }
  }

  public async cancel(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const request = await serviceRequestService.cancel(
        String(req.params.id),
        req.user!.id,
        req.user!.role
      );
      res.status(200).json({ data: request, message: 'Request cancelled' });
    } catch (err) {
      next(err);
    }
  }
}

export const serviceRequestController = new ServiceRequestController();
