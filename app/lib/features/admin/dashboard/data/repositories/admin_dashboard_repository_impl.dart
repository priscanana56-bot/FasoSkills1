import '../../../../../core/errors/failure.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/cache_service.dart';
import '../../domain/models/admin_stats.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  AdminDashboardRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<Result<AdminStats>> getStats() async {
    try {
      final res = await _apiClient.get('/admin/stats');
      final data = res['data'] as Map<String, dynamic>;
      await _cacheService.saveJson(CacheService.keyAdminStats, data);
      return Success(AdminStats.fromJson(data));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<AdminStats?> getCachedStats() async {
    try {
      final cached = await _cacheService.getJson(CacheService.keyAdminStats);
      if (cached is Map<String, dynamic>) {
        return AdminStats.fromJson(cached);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
