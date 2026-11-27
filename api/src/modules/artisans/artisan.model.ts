import mongoose, { Schema, type Document } from 'mongoose';

export interface IVerificationDocument {
  name: string;
  type: string;
  url: string;
  uploadedAt: Date;
}

export interface IArtisanProfile extends Document {
  userId: mongoose.Types.ObjectId;
  category?: mongoose.Types.ObjectId;
  specialty: string;
  city: string;
  experienceYears: number;
  bio: string;
  availability: string;
  rating: number;
  reviewsCount: number;
  completedJobs: number;
  isVerified: boolean;
  verificationStatus: 'pending' | 'verified' | 'rejected';
  rejectionReason?: string;
  verifiedAt?: Date;
  verifiedBy?: mongoose.Types.ObjectId;
  rejectedAt?: Date;
  rejectedBy?: mongoose.Types.ObjectId;
  documents: IVerificationDocument[];
  profileStatus: 'incomplete' | 'complete';
  createdAt: Date;
  updatedAt: Date;
}

const verificationDocumentSchema = new Schema<IVerificationDocument>(
  {
    name: { type: String, required: true, trim: true },
    type: { type: String, default: 'document', trim: true },
    url: { type: String, required: true, trim: true },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: true }
);

const artisanProfileSchema = new Schema<IArtisanProfile>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    category: { type: Schema.Types.ObjectId, ref: 'Category', index: true },
    specialty: { type: String, default: '', trim: true },
    city: { type: String, default: 'Ouagadougou', trim: true, index: true },
    experienceYears: { type: Number, default: 0, min: 0 },
    bio: { type: String, default: '' },
    availability: { type: String, default: 'Disponible' },
    rating: { type: Number, default: 0, min: 0, max: 5, index: true },
    reviewsCount: { type: Number, default: 0, min: 0 },
    completedJobs: { type: Number, default: 0, min: 0 },
    isVerified: { type: Boolean, default: false, index: true },
    verificationStatus: {
      type: String,
      enum: ['pending', 'verified', 'rejected'],
      default: 'pending',
      index: true,
    },
    rejectionReason: { type: String, trim: true },
    verifiedAt: { type: Date },
    verifiedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    rejectedAt: { type: Date },
    rejectedBy: { type: Schema.Types.ObjectId, ref: 'User' },
    documents: { type: [verificationDocumentSchema], default: [] },
    profileStatus: { type: String, enum: ['incomplete', 'complete'], default: 'incomplete' },
  },
  { timestamps: true }
);

// Compound indexes for search and filtering - Requirement A10
artisanProfileSchema.index({ category: 1, city: 1 });
artisanProfileSchema.index({ verificationStatus: 1, createdAt: -1 });
artisanProfileSchema.index({ specialty: 'text', bio: 'text' });

export const ArtisanProfile = mongoose.model<IArtisanProfile>('ArtisanProfile', artisanProfileSchema);
