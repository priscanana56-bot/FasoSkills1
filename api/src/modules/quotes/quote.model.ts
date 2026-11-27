import mongoose, { Schema, type Document } from 'mongoose';

export interface IQuote extends Document {
  requestId: mongoose.Types.ObjectId;
  artisanId: mongoose.Types.ObjectId;
  amount: number;
  estimatedDays: number;
  message?: string;
  status: 'pending' | 'accepted' | 'rejected';
  createdAt: Date;
  updatedAt: Date;
}

const quoteSchema = new Schema<IQuote>(
  {
    requestId: { type: Schema.Types.ObjectId, ref: 'ServiceRequest', required: true, index: true },
    artisanId: { type: Schema.Types.ObjectId, ref: 'ArtisanProfile', required: true, index: true },
    amount: { type: Number, required: true, min: 0 },
    estimatedDays: { type: Number, required: true, min: 1 },
    message: { type: String, default: '' },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected'],
      default: 'pending',
      index: true,
    },
  },
  { timestamps: true }
);

quoteSchema.index({ requestId: 1, artisanId: 1 }, { unique: true });

export const Quote = mongoose.model<IQuote>('Quote', quoteSchema);
