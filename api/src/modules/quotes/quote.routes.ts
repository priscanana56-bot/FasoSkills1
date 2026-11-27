import { Router } from 'express';
import { quoteController } from './quote.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { createQuoteSchema, quoteQuerySchema, myQuotesQuerySchema } from './quote.schema.js';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';
import { idParamSchema } from '../../core/utils/validation.js';

const router = Router();

router.use(authenticate);

router.get('/mine', requireRole(['artisan']), validate({ query: myQuotesQuerySchema }), quoteController.listMine);
router.post('/', requireRole(['artisan']), validate({ body: createQuoteSchema }), quoteController.create);
router.get('/request/:requestId', validate({ query: quoteQuerySchema }), quoteController.listForRequest);
router.post('/:id/accept', requireRole(['client']), validate({ params: idParamSchema }), quoteController.accept);
router.post('/:id/reject', requireRole(['client']), validate({ params: idParamSchema }), quoteController.reject);
router.delete('/:id', requireRole(['artisan']), validate({ params: idParamSchema }), quoteController.withdraw);

export default router;
