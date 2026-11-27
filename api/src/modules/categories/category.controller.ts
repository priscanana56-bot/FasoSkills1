import type { Request, Response, NextFunction } from 'express';
import { categoryService } from './category.service.js';

export class CategoryController {
  public async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const includeInactive =
        req.user?.role === 'admin' && req.query.includeInactive === 'true';
      const categories = await categoryService.list(includeInactive);
      res.status(200).json({ data: categories });
    } catch (err) {
      next(err);
    }
  }

  public async adminList(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const categories = await categoryService.list(true);
      res.status(200).json({ data: categories });
    } catch (err) {
      next(err);
    }
  }

  public async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await categoryService.getById(String(req.params.id));
      res.status(200).json({ data: category });
    } catch (err) {
      next(err);
    }
  }

  public async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await categoryService.create(req.body);
      res.status(201).json({ data: category, message: 'Category created' });
    } catch (err) {
      next(err);
    }
  }

  public async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await categoryService.update(String(req.params.id), req.body);
      res.status(200).json({ data: category, message: 'Category updated' });
    } catch (err) {
      next(err);
    }
  }

  public async remove(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await categoryService.remove(String(req.params.id));
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}

export const categoryController = new CategoryController();
