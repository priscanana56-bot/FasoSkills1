import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/cache_service.dart';
import '../../domain/models/artisan.dart';
import '../../domain/models/artisan_stats.dart';
import '../../domain/repositories/artisan_repository.dart';

class ArtisanRepositoryImpl implements ArtisanRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  ArtisanRepositoryImpl({
    ApiClient? apiClient,
    CacheService? cacheService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _cacheService = cacheService ?? CacheService();

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final res = await _apiClient.get('/categories', requiresAuth: false);
      final List rawList = res['data'] ?? [];
      final categories = rawList.map((e) => Category.fromJson(e)).toList();
      await _cacheService.saveJson(CacheService.keyCategories, rawList);
      return Success(categories);
    } on Failure catch (f) {
      // Try local cache fallback
      final cached = await _cacheService.getJson(CacheService.keyCategories);
      if (cached != null && cached is List) {
        return Success(cached.map((e) => Category.fromJson(e)).toList());
      }
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Artisan>>> getArtisans({
    int page = 1,
    int limit = 10,
    String? search,
    String? city,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      final res = await _apiClient.get(
        '/artisans',
        queryParams: queryParams,
        requiresAuth: false,
      );

      final List rawList = res['data'] ?? [];
      final artisans = rawList.map((e) => Artisan.fromJson(e)).toList();

      // Cache the main list (Requirement F9 - Cache then network)
      if (page == 1 && (search == null || search.isEmpty)) {
        await _cacheService.saveJson(CacheService.keyArtisanList, rawList);
      }

      return Success(artisans);
    } on Failure catch (f) {
      // If network fails on first page, try offline cache
      if (page == 1) {
        final cached = await getCachedArtisans();
        if (cached != null && cached.isNotEmpty) {
          return Success(cached);
        }
      }
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Artisan>?> getCachedArtisans() async {
    final cached = await _cacheService.getJson(CacheService.keyArtisanList);
    if (cached != null && cached is List) {
      return cached.map((e) => Artisan.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<Result<Artisan>> getArtisanById(String id) async {
    try {
      final res = await _apiClient.get('/artisans/$id', requiresAuth: false);
      return Success(Artisan.fromJson(res['data']));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

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
  Future<Result<List<ArtisanReview>>> getReviews(String artisanId) =>
      _guard(() async {
        final res = await _apiClient.get('/reviews/artisan/$artisanId',
            requiresAuth: false);
        return ((res['data'] ?? []) as List)
            .map((e) => ArtisanReview.fromJson(e))
            .toList();
      });

  @override
  Future<Result<Artisan>> getMyProfile() => _guard(() async {
        final res = await _apiClient.get('/artisans/me');
        return Artisan.fromJson(res['data']);
      });

  @override
  Future<Result<Artisan>> updateMyProfile({
    String? specialty,
    String? city,
    String? categoryId,
    int? experienceYears,
    String? bio,
    String? availability,
  }) =>
      _guard(() async {
        final res = await _apiClient.put('/artisans/me', body: {
          if (specialty != null) 'specialty': specialty,
          if (city != null) 'city': city,
          if (categoryId != null) 'categoryId': categoryId,
          if (experienceYears != null) 'experienceYears': experienceYears,
          if (bio != null) 'bio': bio,
          if (availability != null) 'availability': availability,
        });
        return Artisan.fromJson(res['data']);
      });

  @override
  Future<Result<ArtisanStats>> getMyStats() => _guard(() async {
        final res = await _apiClient.get('/artisans/me/stats');
        return ArtisanStats.fromJson(res['data']);
      });
}
