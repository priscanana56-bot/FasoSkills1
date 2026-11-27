import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/service_request.dart';
import '../../domain/models/quote.dart';
import '../../domain/repositories/request_repository.dart';

class RequestRepositoryImpl implements RequestRepository {
  final ApiClient _apiClient;

  RequestRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on Failure catch (f) {
      return FailureResult(f);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  List<ServiceRequest> _requests(dynamic res) => ((res['data'] ?? []) as List)
      .map((e) => ServiceRequest.fromJson(e))
      .toList();

  @override
  Future<Result<List<ServiceRequest>>> getMyRequests() => _guard(() async {
        // The API always scopes a client's list to their own requests.
        final res =
            await _apiClient.get('/requests', queryParams: {'limit': '50'});
        return _requests(res);
      });

  @override
  Future<Result<ServiceRequest>> createRequest({
    required String title,
    required String description,
    required String categoryId,
    required String city,
    String? address,
    List<String>? photos,
  }) =>
      _guard(() async {
        final res = await _apiClient.post('/requests', body: {
          'title': title,
          'description': description,
          'categoryId': categoryId,
          'city': city,
          if (address != null && address.isNotEmpty) 'address': address,
          'photos': photos ?? [],
        });
        return ServiceRequest.fromJson(res['data']);
      });

  @override
  Future<Result<ServiceRequest>> cancelRequest(String requestId) =>
      _guard(() async {
        final res = await _apiClient.delete('/requests/$requestId');
        return ServiceRequest.fromJson(res['data']);
      });

  @override
  Future<Result<List<Quote>>> getQuotesForRequest(String requestId) =>
      _guard(() async {
        final res = await _apiClient
            .get('/quotes/request/$requestId', queryParams: {'limit': '50'});
        return ((res['data'] ?? []) as List)
            .map((e) => Quote.fromJson(e))
            .toList();
      });

  @override
  Future<Result<Quote>> acceptQuote(String quoteId) => _guard(() async {
        final res = await _apiClient.post('/quotes/$quoteId/accept');
        return Quote.fromJson(res['data']);
      });

  @override
  Future<Result<Quote>> rejectQuote(String quoteId) => _guard(() async {
        final res = await _apiClient.post('/quotes/$quoteId/reject');
        return Quote.fromJson(res['data']);
      });

  @override
  Future<Result<void>> submitReview(
          {required String requestId, required int rating, String? comment}) =>
      _guard(() async {
        await _apiClient.post('/reviews', body: {
          'requestId': requestId,
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        });
      });

  @override
  Future<Result<ServiceRequest>> getRequestById(String requestId) =>
      _guard(() async {
        final res = await _apiClient.get('/requests/$requestId');
        return ServiceRequest.fromJson(res['data']);
      });

  @override
  Future<Result<ServiceRequest>> markCompleted(String requestId) =>
      _guard(() async {
        final res = await _apiClient
            .put('/requests/$requestId', body: {'status': 'completed'});
        return ServiceRequest.fromJson(res['data']);
      });

  @override
  Future<Result<List<ServiceRequest>>> getOpenRequests(
          {bool allCategories = false, String? search}) =>
      _guard(() async {
        final res = await _apiClient.get('/requests', queryParams: {
          'scope': 'open',
          'limit': '50',
          if (allCategories) 'allCategories': 'true',
          if (search != null && search.isNotEmpty) 'search': search,
        });
        return _requests(res);
      });

  @override
  Future<Result<List<ServiceRequest>>> getMissions() => _guard(() async {
        final res = await _apiClient.get('/requests',
            queryParams: {'scope': 'missions', 'limit': '50'});
        return _requests(res);
      });

  @override
  Future<Result<List<Quote>>> getMyQuotes() => _guard(() async {
        final res =
            await _apiClient.get('/quotes/mine', queryParams: {'limit': '50'});
        return ((res['data'] ?? []) as List)
            .map((e) => Quote.fromJson(e))
            .toList();
      });

  @override
  Future<Result<Quote>> submitQuote({
    required String requestId,
    required double amount,
    required int estimatedDays,
    String? message,
  }) =>
      _guard(() async {
        final res = await _apiClient.post('/quotes', body: {
          'requestId': requestId,
          'amount': amount,
          'estimatedDays': estimatedDays,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        });
        return Quote.fromJson(res['data']);
      });

  @override
  Future<Result<void>> withdrawQuote(String quoteId) => _guard(() async {
        await _apiClient.delete('/quotes/$quoteId');
      });
}
