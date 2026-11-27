import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { createApp } from '../src/app.js';
import { User } from '../src/modules/auth/auth.model.js';
import { Category } from '../src/modules/categories/category.model.js';
import { ArtisanProfile } from '../src/modules/artisans/artisan.model.js';
import { ServiceRequest } from '../src/modules/requests/request.model.js';
import { Quote } from '../src/modules/quotes/quote.model.js';
import { Review } from '../src/modules/reviews/review.model.js';
import { Conversation, Message } from '../src/modules/chat/chat.model.js';
import { ModerationLog, Report } from '../src/modules/reports/report.model.js';

let mongod: MongoMemoryServer;
const app = createApp();

let adminToken: string;
let clientToken: string;
let artisanToken: string;

let usedCategoryId: string;
let unusedCategoryId: string;

let pendingArtisanProfileId: string;
let rejectableArtisanProfileId: string;

let requestId: string;
let reviewId: string;
let messageId: string;
let conversationId: string;

let requestReportId: string;
let reviewReportId: string;
let messageReportId: string;

const nonexistentId = new mongoose.Types.ObjectId().toString();

beforeAll(async () => {
  mongod = await MongoMemoryServer.create({
    instance: { launchTimeout: 60000 },
  });
  await mongoose.connect(mongod.getUri());

  const passwordHash = await bcrypt.hash('Password123!', 10);

  // Create admin directly (public /register only permits client/artisan)
  await User.create({
    email: 'admin@test.bf',
    fullName: 'Admin Principal',
    passwordHash,
    role: 'admin',
    isVerified: true,
  });

  const adminLogin = await request(app)
    .post('/api/auth/login')
    .send({ email: 'admin@test.bf', password: 'Password123!' });
  adminToken = adminLogin.body.data.tokens.accessToken;

  const catUsed = await Category.create({
    name: 'Électricité',
    slug: 'electricite',
    icon: 'electrical_services',
  });
  usedCategoryId = catUsed._id.toString();

  // Register client
  const clientRes = await request(app).post('/api/auth/register').send({
    email: 'client_mod@test.bf',
    fullName: 'Client ModTest',
    password: 'Password123!',
    role: 'client',
  });
  clientToken = clientRes.body.data.tokens.accessToken;

  // Register two artisans
  const artisanRes1 = await request(app).post('/api/auth/register').send({
    email: 'artisan_pending@test.bf',
    fullName: 'Issa Ouédraogo',
    password: 'Password123!',
    role: 'artisan',
    specialty: 'Électricien solaire',
    city: 'Ouagadougou',
    categoryId: usedCategoryId,
  });
  artisanToken = artisanRes1.body.data.tokens.accessToken;
  pendingArtisanProfileId = artisanRes1.body.data.user.artisanProfileId;

  // Attach verification documents to pending artisan
  await ArtisanProfile.findByIdAndUpdate(pendingArtisanProfileId, {
    documents: [
      {
        name: 'CNIB Recto',
        type: 'id_card',
        url: 'https://cdn.fasoskills.bf/docs/cnib-issa.jpg',
      },
    ],
  });

  const artisanRes2 = await request(app).post('/api/auth/register').send({
    email: 'artisan_reject@test.bf',
    fullName: 'Karim Zongo',
    password: 'Password123!',
    role: 'artisan',
    specialty: 'Électricien bâtiment',
    city: 'Bobo-Dioulasso',
    categoryId: usedCategoryId,
  });
  rejectableArtisanProfileId = artisanRes2.body.data.user.artisanProfileId;

  // Create a service request, quote, completed job, review, and chat message for stats & moderation
  const reqRes = await request(app)
    .post('/api/requests')
    .set('Authorization', `Bearer ${clientToken}`)
    .send({
      title: 'Panne tableau électrique urgent',
      description: 'Le disjoncteur principal saute toutes les heures.',
      categoryId: usedCategoryId,
      city: 'Ouagadougou',
      address: 'Patte d Oie',
    });
  requestId = reqRes.body.data._id;

  const completedReqRes = await request(app)
    .post('/api/requests')
    .set('Authorization', `Bearer ${clientToken}`)
    .send({
      title: 'Installation prise triphasée atelier',
      description: 'Pose dune prise industrielle sécurisée dans le garage.',
      categoryId: usedCategoryId,
      city: 'Ouagadougou',
    });
  const completedReqId = completedReqRes.body.data._id;

  const quoteRes = await request(app)
    .post('/api/quotes')
    .set('Authorization', `Bearer ${artisanToken}`)
    .send({
      requestId: completedReqId,
      amount: 35000,
      estimatedDays: 1,
      message: 'Disponible demain matin.',
    });
  const quoteId = quoteRes.body.data._id;

  await request(app)
    .post(`/api/quotes/${quoteId}/accept`)
    .set('Authorization', `Bearer ${clientToken}`);

  await request(app)
    .put(`/api/requests/${completedReqId}`)
    .set('Authorization', `Bearer ${clientToken}`)
    .send({ status: 'completed' });

  const reviewRes = await request(app)
    .post('/api/reviews')
    .set('Authorization', `Bearer ${clientToken}`)
    .send({
      requestId: completedReqId,
      artisanId: pendingArtisanProfileId,
      rating: 4,
      comment: 'Bon travail mais un peu en retard.',
    });
  reviewId = reviewRes.body.data._id;

  // Create a conversation & two messages
  const artisanUser = await User.findOne({ email: 'artisan_pending@test.bf' });
  const convRes = await request(app)
    .post('/api/chat/conversations')
    .set('Authorization', `Bearer ${clientToken}`)
    .send({
      recipientId: artisanUser!._id.toString(),
      initialMessage: 'Bonjour, êtes-vous disponible ?',
    });
  conversationId = convRes.body.data._id;

  const msgRes = await request(app)
    .post(`/api/chat/conversations/${conversationId}/messages`)
    .set('Authorization', `Bearer ${artisanToken}`)
    .send({ text: 'Message inapproprié à modérer' });
  messageId = msgRes.body.data._id;
}, 90000);

