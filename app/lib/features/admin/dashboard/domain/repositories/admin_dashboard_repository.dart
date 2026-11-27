import '../../../../../core/errors/result.dart';
import '../models/admin_stats.dart';

abstract class AdminDashboardRepository {
  Future<Result<AdminStats>> getStats();
  Future<AdminStats?> getCachedStats();
}
