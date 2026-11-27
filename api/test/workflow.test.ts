import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { createApp } from '../src/app.js';
import { Category } from '../src/modules/categories/category.model.js';

let mongod: MongoMemoryServer;
const app = createApp();

const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

let plomberieId: string;
let peintureId: string;
let client = { token: '', id: '' };
let otherClient = { token: '', id: '' };
let plumber = { token: '', id: '', profileId: '' };
let plumber2 = { token: '', id: '', profileId: '' };
let painter = { token: '', id: '', profileId: '' };
let requestId: string;
let quoteId: string;
let quote2Id: string;
let conversationId: string;
let acceptedArtisan: typeof plumber | null = null;
let losingArtisan: typeof plumber | null = null;

async function register(body: Record<string, unknown>) {
  const res = await request(app).post('/api/auth/register').send({ password: 'Password123!', ...body });
  expect(res.status).toBe(201);
  return {
    token: res.body.data.tokens.accessToken as string,
    id: res.body.data.user.id as string,
    profileId: (res.body.data.user.artisanProfileId ?? '') as string,
  };
}

beforeAll(async () => {
  mongod = await MongoMemoryServer.create({ instance: { launchTimeout: 60000 } });
  await mongoose.connect(mongod.getUri());

  const [plomberie, peinture] = await Category.create([
    { name: 'Plomberie', slug: 'plomberie', icon: 'plumbing' },
    { name: 'Peinture', slug: 'peinture', icon: 'format_paint' },
  ]);
  plomberieId = plomberie._id.toString();
  peintureId = peinture._id.toString();

  client = await register({ email: 'wf_client@test.bf', fullName: 'Client Workflow', role: 'client' });
  otherClient = await register({ email: 'wf_client2@test.bf', fullName: 'Autre Client', role: 'client' });
  plumber = await register({
    email: 'wf_plumber@test.bf', fullName: 'Plombier Un', role: 'artisan',
    specialty: 'Plombier', city: 'Ouagadougou', categoryId: plomberieId,
  });
  plumber2 = await register({
    email: 'wf_plumber2@test.bf', fullName: 'Plombier Deux', role: 'artisan',
    specialty: 'Plombier', city: 'Ouagadougou', categoryId: plomberieId,
  });
  painter = await register({
    email: 'wf_painter@test.bf', fullName: 'Peintre Un', role: 'artisan',
    specialty: 'Peintre', city: 'Ouagadougou', categoryId: peintureId,
  });
}, 90000);

afterAll(async () => {
  await mongoose.disconnect();
  if (mongod) await mongod.stop();
});

