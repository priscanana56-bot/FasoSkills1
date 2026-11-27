import mongoose from 'mongoose';
import { Conversation, Message } from './chat.model.js';
import { User } from '../auth/auth.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { NotFoundError, ForbiddenError, ValidationError } from '../../core/errors/app-error.js';
import { wsManager } from '../../core/websocket/ws-server.js';
import { notificationService } from '../notifications/notification.service.js';
import type { StartConversationInput, SendMessageInput } from './chat.schema.js';

const PARTICIPANT_FIELDS = 'fullName email phone profilePicture role';

type Role = 'client' | 'artisan' | 'admin';

/**
 * Conversations are always between a client and an artisan (an admin may talk to anyone).
 * This rule keeps the client space and the artisan space from mixing.
 */
function isAllowedPair(a: Role, b: Role): boolean {
  if (a === 'admin' || b === 'admin') return true;
  return a !== b;
}

export class ChatService {
  private async assertParticipant(conversationId: string, userId: string) {
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) throw new NotFoundError('Conversation');
    if (!conversation.participants.some((p) => p.toString() === userId)) {
      throw new ForbiddenError('You are not a participant in this conversation');
    }
    return conversation;
  }

  /** Shapes a conversation for one viewer: the other participant + unread count. */
  private async present(conversations: any[], viewerId: string) {
    if (conversations.length === 0) return [];

    const ids = conversations.map((c) => c._id);
    const unread = await Message.aggregate([
      {
        $match: {
          conversationId: { $in: ids },
          isRead: false,
          senderId: { $ne: new mongoose.Types.ObjectId(viewerId) },
        },
      },
      { $group: { _id: '$conversationId', count: { $sum: 1 } } },
    ]);
    const unreadById = new Map(unread.map((u) => [u._id.toString(), u.count as number]));

    const others = conversations
      .map((c) => (c.participants as any[]).find((p) => p && p._id.toString() !== viewerId))
      .filter(Boolean);
    const artisanUserIds = others.filter((o) => o.role === 'artisan').map((o) => o._id);
    const profiles = await ArtisanProfile.find({ userId: { $in: artisanUserIds } })
      .select('userId specialty city rating isVerified category')
      .populate('category', 'name slug icon')
      .lean();
    const profileByUser = new Map(profiles.map((p) => [p.userId.toString(), p]));

    return conversations.map((c) => {
      const other = (c.participants as any[]).find((p) => p && p._id.toString() !== viewerId) ?? null;
      const profile = other ? profileByUser.get(other._id.toString()) : undefined;
      return {
        ...c,
        otherParticipant: other
          ? {
              ...other,
              artisanProfile: profile
                ? {
                    _id: profile._id,
                    specialty: profile.specialty,
                    city: profile.city,
                    rating: profile.rating,
                    isVerified: profile.isVerified,
                    category: profile.category,
                  }
                : null,
            }
          : null,
        unreadCount: unreadById.get(c._id.toString()) ?? 0,
      };
    });
  }

  public async getOrCreateConversation(userId: string, userRole: Role, input: StartConversationInput) {
    if (input.recipientId === userId) {
      throw new ValidationError('You cannot start a conversation with yourself');
    }

    const recipient = await User.findById(input.recipientId).select('role');
    if (!recipient) throw new NotFoundError('Recipient');
    if (!isAllowedPair(userRole, recipient.role)) {
      throw new ForbiddenError('Conversations are only allowed between a client and an artisan');
    }

    let conversation = await Conversation.findOne({
      participants: { $all: [userId, input.recipientId], $size: 2 },
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [userId, input.recipientId],
        requestId: input.requestId,
      });
    } else if (input.requestId && !conversation.requestId) {
      conversation.requestId = new mongoose.Types.ObjectId(input.requestId);
      await conversation.save();
    }

    if (input.initialMessage) {
      await this.sendMessage(conversation._id.toString(), userId, { text: input.initialMessage });
    }

    const populated = await Conversation.findById(conversation._id)
      .populate('participants', PARTICIPANT_FIELDS)
      .lean();
    const [presented] = await this.present([populated], userId);
    return presented;
  }

  public async listUserConversations(userId: string) {
    const conversations = await Conversation.find({ participants: userId })
      .populate('participants', PARTICIPANT_FIELDS)
      .sort({ lastMessageAt: -1 })
      .lean();
    return this.present(conversations, userId);
  }

  public async getConversation(conversationId: string, userId: string) {
    await this.assertParticipant(conversationId, userId);
    const conversation = await Conversation.findById(conversationId)
      .populate('participants', PARTICIPANT_FIELDS)
      .lean();
    const [presented] = await this.present([conversation], userId);
    return presented;
  }

  public async getMessages(conversationId: string, userId: string) {
    await this.assertParticipant(conversationId, userId);
    return Message.find({ conversationId })
      .populate('senderId', 'fullName profilePicture role')
      .sort({ createdAt: 1 });
  }

  /** Marks every message received by [userId] in the conversation as read. */
  public async markRead(conversationId: string, userId: string) {
    const conversation = await this.assertParticipant(conversationId, userId);
    const result = await Message.updateMany(
      { conversationId, senderId: { $ne: userId }, isRead: false },
      { isRead: true }
    );
    if (result.modifiedCount > 0) {
      const other = conversation.participants.find((p) => p.toString() !== userId);
      if (other) {
        wsManager.broadcastToUser(other.toString(), 'conversation:read', { conversationId, readerId: userId });
      }
    }
    return { updated: result.modifiedCount };
  }

  public async unreadCount(userId: string): Promise<number> {
    const conversations = await Conversation.find({ participants: userId }).select('_id').lean();
    if (conversations.length === 0) return 0;
    return Message.countDocuments({
      conversationId: { $in: conversations.map((c) => c._id) },
      senderId: { $ne: userId },
      isRead: false,
    });
  }

  public async sendMessage(conversationId: string, senderId: string, input: SendMessageInput) {
    const conversation = await this.assertParticipant(conversationId, senderId);

    const message = await Message.create({
      conversationId,
      senderId,
      text: input.text,
      isRead: false,
    });

    conversation.lastMessage = input.text;
    conversation.lastMessageAt = new Date();
    conversation.lastSenderId = new mongoose.Types.ObjectId(senderId);
    await conversation.save();

    const populated = await message.populate('senderId', 'fullName profilePicture role');

    // Real-time broadcast via WebSocket to room and other participant
    wsManager.broadcastToRoom(`conversation:${conversationId}`, 'message:received', populated);

    const otherParticipant = conversation.participants.find((p) => p.toString() !== senderId);
    if (otherParticipant) {
      wsManager.broadcastToUser(otherParticipant.toString(), 'message:notification', {
        conversationId,
        message: populated,
      });
      const senderName = (populated.senderId as any)?.fullName ?? 'Nouveau message';
      await notificationService.notify(otherParticipant, {
        type: 'message:new',
        title: senderName,
        body: input.text.length > 120 ? `${input.text.slice(0, 117)}...` : input.text,
        data: { conversationId },
      });
    }

    return populated;
  }
}

export const chatService = new ChatService();
