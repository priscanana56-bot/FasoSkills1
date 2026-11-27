import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/ws_client.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendMessageSubmitted extends ChatEvent {
  final String conversationId;
  final String text;
  final String senderId;
  const SendMessageSubmitted(
      {required this.conversationId, required this.text, this.senderId = ''});
  @override
  List<Object?> get props => [conversationId, text, senderId];
}

class MessageReceivedFromWs extends ChatEvent {
  final ChatMessage message;
  const MessageReceivedFromWs(this.message);
  @override
  List<Object?> get props => [message];
}

class LeaveConversation extends ChatEvent {}

// States
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String conversationId;

  /// Ids of optimistic messages still being sent / that failed to send.
  final Set<String> pendingIds;
  final Set<String> failedIds;
  final ChatMessage? lastSent;

  const ChatLoaded({
    required this.messages,
    required this.conversationId,
    this.pendingIds = const {},
    this.failedIds = const {},
    this.lastSent,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    Set<String>? pendingIds,
    Set<String>? failedIds,
    ChatMessage? lastSent,
  }) =>
      ChatLoaded(
        messages: messages ?? this.messages,
        conversationId: conversationId,
        pendingIds: pendingIds ?? this.pendingIds,
        failedIds: failedIds ?? this.failedIds,
        lastSent: lastSent ?? this.lastSent,
      );

  @override
  List<Object?> get props =>
      [messages, conversationId, pendingIds, failedIds, lastSent];
}

class ChatError extends ChatState {
  final String message;
  final String? conversationId;
  const ChatError(this.message, {this.conversationId});
  @override
  List<Object?> get props => [message, conversationId];
}

/// Messages of the conversation open on screen. One instance per chat screen.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final WebSocketClient _wsClient;
  StreamSubscription? _wsSubscription;
  String? _room;

  ChatBloc(
      {required ChatRepository repository, required WebSocketClient wsClient})
      : _repository = repository,
        _wsClient = wsClient,
        super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageSubmitted>(_onSendMessageSubmitted);
    on<MessageReceivedFromWs>(_onMessageReceivedFromWs);
    on<LeaveConversation>(_onLeave);

    _wsSubscription = _wsClient.on('message:received').listen((event) {
      final data = event['data'];
      if (data is Map) {
        add(MessageReceivedFromWs(
            ChatMessage.fromJson(Map<String, dynamic>.from(data))));
      }
    });
  }

  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded ||
        (state as ChatLoaded).conversationId != event.conversationId) {
      emit(ChatLoading());
    }
    _room = 'conversation:${event.conversationId}';
    _wsClient.joinRoom(_room!);

    final result = await _repository.getMessages(event.conversationId);
    result.when(
      success: (messages) => emit(
          ChatLoaded(messages: messages, conversationId: event.conversationId)),
      failure: (failure) => emit(
          ChatError(failure.message, conversationId: event.conversationId)),
    );
    if (result.isSuccess) await _repository.markRead(event.conversationId);
  }

  Future<void> _onSendMessageSubmitted(
      SendMessageSubmitted event, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoaded) return;
    final text = event.text.trim();
    if (text.isEmpty) return;

    // Optimistic bubble shown immediately, replaced by the server copy.
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final temp = ChatMessage(
      id: tempId,
      conversationId: event.conversationId,
      senderId: event.senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    emit(current.copyWith(
        messages: [...current.messages, temp],
        pendingIds: {...current.pendingIds, tempId}));

    final result = await _repository.sendMessage(
        conversationId: event.conversationId, text: text);
    final now = state;
    if (now is! ChatLoaded) return;
    result.when(
      success: (sent) {
        // The WS echo may already have added it: avoid duplicates.
        final alreadyThere = now.messages.any((m) => m.id == sent.id);
        final messages = now.messages
            .where((m) => !(alreadyThere && m.id == tempId))
            .map((m) => m.id == tempId ? sent : m)
            .toList();
        emit(now.copyWith(
          messages: messages,
          pendingIds: {...now.pendingIds}..remove(tempId),
          lastSent: sent,
        ));
      },
      failure: (_) => emit(now.copyWith(
        pendingIds: {...now.pendingIds}..remove(tempId),
        failedIds: {...now.failedIds, tempId},
      )),
    );
  }

  void _onMessageReceivedFromWs(
      MessageReceivedFromWs event, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded ||
        current.conversationId != event.message.conversationId) {
      return;
    }
    if (current.messages.any((m) => m.id == event.message.id)) return;
    // Replace a matching optimistic bubble from me, if any.
    final pendingIndex = current.messages.indexWhere(
      (m) =>
          current.pendingIds.contains(m.id) &&
          m.text == event.message.text &&
          m.senderId == event.message.senderId,
    );
    if (pendingIndex >= 0) {
      final messages = [...current.messages];
      final tempId = messages[pendingIndex].id;
      messages[pendingIndex] = event.message;
      emit(current.copyWith(
          messages: messages,
          pendingIds: {...current.pendingIds}..remove(tempId)));
      return;
    }
    emit(current.copyWith(messages: [...current.messages, event.message]));
    _repository.markRead(current.conversationId);
  }

  void _onLeave(LeaveConversation event, Emitter<ChatState> emit) {
    if (_room != null) _wsClient.leaveRoom(_room!);
    _room = null;
  }

  @override
  Future<void> close() {
    if (_room != null) _wsClient.leaveRoom(_room!);
    _wsSubscription?.cancel();
    return super.close();
  }
}