describe('Client / artisan workflow', () => {
  describe('Profile', () => {
    it('/auth/me returns the same user shape as login, with artisanProfileId', async () => {
      const res = await request(app).get('/api/auth/me').set(auth(plumber.token));
      expect(res.status).toBe(200);
      expect(res.body.data.user.id).toBe(plumber.id);
      expect(res.body.data.user.role).toBe('artisan');
      expect(res.body.data.user.artisanProfileId).toBe(plumber.profileId);
      expect(res.body.data.user.passwordHash).toBeUndefined();
    });

    it('updates the current user profile', async () => {
      const res = await request(app)
        .patch('/api/auth/me')
        .set(auth(client.token))
        .send({ fullName: 'Client Renommé', phone: '+22670999999' });
      expect(res.status).toBe(200);
      expect(res.body.data.user.fullName).toBe('Client Renommé');
    });

    it('rejects a password change with a wrong current password', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set(auth(client.token))
        .send({ currentPassword: 'wrong', newPassword: 'NewPassword1!' });
      expect(res.status).toBe(401);
    });

    it('lets an artisan read and update their own profile via /artisans/me', async () => {
      const res = await request(app)
        .put('/api/artisans/me')
        .set(auth(plumber.token))
        .send({ bio: 'Dépannage rapide', experienceYears: 7 });
      expect(res.status).toBe(200);
      expect(res.body.data.experienceYears).toBe(7);

      const forbidden = await request(app).get('/api/artisans/me').set(auth(client.token));
      expect(forbidden.status).toBe(403);
    });
  });

  describe('Requests are scoped by role', () => {
    it('only a client can create a request, and matching artisans are notified', async () => {
      const denied = await request(app)
        .post('/api/requests')
        .set(auth(plumber.token))
        .send({ title: 'Fuite évier cuisine', description: 'Fuite sous évier depuis hier.', categoryId: plomberieId, city: 'Ouagadougou' });
      expect(denied.status).toBe(403);

      const res = await request(app)
        .post('/api/requests')
        .set(auth(client.token))
        .send({ title: 'Fuite évier cuisine', description: 'Fuite sous évier depuis hier.', categoryId: plomberieId, city: 'Ouagadougou' });
      expect(res.status).toBe(201);
      requestId = res.body.data._id;

      const plumberNotifs = await request(app).get('/api/notifications').set(auth(plumber.token));
      expect(plumberNotifs.body.data.some((n: any) => n.type === 'request:new')).toBe(true);
      const painterNotifs = await request(app).get('/api/notifications').set(auth(painter.token));
      expect(painterNotifs.body.data.some((n: any) => n.type === 'request:new')).toBe(false);
    });

    it('requires authentication to list or read requests', async () => {
      expect((await request(app).get('/api/requests')).status).toBe(401);
      expect((await request(app).get(`/api/requests/${requestId}`)).status).toBe(401);
    });

    it('a client only sees their own requests', async () => {
      const mine = await request(app).get('/api/requests').set(auth(client.token));
      expect(mine.body.data).toHaveLength(1);
      const theirs = await request(app).get('/api/requests').set(auth(otherClient.token));
      expect(theirs.body.data).toHaveLength(0);
      const read = await request(app).get(`/api/requests/${requestId}`).set(auth(otherClient.token));
      expect(read.status).toBe(403);
    });

    it("an artisan's open feed only contains pending requests of their category", async () => {
      const plumberFeed = await request(app).get('/api/requests?scope=open').set(auth(plumber.token));
      expect(plumberFeed.status).toBe(200);
      expect(plumberFeed.body.data.map((r: any) => r._id)).toContain(requestId);
      expect(plumberFeed.body.data[0].myQuote).toBeNull();

      const painterFeed = await request(app).get('/api/requests?scope=open').set(auth(painter.token));
      expect(painterFeed.body.data).toHaveLength(0);
    });
  });

  describe('Quotes lifecycle', () => {
    it('artisans quote, the client is notified, and the artisan sees it in /quotes/mine', async () => {
      const q1 = await request(app).post('/api/quotes').set(auth(plumber.token))
        .send({ requestId, amount: 15000, estimatedDays: 1, message: 'Je passe demain.' });
      expect(q1.status).toBe(201);
      quoteId = q1.body.data._id;

      const q2 = await request(app).post('/api/quotes').set(auth(plumber2.token))
        .send({ requestId, amount: 18000, estimatedDays: 2 });
      expect(q2.status).toBe(201);
      quote2Id = q2.body.data._id;

      const notifs = await request(app).get('/api/notifications').set(auth(client.token));
      expect(notifs.body.data.filter((n: any) => n.type === 'quote:received')).toHaveLength(2);
      expect(notifs.body.unreadCount).toBeGreaterThanOrEqual(2);

      const mine = await request(app).get('/api/quotes/mine').set(auth(plumber.token));
      expect(mine.status).toBe(200);
      expect(mine.body.data).toHaveLength(1);
      expect(mine.body.data[0].requestId.title).toBe('Fuite évier cuisine');

      const feed = await request(app).get('/api/requests?scope=open').set(auth(plumber.token));
      expect(feed.body.data[0].myQuote._id).toBe(quoteId);
      expect(feed.body.data[0].quotesCount).toBe(2);
    });

    it('an artisan cannot withdraw another artisan quote', async () => {
      const res = await request(app).delete(`/api/quotes/${quoteId}`).set(auth(plumber2.token));
      expect(res.status).toBe(403);
    });

    it('accepting a quote notifies the winner and the other artisans, and creates a mission', async () => {
      const [first, second] = await Promise.all([
        request(app).post(`/api/quotes/${quoteId}/accept`).set(auth(client.token)),
        request(app).post(`/api/quotes/${quote2Id}/accept`).set(auth(client.token)),
      ]);
      expect([first.status, second.status].sort()).toEqual([200, 409]);
      const winnerQuoteId = first.status === 200 ? quoteId : quote2Id;
      const loserQuoteId = winnerQuoteId === quoteId ? quote2Id : quoteId;
      const winnerProfile = winnerQuoteId === quoteId ? plumber : plumber2;
      const loserProfile = winnerQuoteId === quoteId ? plumber2 : plumber;
      acceptedArtisan = winnerProfile;
      losingArtisan = loserProfile;

      const winnerNotifications = await request(app).get('/api/notifications').set(auth(winnerProfile.token));
      expect(winnerNotifications.body.data.some((n: any) => n.type === 'quote:accepted')).toBe(true);
      const loserNotifications = await request(app).get('/api/notifications').set(auth(loserProfile.token));
      expect(loserNotifications.body.data.some((n: any) => n.type === 'quote:rejected')).toBe(true);

      const missions = await request(app).get('/api/requests?scope=missions').set(auth(winnerProfile.token));
      expect(missions.body.data.map((r: any) => r._id)).toEqual([requestId]);
      const noMission = await request(app).get('/api/requests?scope=missions').set(auth(loserProfile.token));
      expect(noMission.body.data).toHaveLength(0);

      const stats = await request(app).get('/api/artisans/me/stats').set(auth(winnerProfile.token));
      expect(stats.body.data.activeMissions).toBe(1);

      const declined = await request(app).post(`/api/quotes/${loserQuoteId}/reject`).set(auth(client.token));
      expect(declined.status).toBe(409);
    });

    it('forbids illegal status transitions', async () => {
      const res = await request(app).put(`/api/requests/${requestId}`).set(auth(client.token)).send({ status: 'pending' });
      expect(res.status).toBe(409);
      const edit = await request(app).put(`/api/requests/${requestId}`).set(auth(client.token)).send({ title: 'Nouveau titre long' });
      expect(edit.status).toBe(409);
    });

    it('the assigned artisan can mark the job completed, which credits their counter', async () => {
      if (!acceptedArtisan || !losingArtisan) throw new Error('Accepted artisan was not initialized');

      const other = await request(app).put(`/api/requests/${requestId}`).set(auth(losingArtisan.token)).send({ status: 'completed' });
      expect(other.status).toBe(403);

      const res = await request(app).put(`/api/requests/${requestId}`).set(auth(acceptedArtisan.token)).send({ status: 'completed' });
      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('completed');

      const profile = await request(app).get(`/api/artisans/${acceptedArtisan.profileId}`);
      expect(profile.body.data.completedJobs).toBe(1);

      const notifs = await request(app).get('/api/notifications').set(auth(client.token));
      expect(notifs.body.data.some((n: any) => n.type === 'request:completed')).toBe(true);
    });

    it('a review always targets the assigned artisan', async () => {
      if (!acceptedArtisan || !losingArtisan) throw new Error('Accepted artisan was not initialized');

      const wrong = await request(app).post('/api/reviews').set(auth(client.token))
        .send({ requestId, artisanId: losingArtisan.profileId, rating: 1 });
      expect(wrong.status).toBe(403);

      const res = await request(app).post('/api/reviews').set(auth(client.token)).send({ requestId, rating: 4 });
      expect(res.status).toBe(201);
      expect(res.body.data.artisanId).toBe(acceptedArtisan.profileId);

      const detail = await request(app).get(`/api/requests/${requestId}`).set(auth(client.token));
      expect(detail.body.data.review.rating).toBe(4);
    });
  });

  describe('Chat keeps client and artisan spaces separate', () => {
    it('refuses client↔client and artisan↔artisan conversations, and self-conversations', async () => {
      const cc = await request(app).post('/api/chat/conversations').set(auth(client.token)).send({ recipientId: otherClient.id });
      expect(cc.status).toBe(403);
      const aa = await request(app).post('/api/chat/conversations').set(auth(plumber.token)).send({ recipientId: painter.id });
      expect(aa.status).toBe(403);
      const self = await request(app).post('/api/chat/conversations').set(auth(client.token)).send({ recipientId: client.id });
      expect(self.status).toBe(422);
    });

    it('returns the other participant and unread count from each viewer point of view', async () => {
      const start = await request(app).post('/api/chat/conversations').set(auth(client.token))
        .send({ recipientId: plumber.id, initialMessage: 'Bonjour, merci pour le travail !' });
      expect(start.status).toBe(200);
      conversationId = start.body.data._id;
      expect(start.body.data.otherParticipant._id).toBe(plumber.id);
      expect(start.body.data.otherParticipant.artisanProfile.specialty).toBe('Plombier');

      // Same pair → same conversation, never a duplicate.
      const again = await request(app).post('/api/chat/conversations').set(auth(plumber.token)).send({ recipientId: client.id });
      expect(again.body.data._id).toBe(conversationId);
      expect(again.body.data.otherParticipant._id).toBe(client.id);

      const artisanList = await request(app).get('/api/chat/conversations').set(auth(plumber.token));
      expect(artisanList.body.data).toHaveLength(1);
      expect(artisanList.body.data[0].otherParticipant.fullName).toBe('Client Renommé');
      expect(artisanList.body.data[0].unreadCount).toBe(1);

      const clientList = await request(app).get('/api/chat/conversations').set(auth(client.token));
      expect(clientList.body.data[0].unreadCount).toBe(0);

      const otherList = await request(app).get('/api/chat/conversations').set(auth(otherClient.token));
      expect(otherList.body.data).toHaveLength(0);
    });

    it('marks messages as read and keeps outsiders out', async () => {
      const unread = await request(app).get('/api/chat/unread-count').set(auth(plumber.token));
      expect(unread.body.data.unreadCount).toBe(1);

      const read = await request(app).post(`/api/chat/conversations/${conversationId}/read`).set(auth(plumber.token));
      expect(read.body.data.updated).toBe(1);
      const after = await request(app).get('/api/chat/unread-count').set(auth(plumber.token));
      expect(after.body.data.unreadCount).toBe(0);

      const outsider = await request(app).get(`/api/chat/conversations/${conversationId}/messages`).set(auth(painter.token));
      expect(outsider.status).toBe(403);
    });
  });

  describe('Notifications', () => {
    it('marks one and then all notifications as read, scoped to the owner', async () => {
      const list = await request(app).get('/api/notifications').set(auth(client.token));
      const first = list.body.data[0]._id;

      const stolen = await request(app).patch(`/api/notifications/${first}/read`).set(auth(otherClient.token));
      expect(stolen.status).toBe(404);

      const one = await request(app).patch(`/api/notifications/${first}/read`).set(auth(client.token));
      expect(one.body.data.isRead).toBe(true);

      await request(app).post('/api/notifications/read-all').set(auth(client.token));
      const count = await request(app).get('/api/notifications/unread-count').set(auth(client.token));
      expect(count.body.data.unreadCount).toBe(0);
    });
  });
});
