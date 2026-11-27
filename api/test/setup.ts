import crypto from 'crypto';

process.env.NODE_ENV = 'test';
process.env.JWT_ACCESS_SECRET ||= crypto.randomBytes(32).toString('hex');
process.env.JWT_REFRESH_SECRET ||= crypto.randomBytes(32).toString('hex');
