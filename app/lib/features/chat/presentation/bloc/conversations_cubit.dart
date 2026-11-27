import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/ws_client.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

enum ConversationsStatus { initial, loading, loaded, error }

class ConversationsState extends Equatable {
  final ConversationsStatus status;
  final List<ChatConversation> conversations;
  final String? error;

  const ConversationsState({
    this.status = ConversationsStatus.initial,
    this.conversations = const [],
    this.error,
  });

  int get totalUnread => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<ChatConversation>? conversations,
    String? error,
  }) =>
      ConversationsState(
        status: status ?? this.status,
        conversations: conversations ?? this.conversations,
        error: error,
      );

  @override
  List<Object?> get props => [status, conversations, error];
}

/// The current user's conversations. Each conversation already knows who the
/// *other* participant is, so a client only sees artisans and vice versa.
class ConversationsCubit extends Cubit<ConversationsState> {
  final ChatRepository _repository;
  final WebSocketClient _ws;
  StreamSubscription? _wsSub;

  /// Conversation currently open on screen: incoming messages there are not counted as unread.
  String? _openConversationId;

  ConversationsCubit(
      {required ChatRepository repository, required WebSocketClient wsClient})
      : _repository = repository,
        _ws = wsClient,
        super(const ConversationsState()) {
    _wsSub = _ws.on('message:notification').listen(_onIncoming);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || state.status == ConversationsStatus.initial) {
      emit(state.copyWith(status: ConversationsStatus.loading));
    }
    final result = await _repository.getConversations();
    result.when(
      success: (list) => emit(state.copyWith(
          status: ConversationsStatus.loaded, conversations: list)),
      failure: (f) => emit(state.copyWith(
        status: state.conversations.isEmpty
            ? ConversationsStatus.error
            : ConversationsStatus.loaded,
        error: f.message,
      )),
    );
  }

  void _onIncoming(Map<String, dynamic> event) {
    final data = event['data'];
    if (data is! Map) return;
    final conversationId = data['conversationId']?.toString();
    final message = data['message'] is Map
        ? ChatMessage.fromJson(Map<String, dynamic>.from(data['message']))
        : null;
    final index = state.conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0 || message == null) {
      load(silent: true); // new conversation started by the other side
      return;
    }
    final current = state.conversations[index];
    final updated = current.copyWith(
      lastMessage: message.text,
      lastSenderId: message.senderId,
      lastMessageAt: message.createdAt ?? DateTime.now(),
      unreadCount:
          conversationId == _openConversationId ? 0 : current.unreadCount + 1,
    );
    final list = [...state.conversations]..removeAt(index);
    emit(state.copyWith(conversations: [updated, ...list]));
  }

  /// Called by the chat screen when it opens/closes a conversation.
  void setOpenConversation(String? conversationId) {
    _openConversationId = conversationId;
    if (conversationId != null) markReadLocally(conversationId);
  }

  void markReadLocally(String conversationId) {
    emit(state.copyWith(
      conversations: state.conversations
          .map((c) => c.id == conversationId ? c.copyWith(unreadCount: 0) : c)
          .toList(),
    ));
  }

  /// Keeps the list in sync after the current user sends a message.
  void onMessageSent(ChatMessage message) {
    final index =
        state.conversations.indexWhere((c) => c.id == message.conversationId);
    if (index < 0) {
      load(silent: true);
      return;
    }
    final updated = state.conversations[index].copyWith(
      lastMessage: message.text,
      lastSenderId: message.senderId,
      lastMessageAt: message.createdAt ?? DateTime.now(),
    );
    final list = [...state.conversations]..removeAt(index);
    emit(state.copyWith(conversations: [updated, ...list]));
  }

  /// Opens (or reuses) the conversation with another user and returns its id.
  Future<String?> startWith(String recipientUserId,
      {String? initialMessage, String? requestId}) async {
    final result = await _repository.startOrGetConversation(
      recipientId: recipientUserId,
      initialMessage: initialMessage,
      requestId: requestId,
    );
    return result.when(
      success: (conversation) {
        final others =
            state.conversations.where((c) => c.id != conversation.id).toList();
        emit(state.copyWith(
            status: ConversationsStatus.loaded,
            conversations: [conversation, ...others]));
        return conversation.id;
      },
      failure: (f) {
        emit(state.copyWith(error: f.message));
        return null;
      },
    );
  }

  ChatConversation? byId(String id) {
    for (final c in state.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  void reset() => emit(const ConversationsState());

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
