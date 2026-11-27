import '../../../../../core/errors/result.dart';
import '../models/admin_artisan.dart';

abstract class AdminArtisansRepository {
  Future<Result<AdminArtisansPage>> listArtisans({
    String status = 'all',
    String? query,
    int page = 1,
    int limit = 10,
  });

  Future<Result<AdminArtisan>> getArtisanById(String id);

  Future<Result<AdminArtisan>> verifyArtisan(String id);

  Future<Result<AdminArtisan>> rejectArtisan(String id, String reason);
}
