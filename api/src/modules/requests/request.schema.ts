import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const createRequestSchema = z.object({
  title: z.string().trim().min(5).max(200),
  description: z.string().trim().min(10),
  categoryId: objectIdSchema,
  city: z.string().trim().min(2).max(100),
  address: z.string().optional(),
  photos: z.array(z.string()).optional().default([]),
});

export const updateRequestSchema = z.object({
  title: z.string().trim().min(5).max(200).optional(),
  description: z.string().trim().min(10).optional(),
  city: z.string().trim().min(2).max(100).optional(),
  address: z.string().optional(),
  status: z.enum(['pending', 'in_progress', 'completed', 'cancelled']).optional(),
});

export const requestQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
  search: z.string().optional(),
  city: z.string().optional(),
  categoryId: z.string().optional(),
  status: z.string().optional(),
  myOnly: z.enum(['true', 'false']).optional(),
  /**
   * Artisan only:
   *  - `open`     : pending requests they can quote on (defaults to their own category)
   *  - `missions` : requests where their quote was accepted
   */
  scope: z.enum(['open', 'missions']).optional(),
  allCategories: z.enum(['true', 'false']).optional(),
});

export type CreateRequestInput = z.infer<typeof createRequestSchema>;
export type UpdateRequestInput = z.infer<typeof updateRequestSchema>;
export type RequestQuery = z.infer<typeof requestQuerySchema>;
