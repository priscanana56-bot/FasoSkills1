import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/ws_client.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/service_request.dart';
import '../../domain/repositories/request_repository.dart';

class RequestDetailState extends Equatable {
  final bool loading;
  final ServiceRequest? request;
  final List<Quote> quotes;
  final String? error;

  /// True while an action (accept, quote, complete...) is running.
  final bool busy;

  /// One-shot feedback for a snackbar.
  final String? message;
  final bool messageIsError;

  const RequestDetailState({
    this.loading = true,
    this.request,
    this.quotes = const [],
    this.error,
    this.busy = false,
    this.message,
    this.messageIsError = false,
  });

  RequestDetailState copyWith({
    bool? loading,
    ServiceRequest? request,
    List<Quote>? quotes,
    String? error,
    bool? busy,
    String? message,
    bool messageIsError = false,
  }) =>
      RequestDetailState(
        loading: loading ?? this.loading,
        request: request ?? this.request,
        quotes: quotes ?? this.quotes,
        error: error,
        busy: busy ?? this.busy,
        message: message,
        messageIsError: messageIsError,
      );

  @override
  List<Object?> get props =>
      [loading, request, quotes, error, busy, message, messageIsError];
}

/// One service request seen by its client (quotes, accept, complete, review)
/// or by an artisan (send / withdraw a quote, report completion).
class RequestDetailCubit extends Cubit<RequestDetailState> {
  final RequestRepository _repository;
  final String requestId;
  final bool isClient;
  StreamSubscription? _wsSub;

  RequestDetailCubit({
    required RequestRepository repository,
    required WebSocketClient wsClient,
    required this.requestId,
    required this.isClient,
  })  : _repository = repository,
        super(const RequestDetailState()) {
    // Refresh when something changes on this request (new quote, status...).
    _wsSub = wsClient.eventStream.listen((event) {
      final name = event['event']?.toString() ?? '';
      if (!(name.startsWith('quote:') || name.startsWith('request:'))) return;
      final data = event['data'];
      final ids = <String>{
        if (data is Map) data['requestId']?.toString() ?? '',
        if (data is Map) data['_id']?.toString() ?? '',
      };
      if (ids.contains(requestId)) load(silent: true);
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true));
    final result = await _repository.getRequestById(requestId);
    final request = result.dataOrNull;
    if (request == null) {
      emit(
          state.copyWith(loading: false, error: result.failureOrNull?.message));
      return;
    }
    var quotes = state.quotes;
    if (isClient) {
      final q = await _repository.getQuotesForRequest(requestId);
      quotes = q.dataOrNull ?? quotes;
    }
    emit(state.copyWith(loading: false, request: request, quotes: quotes));
  }

  Future<bool> _run(
      Future<Result<dynamic>> Function() action, String success) async {
    emit(state.copyWith(busy: true));
    final result = await action();
    if (result.isFailure) {
      emit(state.copyWith(
          busy: false,
          message: result.failureOrNull!.message,
          messageIsError: true));
      return false;
    }
    await load(silent: true);
    emit(state.copyWith(busy: false, message: success));
    return true;
  }

  // Client actions
  Future<bool> acceptQuote(Quote q) => _run(() => _repository.acceptQuote(q.id),
      'Devis accepté. La mission commence !');
  Future<bool> rejectQuote(Quote q) =>
      _run(() => _repository.rejectQuote(q.id), 'Devis refusé');
  Future<bool> cancel() =>
      _run(() => _repository.cancelRequest(requestId), 'Demande annulée');
  Future<bool> review(int rating, String comment) => _run(
        () => _repository.submitReview(
            requestId: requestId, rating: rating, comment: comment),
        'Merci pour votre avis !',
      );

  // Shared
  Future<bool> markCompleted() => _run(
      () => _repository.markCompleted(requestId),
      'Mission marquée comme terminée');

  // Artisan actions
  Future<bool> submitQuote(
          {required double amount, required int days, String? message}) =>
      _run(
        () => _repository.submitQuote(
            requestId: requestId,
            amount: amount,
            estimatedDays: days,
            message: message),
        'Devis envoyé au client',
      );
  Future<bool> withdrawQuote(Quote q) =>
      _run(() => _repository.withdrawQuote(q.id), 'Devis retiré');

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
