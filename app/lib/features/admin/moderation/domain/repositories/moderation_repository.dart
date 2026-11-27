import '../../../../../core/errors/result.dart';
import '../models/admin_report.dart';

abstract class ModerationRepository {
  Future<Result<AdminReportsPage>> listReports({
    String? type,
    String? status,
    int page = 1,
    int limit = 15,
  });

  Future<Result<AdminReport>> dismissReport(
    String reportId, {
    String? resolutionNote,
  });

  Future<Result<void>> deleteContent({
    required String type,
    required String targetId,
    String? reason,
  });

  Future<Result<List<ModerationLogEntry>>> listModerationLogs({
    int page = 1,
    int limit = 20,
  });
}
