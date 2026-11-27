import '../../../../core/errors/result.dart';
import '../models/app_notification.dart';

class NotificationPage {
  final List<AppNotification> items;
  final int unreadCount;
  const NotificationPage(this.items, this.unreadCount);
}

abstract class NotificationRepository {
  Future<Result<NotificationPage>> getNotifications();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
}
