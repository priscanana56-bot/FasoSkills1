import mongoose, { Schema, type Document } from 'mongoose';

export const NOTIFICATION_TYPES = [
  'request:new',
  'request:updated',
  'request:completed',
  'request:cancelled',
  'quote:received',
  'quote:accepted',
  'quote:rejected',
  'message:new',
  'review:new',
  'artisan:verified',
  'artisan:rejected',
] as const;

export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

export interface INotification extends Document {
  userId: mongoose.Types.ObjectId;
  type: NotificationType;
  title: string;
  body: string;
  /** Free-form payload used by the app to deep-link (requestId, conversationId, quoteId...). */
  data: Record<string, unknown>;
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const notificationSchema = new Schema<INotification>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, enum: NOTIFICATION_TYPES, required: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, default: '', trim: true },
    data: { type: Schema.Types.Mixed, default: {} },
    isRead: { type: Boolean, default: false, index: true },
  },
  { timestamps: true }
);

notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

export const Notification = mongoose.model<INotification>('Notification', notificationSchema);
