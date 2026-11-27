import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const createReportSchema = z.preprocess(
  (val) => {
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      const obj = val as Record<string, unknown>;
      return {
        ...obj,
        targetType: obj.targetType ?? obj.type,
      };
    }
    return val;
  },
  z.object({
    targetType: z.enum(['request', 'review', 'message']),
    targetId: objectIdSchema,
    reason: z.string().trim().min(3, 'Reason must be at least 3 characters').max(500),
    description: z.string().trim().max(1000).optional(),
  })
);

export const adminReportsQuerySchema = z.object({
  type: z.preprocess(
    (val) => (val === '' ? undefined : val),
    z.enum(['request', 'review', 'message']).optional()
  ),
  status: z.preprocess(
    (val) => (val === '' ? undefined : val),
    z.enum(['pending', 'dismissed', 'action_taken', 'all']).optional()
  ),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
});

export const dismissReportSchema = z.preprocess(
  (val) => val ?? {},
  z.object({
    status: z.enum(['dismissed', 'action_taken']).default('dismissed'),
    resolutionNote: z.string().trim().max(500).optional(),
  })
);

export const deleteContentParamsSchema = z.object({
  type: z.enum(['request', 'review', 'message']),
  id: objectIdSchema,
});

export const deleteContentBodySchema = z.preprocess(
  (val) => val ?? {},
  z.object({
    reason: z.string().trim().min(2).max(500).optional(),
  })
);

export type CreateReportInput = z.infer<typeof createReportSchema>;
export type AdminReportsQuery = z.infer<typeof adminReportsQuerySchema>;
export type DismissReportInput = z.infer<typeof dismissReportSchema>;
export type DeleteContentParams = z.infer<typeof deleteContentParamsSchema>;
export type DeleteContentBody = z.infer<typeof deleteContentBodySchema>;
