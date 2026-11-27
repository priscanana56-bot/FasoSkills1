import { z } from 'zod';

export const createReviewSchema = z.object({
  requestId: z.string().min(1),
  // Optional: derived from the accepted quote. If sent, it must match it.
  artisanId: z.string().min(1).optional(),
  rating: z.coerce.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
});

export const reviewQuerySchema = z.object({
  artisanId: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
});

export type CreateReviewInput = z.infer<typeof createReviewSchema>;
export type ReviewQuery = z.infer<typeof reviewQuerySchema>;
