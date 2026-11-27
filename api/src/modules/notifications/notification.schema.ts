import { z } from 'zod';

export const notificationQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20),
  unreadOnly: z.enum(['true', 'false']).optional(),
});

export type NotificationQuery = z.infer<typeof notificationQuerySchema>;
