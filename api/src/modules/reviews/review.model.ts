import mongoose, { Schema, type Document } from 'mongoose';

export interface IReview extends Document {
  requestId: mongoose.Types.ObjectId;
  clientId: mongoose.Types.ObjectId;
  artisanId: mongoose.Types.ObjectId;
  rating: number;
  comment?: string;
  createdAt: Date;
}

const reviewSchema = new Schema<IReview>(
  {
    requestId: { type: Schema.Types.ObjectId, ref: 'ServiceRequest', required: true, unique: true },
    clientId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    artisanId: { type: Schema.Types.ObjectId, ref: 'ArtisanProfile', required: true, index: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, default: '' },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

reviewSchema.index({ artisanId: 1, createdAt: -1 });

export const Review = mongoose.model<IReview>('Review', reviewSchema);
