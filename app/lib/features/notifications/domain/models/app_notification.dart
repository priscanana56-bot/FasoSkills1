import 'package:equatable/equatable.dart';
import '../../../../core/utils/json_utils.dart';

class AppNotification extends Equatable {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  String? get requestId => data['requestId']?.toString();
  String? get conversationId => data['conversationId']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: readId(json),
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        data: asMap(json['data']) ?? const {},
        isRead: json['isRead'] ?? false,
        createdAt: readDate(json['createdAt']),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, type, title, body, isRead, createdAt];
}
