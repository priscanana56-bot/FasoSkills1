import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/ws_client.dart';
import '../../../artisans/domain/models/artisan.dart';
import '../../../artisans/domain/models/artisan_stats.dart';
import '../../../artisans/domain/repositories/artisan_repository.dart';
import '../../../requests/domain/models/quote.dart';
import '../../../requests/domain/models/service_request.dart';
import '../../../requests/domain/repositories/request_repository.dart';

class ArtisanWorkState extends Equatable {
  final bool loading;
  final Artisan? profile;
  final ArtisanStats stats;
  final List<ServiceRequest> openRequests;
  final List<ServiceRequest> missions;
  final List<Quote> quotes;
  final bool allCategories;
  final String? error;

  const ArtisanWorkState({
    this.loading = false,
    this.profile,
    this.stats = const ArtisanStats(),
    this.openRequests = const [],
    this.missions = const [],
    this.quotes = const [],
    this.allCategories = false,
    this.error,
  });

  List<ServiceRequest> get activeMissions =>
      missions.where((m) => m.isActive).toList();
  List<ServiceRequest> get completedMissions =>
      missions.where((m) => m.isCompleted).toList();
  List<Quote> get pendingQuotes => quotes.where((q) => q.isPending).toList();

  ArtisanWorkState copyWith({
    bool? loading,
    Artisan? profile,
    ArtisanStats? stats,
    List<ServiceRequest>? openRequests,
    List<ServiceRequest>? missions,
    List<Quote>? quotes,
    bool? allCategories,
    String? error,
  }) =>
      ArtisanWorkState(
        loading: loading ?? this.loading,
        profile: profile ?? this.profile,
        stats: stats ?? this.stats,
        openRequests: openRequests ?? this.openRequests,
        missions: missions ?? this.missions,
        quotes: quotes ?? this.quotes,
        allCategories: allCategories ?? this.allCategories,
        error: error,
      );

  @override
  List<Object?> get props => [
        loading,
        profile,
        stats,
        openRequests,
        missions,
        quotes,
        allCategories,
        error
      ];
}

/// Everything the artisan space shows: profile, counters, open requests, missions and quotes.
class ArtisanWorkCubit extends Cubit<ArtisanWorkState> {
  final RequestRepository _requests;
  final ArtisanRepository _artisans;
  StreamSubscription? _wsSub;
  Timer? _debounce;

  ArtisanWorkCubit({
    required RequestRepository requestRepository,
    required ArtisanRepository artisanRepository,
    required WebSocketClient wsClient,
  })  : _requests = requestRepository,
        _artisans = artisanRepository,
        super(const ArtisanWorkState()) {
    _wsSub = wsClient.eventStream.listen((event) {
      final name = event['event']?.toString() ?? '';
      if (name == 'request:created' ||
          name == 'request:updated' ||
          name.startsWith('quote:') ||
          name == 'artisan:verified' ||
          name == 'artisan:rejected') {
        // Several events can arrive together (e.g. accept → rejected others): refresh once.
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), () => refresh());
      }
    });
  }

  Future<void> loadAll() async {
    emit(state.copyWith(loading: state.profile == null));
    await refresh();
  }

  Future<void> refresh() async {
    final results = await Future.wait([
      _artisans.getMyProfile(),
      _artisans.getMyStats(),
      _requests.getOpenRequests(allCategories: state.allCategories),
      _requests.getMissions(),
      _requests.getMyQuotes(),
    ]);
    if (isClosed) return;
    final failure =
        results.map((r) => r.failureOrNull).whereType<Object>().firstOrNull;
    emit(state.copyWith(
      loading: false,
      profile: results[0].dataOrNull as Artisan?,
      stats: results[1].dataOrNull as ArtisanStats?,
      openRequests: results[2].dataOrNull as List<ServiceRequest>?,
      missions: results[3].dataOrNull as List<ServiceRequest>?,
      quotes: results[4].dataOrNull as List<Quote>?,
      error: failure != null
          ? (results.firstWhere((r) => r.isFailure).failureOrNull!.message)
          : null,
    ));
  }

  Future<void> toggleAllCategories(bool value) async {
    emit(state.copyWith(allCategories: value));
    final result = await _requests.getOpenRequests(allCategories: value);
    emit(state.copyWith(
        openRequests: result.dataOrNull ?? state.openRequests,
        error: result.failureOrNull?.message));
  }

  Future<String?> updateProfile({
    String? specialty,
    String? city,
    String? categoryId,
    int? experienceYears,
    String? bio,
    String? availability,
  }) async {
    final result = await _artisans.updateMyProfile(
      specialty: specialty,
      city: city,
      categoryId: categoryId,
      experienceYears: experienceYears,
      bio: bio,
      availability: availability,
    );
    if (result.isFailure) return result.failureOrNull!.message;
    emit(state.copyWith(profile: result.dataOrNull));
    await refresh();
    return null;
  }

  void reset() => emit(const ArtisanWorkState());

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _debounce?.cancel();
    return super.close();
  }
}
