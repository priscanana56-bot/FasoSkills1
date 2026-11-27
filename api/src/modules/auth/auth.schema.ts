import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const registerSchema = z.object({
  email: z.string().email(),
  phone: z.string().min(8).max(20).optional(),
  fullName: z.string().min(2).max(100),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  role: z.enum(['client', 'artisan']).default('client'),
  // Artisan optional initial fields
  specialty: z.string().optional(),
  city: z.string().optional(),
  categoryId: objectIdSchema.optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const updateMeSchema = z.object({
  fullName: z.string().trim().min(2).max(100).optional(),
  phone: z.string().trim().min(8).max(20).optional(),
  profilePicture: z.string().trim().max(2_000_000).optional(),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6, 'Password must be at least 6 characters'),
});

export type UpdateMeInput = z.infer<typeof updateMeSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
