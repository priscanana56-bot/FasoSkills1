import type { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service.js';

export class AuthController {
  public async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.register(req.body);
      res.status(201).json({
        data: result,
        message: 'User registered successfully',
      });
    } catch (err) {
      next(err);
    }
  }

  public async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.login(req.body);
      res.status(200).json({
        data: result,
        message: 'Login successful',
      });
    } catch (err) {
      next(err);
    }
  }

  public async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const tokens = await authService.refresh(req.body.refreshToken);
      res.status(200).json({
        data: tokens,
        message: 'Tokens refreshed successfully',
      });
    } catch (err) {
      next(err);
    }
  }

  public async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await authService.logout(req.body.refreshToken);
      res.status(200).json({
        data: null,
        message: 'Logged out successfully',
      });
    } catch (err) {
      next(err);
    }
  }

  public async me(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await authService.getCurrentUser(req.user!.id);
      res.status(200).json({
        data: user,
      });
    } catch (err) {
      next(err);
    }
  }

  public async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await authService.updateMe(req.user!.id, req.body);
      res.status(200).json({ data: result, message: 'Profile updated' });
    } catch (err) {
      next(err);
    }
  }

  public async changePassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await authService.changePassword(req.user!.id, req.body);
      res.status(200).json({ data: null, message: 'Password changed' });
    } catch (err) {
      next(err);
    }
  }
}

export const authController = new AuthController();
