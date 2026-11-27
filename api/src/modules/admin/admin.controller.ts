import type { Request, Response, NextFunction } from 'express';
import { adminService } from './admin.service.js';

export class AdminController {
  public async getStats(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await adminService.getStats();
      res.status(200).json({ data: stats });
    } catch (err) {
      next(err);
    }
  }
}

export const adminController = new AdminController();
