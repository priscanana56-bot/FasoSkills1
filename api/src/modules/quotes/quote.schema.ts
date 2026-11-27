import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const createQuoteSchema = z.object({
  requestId: objectIdSchema,
  amount: z.coerce.number().positive(),
  estimatedDays: z.coerce.number().int().positive(),
  message: z.string().max(1000).optional(),
});

export const quoteQuerySchema = z.object({
  requestId: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
});

export const myQuotesQuerySchema = z.object({
  status: z.enum(['pending', 'accepted', 'rejected']).optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20),
});

export type CreateQuoteInput = z.infer<typeof createQuoteSchema>;
export type QuoteQuery = z.infer<typeof quoteQuerySchema>;
export type MyQuotesQuery = z.infer<typeof myQuotesQuerySchema>;
