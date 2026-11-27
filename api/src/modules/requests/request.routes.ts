import { Router } from 'express';
import { serviceRequestController } from './request.controller.js';
import { validate } from '../../core/middlewares/validate.js';
import { createRequestSchema, updateRequestSchema, requestQuerySchema } from './request.schema.js';
import { authenticate, requireRole } from '../../core/middlewares/auth.js';
import { idParamSchema } from '../../core/utils/validation.js';

const router = Router();

// Requests carry client contact details: every endpoint requires authentication,
// and results are scoped to the caller's role in the service layer.
router.use(authenticate);

router.get('/', validate({ query: requestQuerySchema }), serviceRequestController.list);
router.get('/stats', requireRole(['client']), serviceRequestController.stats);
router.get('/:id', validate({ params: idParamSchema }), serviceRequestController.getById);
router.post('/', requireRole(['client']), validate({ body: createRequestSchema }), serviceRequestController.create);
router.put('/:id', validate({ params: idParamSchema, body: updateRequestSchema }), serviceRequestController.update);
router.delete('/:id', validate({ params: idParamSchema }), serviceRequestController.cancel);

export default router;
