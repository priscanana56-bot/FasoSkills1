import 'package:equatable/equatable.dart';
import '../../../../core/utils/json_utils.dart';

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String text;
  final bool isRead;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.text,
    this.isRead = false,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = asMap(json['senderId']);
    return ChatMessage(
      id: readId(json),
      conversationId: readId(json['conversationId']),
      senderId: readId(json['senderId']),
      senderName: sender?['fullName'],
      text: json['text'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: readDate(json['createdAt']),
    );
  }

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, conversationId, senderId, text, isRead, createdAt];
}

/// The person on the other side of a conversation, seen from the current user.
class ChatPeer extends Equatable {
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final String? profilePicture;
  final String? artisanProfileId;
  final String? specialty;
  final String? city;
  final bool isVerified;

  const ChatPeer({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.profilePicture,
    this.artisanProfileId,
    this.specialty,
    this.city,
    this.isVerified = false,
  });

  bool get isArtisan => role == 'artisan';

  /// Short line under the name: the trade for an artisan, "Client" otherwise.
  String get subtitle {
    if (isArtisan) {
      final parts = [
        if ((specialty ?? '').isNotEmpty) specialty!,
        if ((city ?? '').isNotEmpty) city!
      ];
      return parts.isEmpty ? 'Artisan' : parts.join(' • ');
    }
    return role == 'admin' ? 'Équipe FasoSkills' : 'Client';
  }

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    final profile = asMap(json['artisanProfile']);
    return ChatPeer(
      id: readId(json),
      fullName: json['fullName'] ?? 'Utilisateur',
      role: json['role'] ?? 'client',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      artisanProfileId: profile != null ? readId(profile) : null,
      specialty: profile?['specialty'],
      city: profile?['city'],
      isVerified: profile?['isVerified'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, fullName, role, artisanProfileId];
}

class ChatConversation extends Equatable {
  final String id;
  final ChatPeer? peer;
  final String lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? requestId;

  const ChatConversation({
    required this.id,
    this.peer,
    this.lastMessage = '',
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.requestId,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final other = asMap(json['otherParticipant']);
    return ChatConversation(
      id: readId(json),
      peer: other != null ? ChatPeer.fromJson(other) : null,
      lastMessage: json['lastMessage'] ?? '',
      lastSenderId:
          json['lastSenderId'] != null ? readId(json['lastSenderId']) : null,
      lastMessageAt: readDate(json['lastMessageAt']),
      unreadCount: readInt(json['unreadCount']),
      requestId: json['requestId'] != null ? readId(json['requestId']) : null,
    );
  }

  ChatConversation copyWith(
          {String? lastMessage,
          String? lastSenderId,
          DateTime? lastMessageAt,
          int? unreadCount}) =>
      ChatConversation(
        id: id,
        peer: peer,
        lastMessage: lastMessage ?? this.lastMessage,
        lastSenderId: lastSenderId ?? this.lastSenderId,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        requestId: requestId,
      );

  @override
  List<Object?> get props => [
        id,
        peer,
        lastMessage,
        lastSenderId,
        lastMessageAt,
        unreadCount,
        requestId
      ];
}
