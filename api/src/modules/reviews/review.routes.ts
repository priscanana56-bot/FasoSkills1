import { Router } from 'express';
import { reviewController } from './review.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { createReviewSchema, reviewQuerySchema } from './review.schema.js';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';

const router = Router();

router.post('/', authenticate, requireRole(['client']), validate({ body: createReviewSchema }), reviewController.create);
router.get('/artisan/:artisanId', validate({ query: reviewQuerySchema }), reviewController.listForArtisan);

export default router;
