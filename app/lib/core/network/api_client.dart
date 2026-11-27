import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/failure.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final http.Client _client;
  final SecureStorageService _storage;
  final String _baseUrl;

  // Concurrency-safe token refresh (Exigence F6 & Question typique de soutenance)
  Completer<bool>? _refreshCompleter;

  ApiClient({
    http.Client? client,
    SecureStorageService? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(
      (headers) => _client.get(
        _buildUri(endpoint, queryParams),
        headers: headers,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(
      (headers) => _client.post(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(
      (headers) => _client.put(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(
      (headers) => _client.patch(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendRequest(
      (headers) => _client.delete(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$_baseUrl$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> _sendRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFn, {
    required bool requiresAuth,
    bool isRetry = false,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth);
      final response =
          await requestFn(headers).timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 401 && requiresAuth && !isRetry) {
        // Concurrency-safe token refresh handling (F6)
        final refreshed = await _handleTokenRefresh();
        if (refreshed) {
          // Retry the request once with freshly built headers carrying the new access token
          return await _sendRequest(requestFn,
              requiresAuth: requiresAuth, isRetry: true);
        } else {
          throw const AuthFailure('Session expirée, veuillez vous reconnecter');
        }
      }

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw NetworkFailure('Problème de connexion réseau: ${e.message}');
    } on TimeoutException {
      throw const NetworkFailure('Délai d’attente dépassé (timeout)');
    } on Failure {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw const NetworkFailure();
      }
      throw ServerFailure('Une erreur inattendue est survenue: $e');
    }
  }

  /// Concurrency-safe refresh: if 3 requests fail with 401 simultaneously,
  /// only 1 performs the refresh API call, and the others await its result.
  Future<bool> _handleTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        await _storage.clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final res = await _client.post(
        _buildUri('/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        _refreshCompleter!.complete(true);
        return true;
      } else {
        await _storage.clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }
    } catch (_) {
      await _storage.clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
    }

    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final errorMessage = jsonBody?['error']?['message'] ?? 'Erreur serveur';
    final errorCode = jsonBody?['error']?['code'];
    final errorDetails = jsonBody?['error']?['details'];

    switch (response.statusCode) {
      case 400:
        throw ServerFailure(errorMessage, code: errorCode, statusCode: 400);
      case 401:
        throw AuthFailure(errorMessage);
      case 403:
        throw ForbiddenFailure(errorMessage);
      case 404:
        throw ServerFailure(errorMessage, code: 'NOT_FOUND', statusCode: 404);
      case 409:
        throw ServerFailure(errorMessage, code: 'CONFLICT', statusCode: 409);
      case 422:
        throw ValidationFailure(
          errorMessage,
          errors: errorDetails is List ? errorDetails : null,
        );
      default:
        throw ServerFailure(errorMessage,
            code: errorCode, statusCode: response.statusCode);
    }
  }
}
