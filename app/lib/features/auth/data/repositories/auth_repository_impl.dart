import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepositoryImpl({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<Result<User>> login(
      {required String email, required String password}) async {
    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      final data = res['data'];
      await _storage.saveTokens(
        accessToken: data['tokens']['accessToken'],
        refreshToken: data['tokens']['refreshToken'],
      );

      final user = User.fromJson(data['user']);
      return Success(user);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
    String? specialty,
    String? city,
    String? categoryId,
  }) async {
    try {
      final res = await _apiClient.post(
        '/auth/register',
        // Optional fields are omitted when empty: the API rejects null/blank values.
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (specialty != null && specialty.trim().isNotEmpty)
            'specialty': specialty.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
        },
        requiresAuth: false,
      );

      final data = res['data'];
      await _storage.saveTokens(
        accessToken: data['tokens']['accessToken'],
        refreshToken: data['tokens']['refreshToken'],
      );

      final user = User.fromJson(data['user']);
      return Success(user);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
          requiresAuth: false,
        );
      }
      await _storage.clearTokens();
      return const Success(null);
    } catch (_) {
      await _storage.clearTokens();
      return const Success(null);
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final res = await _apiClient.get('/auth/me');
      final user = User.fromJson(res['data']['user']);
      return Success(user);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Result<User>> updateProfile(
      {String? fullName, String? phone, String? profilePicture}) async {
    try {
      final res = await _apiClient.patch('/auth/me', body: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (profilePicture != null) 'profilePicture': profilePicture,
      });
      return Success(User.fromJson(res['data']['user']));
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      await _apiClient.post('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return const Success(null);
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
