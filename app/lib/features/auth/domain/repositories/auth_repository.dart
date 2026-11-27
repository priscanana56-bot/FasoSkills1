import '../../../../core/errors/result.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});
  Future<Result<User>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
    String? specialty,
    String? city,
    String? categoryId,
  });
  Future<Result<void>> logout();
  Future<Result<User>> getCurrentUser();
  Future<bool> hasValidToken();
  Future<Result<User>> updateProfile(
      {String? fullName, String? phone, String? profilePicture});
  Future<Result<void>> changePassword(
      {required String currentPassword, required String newPassword});
}
