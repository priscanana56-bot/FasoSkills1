import '../../../../../core/errors/result.dart';
import '../models/admin_category.dart';

abstract class AdminCategoriesRepository {
  Future<Result<List<AdminCategory>>> listCategories();

  Future<Result<AdminCategory>> createCategory({
    required String name,
    String? icon,
    String? description,
    bool isActive = true,
  });

  Future<Result<AdminCategory>> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? description,
    bool? isActive,
  });

  Future<Result<void>> deleteCategory(String id);
}
