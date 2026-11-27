import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../domain/models/admin_artisan.dart';
import '../../domain/repositories/admin_artisans_repository.dart';

// F8: Debounced search transformer + droppable pagination transformer
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

// ── Events ──────────────────────────────────────────────────────────────────

abstract class AdminArtisansEvent extends Equatable {
  const AdminArtisansEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminArtisans extends AdminArtisansEvent {
  final String statusFilter; // 'pending' | 'verified' | 'all'
  final String query;

  const LoadAdminArtisans({
    this.statusFilter = 'all',
    this.query = '',
  });

  @override
  List<Object?> get props => [statusFilter, query];
}

class SearchAdminArtisans extends AdminArtisansEvent {
  final String query;
  final String statusFilter;

  const SearchAdminArtisans(this.query, {this.statusFilter = 'all'});

  @override
  List<Object?> get props => [query, statusFilter];
}

class LoadMoreAdminArtisans extends AdminArtisansEvent {
  const LoadMoreAdminArtisans();
}

class LoadAdminArtisanDetail extends AdminArtisansEvent {
  final String artisanId;
  const LoadAdminArtisanDetail(this.artisanId);

  @override
  List<Object?> get props => [artisanId];
}

class VerifyAdminArtisanOptimistic extends AdminArtisansEvent {
  final String artisanId;
  const VerifyAdminArtisanOptimistic(this.artisanId);

  @override
  List<Object?> get props => [artisanId];
}

class RejectAdminArtisanOptimistic extends AdminArtisansEvent {
  final String artisanId;
  final String reason;
  const RejectAdminArtisanOptimistic(this.artisanId, this.reason);

  @override
  List<Object?> get props => [artisanId, reason];
}

// ── States (F7) ─────────────────────────────────────────────────────────────

abstract class AdminArtisansState extends Equatable {
  const AdminArtisansState();

  @override
  List<Object?> get props => [];
}

class AdminArtisansInitial extends AdminArtisansState {}

class AdminArtisansLoading extends AdminArtisansState {
  final String statusFilter;
  final String searchQuery;

