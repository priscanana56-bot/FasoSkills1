import mongoose, { Schema, type Document } from 'mongoose';

export interface IServiceRequest extends Document {
  clientId: mongoose.Types.ObjectId;
  categoryId: mongoose.Types.ObjectId;
  title: string;
  description: string;
  city: string;
  address?: string;
  photos: string[];
  status: 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled';
  acceptedQuoteId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const serviceRequestSchema = new Schema<IServiceRequest>(
  {
    clientId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true },
    city: { type: String, required: true, trim: true, index: true },
    address: { type: String, default: '' },
    photos: { type: [String], default: [] },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'],
      default: 'pending',
      index: true,
    },
    acceptedQuoteId: { type: Schema.Types.ObjectId, ref: 'Quote' },
  },
  { timestamps: true }
);

serviceRequestSchema.index({ city: 1, status: 1 });
serviceRequestSchema.index({ createdAt: -1 });

export const ServiceRequest = mongoose.model<IServiceRequest>('ServiceRequest', serviceRequestSchema);