afterAll(async () => {
  await mongoose.disconnect();
  if (mongod) {
    await mongod.stop();
  }
});

describe('Admin Backend — Authorization, Workflows & Moderation (§7.1 & §7.3)', () => {
  describe('1. Authorization Matrix (401 without token, 403 for client/artisan)', () => {
    it('rejects unauthenticated requests to all admin endpoints with 401', async () => {
      const checks = await Promise.all([
        request(app).get('/api/admin/stats'),
        request(app).get('/api/admin/artisans'),
        request(app).get(`/api/admin/artisans/${pendingArtisanProfileId}`),
        request(app).post(`/api/artisans/${pendingArtisanProfileId}/verify`),
        request(app)
          .post(`/api/admin/artisans/${pendingArtisanProfileId}/reject`)
          .send({ reason: 'Invalid doc' }),
        request(app).post('/api/categories').send({ name: 'Jardinage' }),
        request(app).patch(`/api/categories/${usedCategoryId}`).send({ isActive: false }),
        request(app).delete(`/api/categories/${usedCategoryId}`),
        request(app).get('/api/admin/reports'),
        request(app).patch(`/api/admin/reports/${nonexistentId}`).send({}),
        request(app).delete(`/api/admin/content/request/${requestId}`),
      ]);

      for (const res of checks) {
        expect(res.status).toBe(401);
        expect(res.body.error.code).toBe('UNAUTHORIZED');
      }
    });

    it('rejects client role on all admin endpoints with 403', async () => {
      const checks = await Promise.all([
        request(app).get('/api/admin/stats').set('Authorization', `Bearer ${clientToken}`),
        request(app).get('/api/admin/artisans').set('Authorization', `Bearer ${clientToken}`),
        request(app)
          .get(`/api/admin/artisans/${pendingArtisanProfileId}`)
          .set('Authorization', `Bearer ${clientToken}`),
        request(app)
          .post(`/api/artisans/${pendingArtisanProfileId}/verify`)
          .set('Authorization', `Bearer ${clientToken}`),
        request(app)
          .post(`/api/admin/artisans/${pendingArtisanProfileId}/reject`)
          .set('Authorization', `Bearer ${clientToken}`)
          .send({ reason: 'No reason' }),
        request(app)
          .post('/api/categories')
          .set('Authorization', `Bearer ${clientToken}`)
          .send({ name: 'Jardinage' }),
        request(app)
          .patch(`/api/categories/${usedCategoryId}`)
          .set('Authorization', `Bearer ${clientToken}`)
          .send({ isActive: false }),
        request(app)
          .delete(`/api/categories/${usedCategoryId}`)
          .set('Authorization', `Bearer ${clientToken}`),
        request(app).get('/api/admin/reports').set('Authorization', `Bearer ${clientToken}`),
        request(app)
          .patch(`/api/admin/reports/${nonexistentId}`)
          .set('Authorization', `Bearer ${clientToken}`)
          .send({}),
        request(app)
          .delete(`/api/admin/content/request/${requestId}`)
          .set('Authorization', `Bearer ${clientToken}`),
      ]);

      for (const res of checks) {
        expect(res.status).toBe(403);
        expect(res.body.error.code).toBe('FORBIDDEN');
      }
    });

    it('rejects artisan role on all admin endpoints with 403 (artisan cannot self-verify)', async () => {
      const checks = await Promise.all([
        request(app).get('/api/admin/stats').set('Authorization', `Bearer ${artisanToken}`),
        request(app).get('/api/admin/artisans').set('Authorization', `Bearer ${artisanToken}`),
        request(app)
          .post(`/api/artisans/${pendingArtisanProfileId}/verify`)
          .set('Authorization', `Bearer ${artisanToken}`),
        request(app)
          .post(`/api/admin/artisans/${pendingArtisanProfileId}/reject`)
          .set('Authorization', `Bearer ${artisanToken}`)
          .send({ reason: 'Self reject' }),
        request(app)
          .post('/api/categories')
          .set('Authorization', `Bearer ${artisanToken}`)
          .send({ name: 'Coiffure' }),
        request(app).get('/api/admin/reports').set('Authorization', `Bearer ${artisanToken}`),
        request(app)
          .delete(`/api/admin/content/request/${requestId}`)
          .set('Authorization', `Bearer ${artisanToken}`),
      ]);

      for (const res of checks) {
        expect(res.status).toBe(403);
        expect(res.body.error.code).toBe('FORBIDDEN');
      }
    });
  });

  describe('2. Artisan Verification & Rejection Workflow', () => {
    it('lists pending artisans with search q and pagination', async () => {
      const res = await request(app)
        .get('/api/admin/artisans?status=pending&q=Issa&page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0]._id).toBe(pendingArtisanProfileId);
      expect(res.body.pagination.total).toBe(1);
    });

    it('rejects invalid status query with 422', async () => {
      const res = await request(app)
        .get('/api/admin/artisans?status=unknown')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(422);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('gets detailed artisan profile including documents for admin', async () => {
      const res = await request(app)
        .get(`/api/admin/artisans/${pendingArtisanProfileId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data._id).toBe(pendingArtisanProfileId);
      expect(res.body.data.documents).toHaveLength(1);
      expect(res.body.data.documents[0].name).toBe('CNIB Recto');

      const notFoundRes = await request(app)
        .get(`/api/admin/artisans/${nonexistentId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(notFoundRes.status).toBe(404);
    });

    it('verifies a pending artisan and returns 409 if already verified', async () => {
      const res = await request(app)
        .post(`/api/artisans/${pendingArtisanProfileId}/verify`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.isVerified).toBe(true);
      expect(res.body.data.verificationStatus).toBe('verified');

      // Second verify attempt must fail with 409 Conflict
      const conflictRes = await request(app)
        .post(`/api/artisans/${pendingArtisanProfileId}/verify`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(conflictRes.status).toBe(409);
      expect(conflictRes.body.error.code).toBe('CONFLICT');

      // Not found returns 404
      const notFoundRes = await request(app)
        .post(`/api/artisans/${nonexistentId}/verify`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(notFoundRes.status).toBe(404);
    });

    it('validates rejection reason (422) and rejects an artisan with reason', async () => {
      const badRes = await request(app)
        .post(`/api/admin/artisans/${rejectableArtisanProfileId}/reject`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ reason: 'ab' });

      expect(badRes.status).toBe(422);
      expect(badRes.body.error.code).toBe('VALIDATION_ERROR');

      const res = await request(app)
        .post(`/api/admin/artisans/${rejectableArtisanProfileId}/reject`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ reason: 'Pièce justificative illisible' });

      expect(res.status).toBe(200);
      expect(res.body.data.isVerified).toBe(false);
      expect(res.body.data.verificationStatus).toBe('rejected');
      expect(res.body.data.rejectionReason).toBe('Pièce justificative illisible');

      // Pending tab no longer includes verified or rejected artisans
      const pendingRes = await request(app)
        .get('/api/admin/artisans?status=pending')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(pendingRes.body.data).toHaveLength(0);

      // Verified tab has 1 artisan
      const verifiedRes = await request(app)
        .get('/api/admin/artisans?status=verified')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(verifiedRes.body.data).toHaveLength(1);
    });
  });

  describe('3. Categories CRUD & Integrity Rules', () => {
    it('creates a new category and rejects duplicates (409) and invalid body (422)', async () => {
      const invalidRes = await request(app)
        .post('/api/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ name: 'A' });
      expect(invalidRes.status).toBe(422);

      const createRes = await request(app)
        .post('/api/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Climatisation',
          icon: 'ac_unit',
          description: 'Froid et climatisation',
        });

      expect(createRes.status).toBe(201);
      expect(createRes.body.data.slug).toBe('climatisation');
      unusedCategoryId = createRes.body.data._id;

      // Duplicate name must return 409
      const dupRes = await request(app)
        .post('/api/categories')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ name: 'climatisation' });
      expect(dupRes.status).toBe(409);
    });

    it('updates category including isActive toggle and respects visibility', async () => {
      const patchRes = await request(app)
        .patch(`/api/categories/${unusedCategoryId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isActive: false, description: 'Froid et clim auto' });

      expect(patchRes.status).toBe(200);
      expect(patchRes.body.data.isActive).toBe(false);

      // Public GET hides inactive category
      const publicList = await request(app).get('/api/categories');
      expect(publicList.body.data.some((c: any) => c._id === unusedCategoryId)).toBe(false);

      // Admin GET sees inactive category
      const adminList = await request(app)
        .get('/api/admin/categories')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(adminList.body.data.some((c: any) => c._id === unusedCategoryId)).toBe(true);

      const notFoundRes = await request(app)
        .patch(`/api/categories/${nonexistentId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isActive: true });
      expect(notFoundRes.status).toBe(404);
    });

    it('prevents deleting a category in use (409) and deletes unused category (204)', async () => {
      const inUseRes = await request(app)
        .delete(`/api/categories/${usedCategoryId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(inUseRes.status).toBe(409);
      expect(inUseRes.body.error.code).toBe('CONFLICT');

      const deleteRes = await request(app)
        .delete(`/api/categories/${unusedCategoryId}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(deleteRes.status).toBe(204);

      const notFoundRes = await request(app)
        .delete(`/api/categories/${unusedCategoryId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(notFoundRes.status).toBe(404);
    });
  });

  describe('4. Admin Stats Aggregation Pipeline', () => {
    it('returns aggregated platform statistics and chart series', async () => {
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      const stats = res.body.data;

      expect(stats.users.total).toBe(4);
      expect(stats.users.clients).toBe(1);
      expect(stats.users.artisans).toBe(2);
      expect(stats.users.admins).toBe(1);

      expect(stats.artisans.total).toBe(2);
      expect(stats.artisans.verified).toBe(1);
      expect(stats.artisans.rejected).toBe(1);
      expect(stats.artisans.pending).toBe(0);

      expect(stats.requests.total).toBe(2);
      expect(stats.requests.pending).toBe(1);
      expect(stats.requests.completed).toBe(1);

      expect(stats.quotes.total).toBe(1);
      expect(stats.quotes.accepted).toBe(1);
      expect(stats.quotes.totalAcceptedAmount).toBe(35000);

      expect(stats.charts.requestsByCategory).toBeInstanceOf(Array);
      expect(stats.charts.artisansByCity).toBeInstanceOf(Array);
    });
  });

  describe('5. Content Reporting & Admin Moderation', () => {
    it('allows client/artisan to report existing request, review, and message; rejects 404/422', async () => {
      const missingRes = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          targetType: 'request',
          targetId: nonexistentId,
          reason: 'Contenu inexistant',
        });
      expect(missingRes.status).toBe(404);

      const invalidRes = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          targetType: 'invalid_type',
          targetId: requestId,
          reason: 'Bad',
        });
      expect(invalidRes.status).toBe(422);

      const r1 = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${artisanToken}`)
        .send({
          targetType: 'request',
          targetId: requestId,
          reason: 'Demande frauduleuse',
        });
      expect(r1.status).toBe(201);
      requestReportId = r1.body.data._id;

      const r2 = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${artisanToken}`)
        .send({
          targetType: 'review',
          targetId: reviewId,
          reason: 'Propos diffamatoires',
        });
      expect(r2.status).toBe(201);
      reviewReportId = r2.body.data._id;

      const r3 = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${clientToken}`)
        .send({
          targetType: 'message',
          targetId: messageId,
          reason: 'Langage inapproprié',
        });
      expect(r3.status).toBe(201);
      messageReportId = r3.body.data._id;
    });

    it('lists and filters reports for admin with hydrated targets', async () => {
      const res = await request(app)
        .get('/api/admin/reports?type=request&status=pending&page=1&limit=10')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0]._id).toBe(requestReportId);
      expect(res.body.data[0].target).toBeTruthy();

      const badQuery = await request(app)
        .get('/api/admin/reports?type=invalid')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(badQuery.status).toBe(422);
    });

    it('dismisses a report via PATCH /api/admin/reports/:id', async () => {
      const res = await request(app)
        .patch(`/api/admin/reports/${requestReportId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ resolutionNote: 'Demande conforme aux règles' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('dismissed');

      const notFoundRes = await request(app)
        .patch(`/api/admin/reports/${nonexistentId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(notFoundRes.status).toBe(404);
    });

    it('deletes reported request, review, and message with audit logs (204)', async () => {
      // 1. Delete request
      const delReq = await request(app)
        .delete(`/api/admin/content/request/${requestId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ reason: 'Annonce spam confirmée' });
      expect(delReq.status).toBe(204);
      expect(await ServiceRequest.findById(requestId)).toBeNull();

      // 2. Delete review and confirm artisan rating resets
      const delReview = await request(app)
        .delete(`/api/admin/content/review/${reviewId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ reason: 'Avis abusif' });
      expect(delReview.status).toBe(204);
      expect(await Review.findById(reviewId)).toBeNull();
      const updatedArtisan = await ArtisanProfile.findById(pendingArtisanProfileId);
      expect(updatedArtisan?.reviewsCount).toBe(0);
      expect(updatedArtisan?.rating).toBe(0);

      // 3. Delete message and confirm conversation lastMessage updates
      const delMsg = await request(app)
        .delete(`/api/admin/content/message/${messageId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ reason: 'Message contraire à la charte' });
      expect(delMsg.status).toBe(204);
      expect(await Message.findById(messageId)).toBeNull();
      const updatedConv = await Conversation.findById(conversationId);
      expect(updatedConv?.lastMessage).toBe('Bonjour, êtes-vous disponible ?');

      // Pending reports on deleted items are marked action_taken
      const resolvedReviewReport = await Report.findById(reviewReportId);
      const resolvedMsgReport = await Report.findById(messageReportId);
      expect(resolvedReviewReport?.status).toBe('action_taken');
      expect(resolvedMsgReport?.status).toBe('action_taken');

      // Audit logs recorded all deletion reasons
      const logs = await ModerationLog.find({ action: 'delete_content' }).lean();
      expect(logs).toHaveLength(3);
      expect(logs.map((l) => l.reason)).toContain('Annonce spam confirmée');

      // Deleting non-existent content returns 404
      const notFoundDel = await request(app)
        .delete(`/api/admin/content/request/${nonexistentId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(notFoundDel.status).toBe(404);
    });
  });
});
