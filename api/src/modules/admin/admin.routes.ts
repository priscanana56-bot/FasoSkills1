import { Router } from 'express';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';
import { validate } from '../../core/middlewares/validate.js';
import { idParamSchema } from '../../core/utils/validation.js';
import { adminController } from './admin.controller.js';
import { artisanController } from '../artisans/artisan.controller.js';
import {
  adminArtisansQuerySchema,
  rejectArtisanSchema,
} from '../artisans/artisan.schema.js';
import { categoryController } from '../categories/category.controller.js';
import { reportController } from '../reports/report.controller.js';
import {
  adminReportsQuerySchema,
  deleteContentBodySchema,
  deleteContentParamsSchema,
  dismissReportSchema,
} from '../reports/report.schema.js';

const router = Router();

// All /api/admin/* endpoints strictly require an authenticated admin user
router.use(authenticate, requireRole(['admin']));

// Dashboard analytics (MongoDB aggregation pipelines)
router.get('/stats', adminController.getStats);

// Artisan verification workflow
router.get('/artisans', validate({ query: adminArtisansQuerySchema }), artisanController.adminList);
router.get('/artisans/:id', validate({ params: idParamSchema }), artisanController.adminGetById);
router.post(
  '/artisans/:id/reject',
  validate({ params: idParamSchema, body: rejectArtisanSchema }),
  artisanController.reject
);

// Categories overview (including inactive)
router.get('/categories', categoryController.adminList);

// Reports & content moderation
router.get('/reports', validate({ query: adminReportsQuerySchema }), reportController.adminList);
router.patch(
  '/reports/:id',
  validate({ params: idParamSchema, body: dismissReportSchema }),
  reportController.dismiss
);
router.delete(
  '/content/:type/:id',
  validate({ params: deleteContentParamsSchema, body: deleteContentBodySchema }),
  reportController.deleteContent
);
router.get('/moderation-logs', reportController.listLogs);

export default router;
