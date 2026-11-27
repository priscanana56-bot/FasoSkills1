import mongoose, { Schema, type Document } from 'mongoose';

export type ReportTargetType = 'request' | 'review' | 'message';
export type ReportStatus = 'pending' | 'dismissed' | 'action_taken';

export interface IReport extends Document {
  reporterId: mongoose.Types.ObjectId;
  targetType: ReportTargetType;
  targetId: mongoose.Types.ObjectId;
  reason: string;
  description: string;
  status: ReportStatus;
  targetSnapshot?: Record<string, unknown>;
  resolvedBy?: mongoose.Types.ObjectId;
  resolvedAt?: Date;
  resolutionNote?: string;
  createdAt: Date;
  updatedAt: Date;
}

const reportSchema = new Schema<IReport>(
  {
    reporterId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    targetType: {
      type: String,
      enum: ['request', 'review', 'message'],
      required: true,
      index: true,
    },
    targetId: { type: Schema.Types.ObjectId, required: true, index: true },
    reason: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    status: {
      type: String,
      enum: ['pending', 'dismissed', 'action_taken'],
      default: 'pending',
      index: true,
    },
    targetSnapshot: { type: Schema.Types.Mixed },
    resolvedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    resolvedAt: { type: Date },
    resolutionNote: { type: String, trim: true },
  },
  { timestamps: true }
);

reportSchema.index({ targetType: 1, status: 1, createdAt: -1 });
reportSchema.index({ targetType: 1, targetId: 1 });

export const Report = mongoose.model<IReport>('Report', reportSchema);

export interface IModerationLog extends Document {
  adminId: mongoose.Types.ObjectId;
  action: 'delete_content' | 'dismiss_report' | 'verify_artisan' | 'reject_artisan';
  targetType: ReportTargetType | 'artisan' | 'report';
  targetId: mongoose.Types.ObjectId;
  reason: string;
  targetSnapshot?: Record<string, unknown>;
  createdAt: Date;
}

const moderationLogSchema = new Schema<IModerationLog>(
  {
    adminId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    action: {
      type: String,
      enum: ['delete_content', 'dismiss_report', 'verify_artisan', 'reject_artisan'],
      required: true,
    },
    targetType: {
      type: String,
      enum: ['request', 'review', 'message', 'artisan', 'report'],
      required: true,
      index: true,
    },
    targetId: { type: Schema.Types.ObjectId, required: true, index: true },
    reason: { type: String, required: true, trim: true },
    targetSnapshot: { type: Schema.Types.Mixed },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

moderationLogSchema.index({ createdAt: -1 });

export const ModerationLog = mongoose.model<IModerationLog>('ModerationLog', moderationLogSchema);
