import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryImpl({ApiClient? apiClient})
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
  Future<Result<NotificationPage>> getNotifications() => _guard(() async {
        final res = await _apiClient
            .get('/notifications', queryParams: {'limit': '50'});
        final items = ((res['data'] ?? []) as List)
            .map((e) => AppNotification.fromJson(e))
            .toList();
        return NotificationPage(items, readInt(res['unreadCount']));
      });

  @override
  Future<Result<void>> markRead(String id) => _guard(() async {
        await _apiClient.patch('/notifications/$id/read');
      });

  @override
  Future<Result<void>> markAllRead() => _guard(() async {
        await _apiClient.post('/notifications/read-all');
      });
}
