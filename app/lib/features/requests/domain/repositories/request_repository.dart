import '../../../../core/errors/result.dart';
import '../models/service_request.dart';
import '../models/quote.dart';

abstract class RequestRepository {
  // ── Client ────────────────────────────────────────────────────────────────
  Future<Result<List<ServiceRequest>>> getMyRequests();
  Future<Result<ServiceRequest>> createRequest({
    required String title,
    required String description,
    required String categoryId,
    required String city,
    String? address,
    List<String>? photos,
  });
  Future<Result<ServiceRequest>> cancelRequest(String requestId);
  Future<Result<List<Quote>>> getQuotesForRequest(String requestId);
  Future<Result<Quote>> acceptQuote(String quoteId);
  Future<Result<Quote>> rejectQuote(String quoteId);
  Future<Result<void>> submitReview(
      {required String requestId, required int rating, String? comment});

  // ── Shared ────────────────────────────────────────────────────────────────
  Future<Result<ServiceRequest>> getRequestById(String requestId);

  /// Client confirms, or assigned artisan reports, that the job is done.
  Future<Result<ServiceRequest>> markCompleted(String requestId);

  // ── Artisan ───────────────────────────────────────────────────────────────
  /// Pending requests the artisan can quote on (their category by default).
  Future<Result<List<ServiceRequest>>> getOpenRequests(
      {bool allCategories = false, String? search});

  /// Requests where the artisan's quote was accepted.
  Future<Result<List<ServiceRequest>>> getMissions();
  Future<Result<List<Quote>>> getMyQuotes();
  Future<Result<Quote>> submitQuote({
    required String requestId,
    required double amount,
    required int estimatedDays,
    String? message,
  });
  Future<Result<void>> withdrawQuote(String quoteId);
}
