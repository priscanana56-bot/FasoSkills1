import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const verificationDocumentSchema = z.object({
  name: z.string().trim().min(1).max(100),
  type: z.string().trim().min(1).max(50).default('document'),
  url: z.string().trim().min(1).max(1000),
});

export const updateArtisanProfileSchema = z.object({
  specialty: z.string().trim().min(2).max(150).optional(),
  city: z.string().trim().min(2).max(100).optional(),
  categoryId: objectIdSchema.optional(),
  experienceYears: z.coerce.number().min(0).max(50).optional(),
  bio: z.string().max(1000).optional(),
  availability: z.string().max(100).optional(),
  documents: z.array(verificationDocumentSchema).max(10).optional(),
});

export const artisanQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
  search: z.string().optional(),
  city: z.string().optional(),
  categoryId: z.string().optional(),
  minRating: z.coerce.number().min(0).max(5).optional(),
});

export const adminArtisansQuerySchema = z.object({
  status: z.preprocess(
    (val) => (val === '' ? undefined : val),
    z.enum(['pending', 'verified', 'all']).default('all')
  ),
  q: z.string().trim().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(10),
});

export const rejectArtisanSchema = z.object({
  reason: z.string().trim().min(3, 'Rejection reason must be at least 3 characters').max(500),
});

export type UpdateArtisanProfileInput = z.infer<typeof updateArtisanProfileSchema>;
export type ArtisanQuery = z.infer<typeof artisanQuerySchema>;
export type AdminArtisansQuery = z.infer<typeof adminArtisansQuerySchema>;
export type RejectArtisanInput = z.infer<typeof rejectArtisanSchema>;
