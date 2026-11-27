import express, { type Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { env } from './config/env.js';

import authRoutes from './modules/auth/auth.routes.js';
import categoryRoutes from './modules/categories/category.routes.js';
import artisanRoutes from './modules/artisans/artisan.routes.js';
import requestRoutes from './modules/requests/request.routes.js';
import quoteRoutes from './modules/quotes/quote.routes.js';
import reviewRoutes from './modules/reviews/review.routes.js';
import chatRoutes from './modules/chat/chat.routes.js';
import reportRoutes from './modules/reports/report.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';
import notificationRoutes from './modules/notifications/notification.routes.js';

import { errorHandler } from './core/middlewares/error-handler.js';
import { NotFoundError } from './core/errors/app-error.js';

export function createApp(): Application {
  const app: Application = express();

  // A11. Security middlewares - allow cross-origin resource policy for Flutter Web
  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }));
  app.use(cors({
    origin: env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(',').map((origin) => origin.trim()),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }));

  // A11. Body size limit
  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true, limit: '5mb' }));

  // A11. Rate limiter for authentication routes
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      error: {
        code: 'TOO_MANY_REQUESTS',
        message: 'Too many authentication attempts, please try again later.',
      },
    },
  });

  // Health check endpoint
  app.get('/api/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // Modules routes
  app.use('/api/auth', authLimiter, authRoutes);
  app.use('/api/categories', categoryRoutes);
  app.use('/api/artisans', artisanRoutes);
  app.use('/api/requests', requestRoutes);
  app.use('/api/quotes', quoteRoutes);
  app.use('/api/reviews', reviewRoutes);
  app.use('/api/chat', chatRoutes);
  app.use('/api/reports', reportRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/notifications', notificationRoutes);

  // 404 handler for undefined routes
  app.use((_req, _res, next) => {
    next(new NotFoundError('API Route'));
  });

  // A5. Centralized error handling
  app.use(errorHandler);

  return app;
}
