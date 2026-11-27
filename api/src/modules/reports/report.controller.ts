import type { Request, Response, NextFunction } from 'express';
import { reportService } from './report.service.js';
import type { ReportTargetType } from './report.model.js';

export class ReportController {
  public async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const report = await reportService.createReport(req.user!.id, req.body);
      res.status(201).json({ data: report, message: 'Report submitted successfully' });
    } catch (err) {
      next(err);
    }
  }

  public async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await reportService.listReports(req.query as any);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  public async dismiss(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const report = await reportService.updateReportStatus(
        String(req.params.id),
        req.user!.id,
        req.body
      );
      res.status(200).json({ data: report, message: 'Report updated' });
    } catch (err) {
      next(err);
    }
  }

  public async deleteContent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await reportService.deleteContent(
        req.params.type as ReportTargetType,
        String(req.params.id),
        req.user!.id,
        req.body?.reason
      );
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }

  public async listLogs(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await reportService.listModerationLogs(page, limit);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}

export const reportController = new ReportController();
