import '../../../../../core/errors/failure.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/network/api_client.dart';
import '../../../artisans/domain/models/admin_artisan.dart';
import '../../domain/models/admin_report.dart';
import '../../domain/repositories/moderation_repository.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final ApiClient _apiClient;

  ModerationRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<AdminReportsPage>> listReports({
    String? type,
    String? status,
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final res = await _apiClient.get('/admin/reports', queryParams: params);
      final List<dynamic> rawList = (res['data'] as List?) ?? [];
      final paginationJson =
          (res['pagination'] as Map<String, dynamic>?) ?? const {};

      return Success(
        AdminReportsPage(
          items: rawList
              .whereType<Map<String, dynamic>>()
              .map(AdminReport.fromJson)
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
  Future<Result<AdminReport>> dismissReport(
    String reportId, {
    String? resolutionNote,
  }) async {
    try {
      final body = <String, dynamic>{'status': 'dismissed'};
      if (resolutionNote != null && resolutionNote.trim().isNotEmpty) {
        body['resolutionNote'] = resolutionNote.trim();
      }
      final res =
          await _apiClient.patch('/admin/reports/$reportId', body: body);
      return Success(AdminReport.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteContent({
    required String type,
    required String targetId,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        body['reason'] = reason.trim();
      }
      await _apiClient.delete(
        '/admin/content/$type/$targetId',
        body: body.isEmpty ? null : body,
      );
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ModerationLogEntry>>> listModerationLogs({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _apiClient.get(
        '/admin/moderation-logs',
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final List<dynamic> list = (res['data'] as List?) ?? [];
      return Success(
        list
            .whereType<Map<String, dynamic>>()
            .map(ModerationLogEntry.fromJson)
            .toList(),
      );
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
