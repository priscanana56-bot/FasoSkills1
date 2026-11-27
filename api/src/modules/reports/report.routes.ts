import { Router } from 'express';
import { reportController } from './report.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { createReportSchema } from './report.schema.js';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';

const router = Router();

router.post(
  '/',
  authenticate,
  requireRole(['client', 'artisan', 'admin']),
  validate({ body: createReportSchema }),
  reportController.create
);

export default router;
