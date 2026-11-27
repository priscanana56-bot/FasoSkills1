import '../../../../core/errors/result.dart';
import '../models/message.dart';

abstract class ChatRepository {
  /// Opens (or reuses) the single conversation between the current user and [recipientId] (a user id).
  Future<Result<ChatConversation>> startOrGetConversation({
    required String recipientId,
    String? initialMessage,
    String? requestId,
  });
  Future<Result<List<ChatConversation>>> getConversations();
  Future<Result<ChatConversation>> getConversation(String conversationId);
  Future<Result<List<ChatMessage>>> getMessages(String conversationId);
  Future<Result<ChatMessage>> sendMessage({
    required String conversationId,
    required String text,
  });
  Future<Result<void>> markRead(String conversationId);
}
