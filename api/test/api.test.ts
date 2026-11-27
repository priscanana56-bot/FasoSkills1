import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { createApp } from '../src/app.js';
import { Category } from '../src/modules/categories/category.model.js';

let mongod: MongoMemoryServer;
const app = createApp();

let clientToken: string;
let clientRefreshToken: string;
let clientBToken: string;
let artisanToken: string;
let artisanProfileId: string;
let categoryId: string;
let requestId: string;
let quoteId: string;

beforeAll(async () => {
  mongod = await MongoMemoryServer.create({
    instance: {
      launchTimeout: 60000,
    },
  });
  const uri = mongod.getUri();
  await mongoose.connect(uri);

  // Seed one category
  const cat = await Category.create({
    name: 'Plomberie',
    slug: 'plomberie',
    icon: 'plumbing',
  });
  categoryId = cat._id.toString();
}, 90000);

afterAll(async () => {
  await mongoose.disconnect();
  if (mongod) {
    await mongod.stop();
  }
});

describe('A12 - API Integration Tests', () => {
  describe('1. Authentication & Token Lifecycle (A6)', () => {
    it('registers a new client user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'client_a@test.bf',
          fullName: 'Client A',
          password: 'Password123!',
          role: 'client',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.tokens.accessToken).toBeDefined();
      expect(res.body.data.tokens.refreshToken).toBeDefined();
      expect(res.body.data.user.role).toBe('client');

      clientToken = res.body.data.tokens.accessToken;
      clientRefreshToken = res.body.data.tokens.refreshToken;
    });

    it('rejects duplicate email registration with 409', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'client_a@test.bf',
          fullName: 'Client Duplicate',
          password: 'Password123!',
          role: 'client',
        });

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('CONFLICT');
    });

    it('registers a second client user (Client B for authorization tests)', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'client_b@test.bf',
          fullName: 'Client B',
          password: 'Password123!',
          role: 'client',
        });

      expect(res.status).toBe(201);
      clientBToken = res.body.data.tokens.accessToken;
    });

    it('registers an artisan user and creates profile', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'artisan_a@test.bf',
          fullName: 'Artisan Moussa',
          password: 'Password123!',
          role: 'artisan',
          specialty: 'Plombier',
          city: 'Ouagadougou',
          categoryId,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.user.artisanProfileId).toBeDefined();

      artisanToken = res.body.data.tokens.accessToken;
      artisanProfileId = res.body.data.user.artisanProfileId;
    });

    it('logs in successfully with valid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'client_a@test.bf',
          password: 'Password123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.tokens.accessToken).toBeDefined();
    });

    it('rejects invalid password with 401', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'client_a@test.bf',
          password: 'WrongPassword!',
        });

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('refreshes token with rotation (A6)', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: clientRefreshToken });

      expect(res.status).toBe(200);
      expect(res.body.data.accessToken).toBeDefined();
      expect(res.body.data.refreshToken).toBeDefined();

      // Old refresh token must be revoked now
      const retryRes = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: clientRefreshToken });

      expect(retryRes.status).toBe(401);

      // Update active token
      clientToken = res.body.data.accessToken;
      clientRefreshToken = res.body.data.refreshToken;
    });
  });

  describe('2. Artisans & Object Authorization (A7, A8)', () => {
    it('lists artisans with pagination', async () => {
      const res = await request(app).get('/api/artisans?page=1&limit=5');
      expect(res.status).toBe(200);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.pagination.page).toBe(1);
    });

    it('allows artisan to update their own profile', async () => {
      const res = await request(app)
        .put(`/api/artisans/${artisanProfileId}`)
        .set('Authorization', `Bearer ${artisanToken}`)
        .send({
          bio: 'Plombier expérimenté disponible 24/7.',
          experienceYears: 6,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.bio).toBe('Plombier expérimenté disponible 24/7.');
    });

    it('authorisation test: rejects Client A from modifying artisan profile', async () => {
      const res = await request(app)
        .put(`/api/artisans/${artisanProfileId}`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          bio: 'Hacked bio',
        });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('3. Service Requests & Object Authorization (A7, A8)', () => {
    it('allows Client A to create a service request', async () => {
      const res = await request(app)
        .post('/api/requests')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          title: 'Fuite tuyau principal salle de bain',
          description: 'Fuite urgente sous la baignoire avec écoulement continu.',
          categoryId,
          city: 'Ouagadougou',
          address: 'Gounghin Sud',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.title).toBe('Fuite tuyau principal salle de bain');
      expect(res.body.data.status).toBe('pending');
      requestId = res.body.data._id;
    });

    it('allows Client A to update their own request', async () => {
      const res = await request(app)
        .put(`/api/requests/${requestId}`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          title: 'Fuite tuyau principal modifiée',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.title).toBe('Fuite tuyau principal modifiée');
    });

    it('authorization test: Client B CANNOT update Client A’s request (A12 requirement)', async () => {
      const res = await request(app)
        .put(`/api/requests/${requestId}`)
        .set('Authorization', `Bearer ${clientBToken}`)
        .send({
          title: 'Title changed by Client B',
        });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('4. Quotes & Business Rules (T18)', () => {
    it('allows artisan to submit a quote for pending request', async () => {
      const res = await request(app)
        .post('/api/quotes')
        .set('Authorization', `Bearer ${artisanToken}`)
        .send({
          requestId,
          amount: 25000,
          estimatedDays: 1,
          message: 'Je passe avec les joints et soudures nécessaires.',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.amount).toBe(25000);
      quoteId = res.body.data._id;
    });

    it('allows Client A (requester) to view quotes for their request', async () => {
      const res = await request(app)
        .get(`/api/quotes/request/${requestId}`)
        .set('Authorization', `Bearer ${clientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThan(0);
    });

    it('authorization test: Client B CANNOT view quotes for Client A’s request', async () => {
      const res = await request(app)
        .get(`/api/quotes/request/${requestId}`)
        .set('Authorization', `Bearer ${clientBToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('allows Client A to accept quote -> request transitions to in_progress', async () => {
      const res = await request(app)
        .post(`/api/quotes/${quoteId}/accept`)
        .set('Authorization', `Bearer ${clientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('accepted');

      // Verify request is now in_progress
      // Request details carry contact data, so reading them requires authentication.
      const reqRes = await request(app)
        .get(`/api/requests/${requestId}`)
        .set('Authorization', `Bearer ${clientToken}`);
      expect(reqRes.body.data.status).toBe('in_progress');
    });
  });

  describe('5. Reviews & Completed Status Rule (T18)', () => {
    it('rejects review if request is not completed (rule: reviews only for completed jobs)', async () => {
      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          requestId,
          artisanId: artisanProfileId,
          rating: 5,
          comment: 'Too early review',
        });

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('CONFLICT');
    });

    it('allows Client A to mark request completed', async () => {
      const res = await request(app)
        .put(`/api/requests/${requestId}`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ status: 'completed' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('completed');
    });

    it('allows Client A to review completed job and updates artisan rating', async () => {
      const res = await request(app)
        .post('/api/reviews')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          requestId,
          artisanId: artisanProfileId,
          rating: 5,
          comment: 'Travail impeccable et ponctuel !',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.rating).toBe(5);

      // Verify artisan profile rating updated
      const artisanRes = await request(app).get(`/api/artisans/${artisanProfileId}`);
      expect(artisanRes.body.data.rating).toBe(5);
      expect(artisanRes.body.data.completedJobs).toBe(1);
    });
  });
});
