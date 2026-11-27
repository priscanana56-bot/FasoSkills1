import { z } from 'zod';
import { objectIdSchema } from '../../core/utils/validation.js';

export const startConversationSchema = z.object({
  recipientId: objectIdSchema,
  initialMessage: z.string().trim().min(1).max(2000).optional(),
  requestId: objectIdSchema.optional(),
});

export const sendMessageSchema = z.object({
  text: z.string().trim().min(1).max(2000),
});

export const conversationParamsSchema = z.object({
  conversationId: objectIdSchema,
});

export type StartConversationInput = z.infer<typeof startConversationSchema>;
export type SendMessageInput = z.infer<typeof sendMessageSchema>;
