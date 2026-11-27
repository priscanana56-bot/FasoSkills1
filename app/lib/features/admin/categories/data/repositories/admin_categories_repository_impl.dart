import '../../../../../core/errors/failure.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/models/admin_category.dart';
import '../../domain/repositories/admin_categories_repository.dart';

class AdminCategoriesRepositoryImpl implements AdminCategoriesRepository {
  final ApiClient _apiClient;

  AdminCategoriesRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<List<AdminCategory>>> listCategories() async {
    try {
      final res = await _apiClient.get('/admin/categories');
      final List<dynamic> list = (res['data'] as List?) ?? [];
      return Success(
        list
            .whereType<Map<String, dynamic>>()
            .map(AdminCategory.fromJson)
            .toList(),
      );
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AdminCategory>> createCategory({
    required String name,
    String? icon,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'isActive': isActive,
      };
      if (icon != null && icon.trim().isNotEmpty) body['icon'] = icon.trim();
      if (description != null && description.trim().isNotEmpty) {
        body['description'] = description.trim();
      }

      final res = await _apiClient.post('/categories', body: body);
      return Success(
          AdminCategory.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AdminCategory>> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? description,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (description != null) body['description'] = description;
      if (isActive != null) body['isActive'] = isActive;

      final res = await _apiClient.patch('/categories/$id', body: body);
      return Success(
          AdminCategory.fromJson(res['data'] as Map<String, dynamic>));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    try {
      await _apiClient.delete('/categories/$id');
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
