import { Router } from 'express';
import { notificationController } from './notification.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { authenticate } from '../../core/middlewares/auth.js';
import { idParamSchema } from '../../core/utils/validation.js';
import { notificationQuerySchema } from './notification.schema.js';

const router = Router();

router.use(authenticate);

router.get('/', validate({ query: notificationQuerySchema }), notificationController.list);
router.get('/unread-count', notificationController.unreadCount);
router.post('/read-all', notificationController.markAllRead);
router.patch('/:id/read', validate({ params: idParamSchema }), notificationController.markRead);

export default router;
