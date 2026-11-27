import { Router } from 'express';
import { chatController } from './chat.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { startConversationSchema, sendMessageSchema, conversationParamsSchema } from './chat.schema.js';
import { authenticate } from '../../core/middlewares/auth.js';

const router = Router();

router.use(authenticate);

router.get('/unread-count', chatController.unreadCount);
router.post('/conversations', validate({ body: startConversationSchema }), chatController.startOrGet);
router.get('/conversations', chatController.list);
router.get(
  '/conversations/:conversationId',
  validate({ params: conversationParamsSchema }),
  chatController.getOne
);
router.get(
  '/conversations/:conversationId/messages',
  validate({ params: conversationParamsSchema }),
  chatController.getMessages
);
router.post(
  '/conversations/:conversationId/messages',
  validate({ params: conversationParamsSchema, body: sendMessageSchema }),
  chatController.send
);
router.post(
  '/conversations/:conversationId/read',
  validate({ params: conversationParamsSchema }),
  chatController.markRead
);

export default router;
