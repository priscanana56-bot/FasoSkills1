import { WebSocketServer, WebSocket } from 'ws';
import type { Server } from 'http';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import type { AuthUser } from '../middlewares/auth.js';
import { Conversation } from '../../modules/chat/chat.model.js';
import { ServiceRequest } from '../../modules/requests/request.model.js';
import { Quote } from '../../modules/quotes/quote.model.js';
import { ArtisanProfile } from '../../modules/artisans/artisan.model.js';

interface ClientConnection {
  ws: WebSocket;
  user: AuthUser;
  rooms: Set<string>;
}

class WsManager {
  private wss: WebSocketServer | null = null;
  private clients = new Map<WebSocket, ClientConnection>();

  public init(server: Server): WebSocketServer {
    this.wss = new WebSocketServer({ server, path: '/ws' });

    this.wss.on('connection', (ws: WebSocket, req) => {
      // Authenticate from query param ?token=... or via auth message
      const url = new URL(req.url || '', `http://${req.headers.host}`);
      const token = url.searchParams.get('token');
      let authenticationTimeout: NodeJS.Timeout | null = null;

      let user: AuthUser | null = null;
      if (token) {
        try {
          user = jwt.verify(token, env.JWT_ACCESS_SECRET) as AuthUser;
        } catch {
          // Token invalid, wait for auth message or close
        }
      }

      if (user) {
        this.clients.set(ws, { ws, user, rooms: new Set([`user:${user.id}`]) });
        ws.send(JSON.stringify({ event: 'connected', user: { id: user.id, role: user.role } }));
      } else {
        authenticationTimeout = setTimeout(() => {
          if (!this.clients.has(ws)) {
            ws.close(1008, 'Authentication required');
          }
        }, 30_000);
      }

      ws.on('message', async (data: Buffer | string) => {
        try {
          const payload = JSON.parse(data.toString());
          if (payload.action === 'authenticate' && payload.token) {
            try {
              const decoded = jwt.verify(payload.token, env.JWT_ACCESS_SECRET) as AuthUser;
              this.clients.set(ws, { ws, user: decoded, rooms: new Set([`user:${decoded.id}`]) });
              if (authenticationTimeout) {
                clearTimeout(authenticationTimeout);
                authenticationTimeout = null;
              }
              ws.send(JSON.stringify({ event: 'authenticated', user: { id: decoded.id } }));
            } catch {
              ws.send(JSON.stringify({ event: 'error', message: 'Authentication failed' }));
            }
          } else if (payload.action === 'join_room' && payload.room) {
            const client = this.clients.get(ws);
            if (client) {
              const room = String(payload.room);
              let allowed = false;

              if (room === `user:${client.user.id}`) {
                allowed = true;
              } else if (room.startsWith('conversation:')) {
                const conversationId = room.slice('conversation:'.length);
                const conversation = await Conversation.findById(conversationId).select('participants').lean();
                allowed = client.user.role === 'admin'
                  || !!conversation?.participants.some((participant) => participant.toString() === client.user.id);
              } else if (room.startsWith('request:')) {
                const requestId = room.slice('request:'.length);
                const request = await ServiceRequest.findById(requestId).select('clientId acceptedQuoteId').lean();
                if (client.user.role === 'admin' || request?.clientId.toString() === client.user.id) {
                  allowed = true;
                } else if (request?.acceptedQuoteId) {
                  const quote = await Quote.findById(request.acceptedQuoteId).select('artisanId').lean();
                  if (quote) {
                    const artisan = await ArtisanProfile.findById(quote.artisanId).select('userId').lean();
                    allowed = artisan?.userId.toString() === client.user.id;
                  }
                }
              }

              if (allowed) {
                client.rooms.add(room);
                ws.send(JSON.stringify({ event: 'joined_room', room }));
              } else {
                ws.send(JSON.stringify({ event: 'error', message: 'Room access denied' }));
              }
            }
          } else if (payload.action === 'leave_room' && payload.room) {
            const client = this.clients.get(ws);
            if (client) {
              client.rooms.delete(payload.room);
            }
          }
        } catch (e) {
          // Ignore malformed WS message
        }
      });

      ws.on('close', () => {
        if (authenticationTimeout) {
          clearTimeout(authenticationTimeout);
        }
        this.clients.delete(ws);
      });
    });

    console.log('⚡ WebSocket server running on path /ws');
    return this.wss;
  }

  public broadcastToUser(userId: string, event: string, payload: unknown): void {
    const message = JSON.stringify({ event, data: payload });
    for (const client of this.clients.values()) {
      if (client.user.id === userId && client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message);
      }
    }
  }

  public broadcastToRoom(room: string, event: string, payload: unknown): void {
    const message = JSON.stringify({ event, room, data: payload });
    for (const client of this.clients.values()) {
      if (client.rooms.has(room) && client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message);
      }
    }
  }

  public broadcastAll(event: string, payload: unknown): void {
    const message = JSON.stringify({ event, data: payload });
    for (const client of this.clients.values()) {
      if (client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message);
      }
    }
  }
}

export const wsManager = new WsManager();
