import mongoose from 'mongoose';
import { env } from './env.js';

export async function connectDatabase(uri?: string): Promise<void> {
  const targetUri = uri || env.MONGODB_URI;
  if (mongoose.connection.readyState === 1) return;
  await mongoose.connect(targetUri);
  console.log(` Connected to MongoDB: ${targetUri}`);
}

export async function disconnectDatabase(): Promise<void> {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
}
