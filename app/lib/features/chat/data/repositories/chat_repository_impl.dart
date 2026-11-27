import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;

  ChatRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ChatConversation>> startOrGetConversation({
    required String recipientId,
    String? initialMessage,
    String? requestId,
  }) =>
      _guard(() async {
        final res = await _apiClient.post('/chat/conversations', body: {
          'recipientId': recipientId,
          if (initialMessage != null && initialMessage.trim().isNotEmpty)
            'initialMessage': initialMessage.trim(),
          if (requestId != null) 'requestId': requestId,
        });
        return ChatConversation.fromJson(res['data']);
      });

  @override
  Future<Result<List<ChatConversation>>> getConversations() => _guard(() async {
        final res = await _apiClient.get('/chat/conversations');
        final List list = res['data'] ?? [];
        return list.map((e) => ChatConversation.fromJson(e)).toList();
      });

  @override
  Future<Result<ChatConversation>> getConversation(String conversationId) =>
      _guard(() async {
        final res = await _apiClient.get('/chat/conversations/$conversationId');
        return ChatConversation.fromJson(res['data']);
      });

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) =>
      _guard(() async {
        final res = await _apiClient
            .get('/chat/conversations/$conversationId/messages');
        final List list = res['data'] ?? [];
        return list.map((e) => ChatMessage.fromJson(e)).toList();
      });

  @override
  Future<Result<ChatMessage>> sendMessage(
          {required String conversationId, required String text}) =>
      _guard(() async {
        final res = await _apiClient.post(
            '/chat/conversations/$conversationId/messages',
            body: {'text': text});
        return ChatMessage.fromJson(res['data']);
      });

  @override
  Future<Result<void>> markRead(String conversationId) => _guard(() async {
        await _apiClient.post('/chat/conversations/$conversationId/read');
      });
}