  const AdminArtisansLoading({
    this.statusFilter = 'all',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [statusFilter, searchQuery];
}

class AdminArtisansEmpty extends AdminArtisansState {
  final String statusFilter;
  final String searchQuery;

  const AdminArtisansEmpty({
    this.statusFilter = 'all',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [statusFilter, searchQuery];
}

class AdminArtisansError extends AdminArtisansState {
  final String message;
  final String statusFilter;
  final String searchQuery;

  const AdminArtisansError(
    this.message, {
    this.statusFilter = 'all',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [message, statusFilter, searchQuery];
}

class AdminArtisansLoaded extends AdminArtisansState {
  final List<AdminArtisan> artisans;
  final AdminPagination pagination;
  final String statusFilter;
  final String searchQuery;
  final bool isLoadingMore;
  final AdminArtisan? selectedArtisan;
  final bool isDetailLoading;
  final String? detailError;
  final String? actionMessage;
  final bool actionIsError;

  const AdminArtisansLoaded({
    required this.artisans,
    this.pagination = const AdminPagination(),
    this.statusFilter = 'all',
    this.searchQuery = '',
    this.isLoadingMore = false,
    this.selectedArtisan,
    this.isDetailLoading = false,
    this.detailError,
    this.actionMessage,
    this.actionIsError = false,
  });

  AdminArtisansLoaded copyWith({
    List<AdminArtisan>? artisans,
    AdminPagination? pagination,
    String? statusFilter,
    String? searchQuery,
    bool? isLoadingMore,
    AdminArtisan? selectedArtisan,
    bool? isDetailLoading,
    String? detailError,
    bool clearDetailError = false,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? actionIsError,
  }) {
    return AdminArtisansLoaded(
      artisans: artisans ?? this.artisans,
      pagination: pagination ?? this.pagination,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedArtisan: selectedArtisan ?? this.selectedArtisan,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      actionIsError: actionIsError ?? this.actionIsError,
    );
  }

  @override
  List<Object?> get props => [
        artisans,
        pagination,
        statusFilter,
        searchQuery,
        isLoadingMore,
        selectedArtisan,
        isDetailLoading,
        detailError,
        actionMessage,
        actionIsError,
      ];
}

// ── BLoC (F8: Debounced search, droppable pagination, optimistic + rollback) ──

class AdminArtisansBloc extends Bloc<AdminArtisansEvent, AdminArtisansState> {
  final AdminArtisansRepository _repository;
  static const int _pageSize = 10;

  AdminArtisansBloc({required AdminArtisansRepository repository})
      : _repository = repository,
        super(AdminArtisansInitial()) {
    on<LoadAdminArtisans>(_onLoad);
    on<SearchAdminArtisans>(
      _onSearch,
      transformer: debounceRestartable(const Duration(milliseconds: 300)),
    );
    on<LoadMoreAdminArtisans>(
      _onLoadMore,
      transformer: droppable(),
    );
    on<LoadAdminArtisanDetail>(_onLoadDetail);
    on<VerifyAdminArtisanOptimistic>(_onVerifyOptimistic);
    on<RejectAdminArtisanOptimistic>(_onRejectOptimistic);
  }

  Future<void> _fetchFirstPage({
    required String statusFilter,
    required String query,
    required Emitter<AdminArtisansState> emit,
    AdminArtisan? preserveSelected,
  }) async {
    emit(AdminArtisansLoading(statusFilter: statusFilter, searchQuery: query));

    final result = await _repository.listArtisans(
      status: statusFilter,
      query: query,
      page: 1,
      limit: _pageSize,
    );

    result.when(
      success: (page) {
        if (page.items.isEmpty) {
          emit(AdminArtisansEmpty(
              statusFilter: statusFilter, searchQuery: query));
        } else {
          emit(
            AdminArtisansLoaded(
              artisans: page.items,
              pagination: page.pagination,
              statusFilter: statusFilter,
              searchQuery: query,
              selectedArtisan: preserveSelected,
            ),
          );
        }
      },
      failure: (failure) {
        emit(
          AdminArtisansError(
            failure.message,
            statusFilter: statusFilter,
            searchQuery: query,
          ),
        );
      },
    );
  }

  Future<void> _onLoad(
    LoadAdminArtisans event,
    Emitter<AdminArtisansState> emit,
  ) async {
    final current = state;
    final selected =
        current is AdminArtisansLoaded ? current.selectedArtisan : null;
    await _fetchFirstPage(
      statusFilter: event.statusFilter,
      query: event.query,
      emit: emit,
      preserveSelected: selected,
    );
  }

  Future<void> _onSearch(
    SearchAdminArtisans event,
    Emitter<AdminArtisansState> emit,
  ) async {
    await _fetchFirstPage(
      statusFilter: event.statusFilter,
      query: event.query,
      emit: emit,
    );
  }

  Future<void> _onLoadMore(
    LoadMoreAdminArtisans event,
    Emitter<AdminArtisansState> emit,
  ) async {
    final current = state;
    if (current is! AdminArtisansLoaded) return;
    if (!current.pagination.hasNextPage || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true, clearActionMessage: true));

    final nextPage = current.pagination.page + 1;
    final result = await _repository.listArtisans(
      status: current.statusFilter,
      query: current.searchQuery,
      page: nextPage,
      limit: _pageSize,
    );

    result.when(
      success: (page) {
        final merged = [...current.artisans, ...page.items];
        emit(
          current.copyWith(
            artisans: merged,
            pagination: page.pagination,
            isLoadingMore: false,
          ),
        );
      },
      failure: (failure) {
        emit(
          current.copyWith(
            isLoadingMore: false,
            actionMessage: failure.message,
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoadDetail(
    LoadAdminArtisanDetail event,
    Emitter<AdminArtisansState> emit,
  ) async {
    final current = state;
    if (current is AdminArtisansLoaded) {
      AdminArtisan? existing;
      for (final a in current.artisans) {
        if (a.id == event.artisanId) {
          existing = a;
          break;
        }
      }
      emit(
        current.copyWith(
          selectedArtisan: existing,
          isDetailLoading: true,
          clearDetailError: true,
          clearActionMessage: true,
        ),
      );
    }

    final result = await _repository.getArtisanById(event.artisanId);
    final latest = state;

    result.when(
      success: (artisan) {
        if (latest is AdminArtisansLoaded) {
          emit(
            latest.copyWith(
              selectedArtisan: artisan,
              isDetailLoading: false,
              clearDetailError: true,
            ),
          );
        } else {
          emit(
            AdminArtisansLoaded(
              artisans: [artisan],
              pagination: const AdminPagination(total: 1),
              selectedArtisan: artisan,
              isDetailLoading: false,
            ),
          );
        }
      },
      failure: (failure) {
        if (latest is AdminArtisansLoaded) {
          emit(
            latest.copyWith(
              isDetailLoading: false,
              detailError: failure.message,
            ),
          );
        } else {
          emit(AdminArtisansError(failure.message));
        }
      },
    );
  }

  Future<void> _onVerifyOptimistic(
    VerifyAdminArtisanOptimistic event,
    Emitter<AdminArtisansState> emit,
  ) async {
    final current = state;
    if (current is! AdminArtisansLoaded) return;

    final previousArtisans = current.artisans;
    final previousSelected = current.selectedArtisan;

    final optimisticList = previousArtisans.map((artisan) {
      if (artisan.id == event.artisanId) {
        return artisan.copyWith(
          isVerified: true,
          verificationStatus: 'verified',
        );
      }
      return artisan;
    }).toList();

    final optimisticSelected =
        previousSelected != null && previousSelected.id == event.artisanId
            ? previousSelected.copyWith(
                isVerified: true,
                verificationStatus: 'verified',
              )
            : previousSelected;

    // 1. Optimistic emission
    emit(
      current.copyWith(
        artisans: optimisticList,
        selectedArtisan: optimisticSelected,
        actionMessage: 'Attribution du badge en cours...',
        actionIsError: false,
      ),
    );

    // 2. Network call
    final result = await _repository.verifyArtisan(event.artisanId);

    result.when(
      success: (verifiedArtisan) {
        final syncedList = optimisticList.map((a) {
          return a.id == verifiedArtisan.id ? verifiedArtisan : a;
        }).toList();
        emit(
          current.copyWith(
            artisans: syncedList,
            selectedArtisan: optimisticSelected?.id == verifiedArtisan.id
                ? verifiedArtisan
                : optimisticSelected,
            actionMessage: 'Badge Vérifié attribué avec succès',
            actionIsError: false,
          ),
        );
      },
      failure: (failure) {
        // 3. Rollback on failure (F8)
        emit(
          current.copyWith(
            artisans: previousArtisans,
            selectedArtisan: previousSelected,
            actionMessage: 'Échec de la vérification : ${failure.message}',
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onRejectOptimistic(
    RejectAdminArtisanOptimistic event,
    Emitter<AdminArtisansState> emit,
  ) async {
    final current = state;
    if (current is! AdminArtisansLoaded) return;

    final previousArtisans = current.artisans;
    final previousSelected = current.selectedArtisan;

    final optimisticList = previousArtisans.map((artisan) {
      if (artisan.id == event.artisanId) {
        return artisan.copyWith(
          isVerified: false,
          verificationStatus: 'rejected',
          rejectionReason: event.reason,
        );
      }
      return artisan;
    }).toList();

    final optimisticSelected =
        previousSelected != null && previousSelected.id == event.artisanId
            ? previousSelected.copyWith(
                isVerified: false,
                verificationStatus: 'rejected',
                rejectionReason: event.reason,
              )
            : previousSelected;

    // 1. Optimistic emission
    emit(
      current.copyWith(
        artisans: optimisticList,
        selectedArtisan: optimisticSelected,
        actionMessage: 'Refus du dossier en cours...',
        actionIsError: false,
      ),
    );

    // 2. Network call
    final result =
        await _repository.rejectArtisan(event.artisanId, event.reason);

    result.when(
      success: (rejectedArtisan) {
        final syncedList = optimisticList.map((a) {
          return a.id == rejectedArtisan.id ? rejectedArtisan : a;
        }).toList();
        emit(
          current.copyWith(
            artisans: syncedList,
            selectedArtisan: optimisticSelected?.id == rejectedArtisan.id
                ? rejectedArtisan
                : optimisticSelected,
            actionMessage: 'Dossier refusé avec motif enregistré',
            actionIsError: false,
          ),
        );
      },
      failure: (failure) {
        // 3. Rollback on failure (F8)
        emit(
          current.copyWith(
            artisans: previousArtisans,
            selectedArtisan: previousSelected,
            actionMessage: 'Échec du refus : ${failure.message}',
            actionIsError: true,
          ),
        );
      },
    );
  }
}
