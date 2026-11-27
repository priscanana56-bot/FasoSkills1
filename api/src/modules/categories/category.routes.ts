import { Router } from 'express';
import { categoryController } from './category.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import {
  createCategorySchema,
  updateCategorySchema,
  categoryQuerySchema,
} from './category.schema.js';
import { authenticate, optionalAuthenticate, requireRole } from '../../core/middlewares/auth.js';
import { idParamSchema } from '../../core/utils/validation.js';

const router = Router();

router.get(
  '/',
  optionalAuthenticate,
  validate({ query: categoryQuerySchema }),
  categoryController.list
);
router.get('/:id', validate({ params: idParamSchema }), categoryController.getById);
router.post(
  '/',
  authenticate,
  requireRole(['admin']),
  validate({ body: createCategorySchema }),
  categoryController.create
);
router.patch(
  '/:id',
  authenticate,
  requireRole(['admin']),
  validate({ params: idParamSchema, body: updateCategorySchema }),
  categoryController.update
);
router.delete(
  '/:id',
  authenticate,
  requireRole(['admin']),
  validate({ params: idParamSchema }),
  categoryController.remove
);

export default router;
