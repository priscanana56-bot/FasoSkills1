import '../../../../core/errors/result.dart';
import '../models/artisan.dart';
import '../models/artisan_stats.dart';

abstract class ArtisanRepository {
  Future<Result<List<Category>>> getCategories();
  Future<Result<List<Artisan>>> getArtisans({
    int page = 1,
    int limit = 10,
    String? search,
    String? city,
    String? categoryId,
  });
  Future<Result<Artisan>> getArtisanById(String id);
  Future<List<Artisan>?> getCachedArtisans();
  Future<Result<List<ArtisanReview>>> getReviews(String artisanId);

  // ── Logged-in artisan ─────────────────────────────────────────────────────
  Future<Result<Artisan>> getMyProfile();
  Future<Result<Artisan>> updateMyProfile({
    String? specialty,
    String? city,
    String? categoryId,
    int? experienceYears,
    String? bio,
    String? availability,
  });
  Future<Result<ArtisanStats>> getMyStats();
}
