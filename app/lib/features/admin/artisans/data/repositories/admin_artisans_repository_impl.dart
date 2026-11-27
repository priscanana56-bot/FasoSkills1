import '../../../../../core/errors/failure.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/models/admin_artisan.dart';
import '../../domain/repositories/admin_artisans_repository.dart';

class AdminArtisansRepositoryImpl implements AdminArtisansRepository {
  final ApiClient _apiClient;

  AdminArtisansRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<AdminArtisansPage>> listArtisans({
    String status = 'all',
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final params = <String, String>{
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (query != null && query.trim().isNotEmpty) {
        params['q'] = query.trim();
      }

      final res = await _apiClient.get('/admin/artisans', queryParams: params);
      final List<dynamic> rawList = (res['data'] as List?) ?? [];
      final paginationJson =
          (res['pagination'] as Map<String, dynamic>?) ?? const {};

      return Success(
        AdminArtisansPage(
          items: rawList
              .whereType<Map<String, dynamic>>()
              .map(AdminArtisan.fromJson)
              .toList(),
          pagination: AdminPagination.fromJson(paginationJson),
        ),
      );
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AdminArtisan>> getArtisanById(String id) async {
    try {
      final res = await _apiClient.get('/admin/artisans/$id');
      return Success(
          AdminArtisan.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AdminArtisan>> verifyArtisan(String id) async {
    try {
      final res = await _apiClient.post('/artisans/$id/verify');
      return Success(
          AdminArtisan.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AdminArtisan>> rejectArtisan(String id, String reason) async {
    try {
      final res = await _apiClient.post(
        '/admin/artisans/$id/reject',
        body: {'reason': reason},
      );
      return Success(
          AdminArtisan.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
