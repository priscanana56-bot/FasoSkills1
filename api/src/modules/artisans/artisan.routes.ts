import { Router } from 'express';
import { artisanController } from './artisan.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { artisanQuerySchema, updateArtisanProfileSchema } from './artisan.schema.js';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';
import { idParamSchema } from '../../core/utils/validation.js';

const router = Router();

router.get('/', validate({ query: artisanQuerySchema }), artisanController.list);
// "me" routes are declared before "/:id" so they are not captured as an id.
router.get('/me', authenticate, requireRole(['artisan']), artisanController.me);
router.put(
  '/me',
  authenticate,
  requireRole(['artisan']),
  validate({ body: updateArtisanProfileSchema }),
  artisanController.updateMe
);
router.get('/me/stats', authenticate, requireRole(['artisan']), artisanController.myStats);
router.get('/:id', validate({ params: idParamSchema }), artisanController.getById);
router.put(
  '/:id',
  authenticate,
  validate({ params: idParamSchema, body: updateArtisanProfileSchema }),
  artisanController.update
);
router.post(
  '/:id/verify',
  authenticate,
  requireRole(['admin']),
  validate({ params: idParamSchema }),
  artisanController.verify
);

export default router;
