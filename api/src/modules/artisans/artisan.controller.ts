import type { Request, Response, NextFunction } from 'express';
import { artisanService } from './artisan.service.js';

export class ArtisanController {
  public async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await artisanService.list(req.query as any);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  public async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.getById(String(req.params.id));
      res.status(200).json({ data: profile });
    } catch (err) {
      next(err);
    }
  }

  public async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.updateProfile(
        String(req.params.id),
        req.user!.id,
        req.user!.role,
        req.body
      );
      res.status(200).json({ data: profile, message: 'Profile updated successfully' });
    } catch (err) {
      next(err);
    }
  }

  public async verify(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.verifyArtisan(String(req.params.id), req.user!.id);
      res.status(200).json({ data: profile, message: 'Artisan verified' });
    } catch (err) {
      next(err);
    }
  }

  public async reject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.rejectArtisan(
        String(req.params.id),
        req.user!.id,
        req.body.reason
      );
      res.status(200).json({ data: profile, message: 'Artisan verification rejected' });
    } catch (err) {
      next(err);
    }
  }

  public async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await artisanService.adminList(req.query as any);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  public async me(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.getByUserId(req.user!.id);
      res.status(200).json({ data: profile });
    } catch (err) {
      next(err);
    }
  }

  public async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const current = await artisanService.getByUserId(req.user!.id);
      const profile = await artisanService.updateProfile(
        current._id.toString(),
        req.user!.id,
        req.user!.role,
        req.body
      );
      res.status(200).json({ data: profile, message: 'Profile updated successfully' });
    } catch (err) {
      next(err);
    }
  }

  public async myStats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await artisanService.statsForUser(req.user!.id);
      res.status(200).json({ data: stats });
    } catch (err) {
      next(err);
    }
  }

  public async adminGetById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await artisanService.getById(String(req.params.id));
      res.status(200).json({ data: profile });
    } catch (err) {
      next(err);
    }
  }
}

export const artisanController = new ArtisanController();
