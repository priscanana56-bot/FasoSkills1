import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../artisans/domain/models/admin_artisan.dart';
import '../../../artisans/domain/repositories/admin_artisans_repository.dart';
import '../../../categories/domain/models/admin_category.dart';
import '../../../categories/domain/repositories/admin_categories_repository.dart';
import '../../domain/models/admin_stats.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminDashboardEvent {
  final bool forceRefresh;
  const LoadAdminDashboard({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class QuickVerifyArtisan extends AdminDashboardEvent {
  final String artisanId;
  const QuickVerifyArtisan(this.artisanId);

  @override
  List<Object?> get props => [artisanId];
}

class QuickRejectArtisan extends AdminDashboardEvent {
  final String artisanId;
  final String reason;
  const QuickRejectArtisan(this.artisanId, this.reason);

  @override
  List<Object?> get props => [artisanId, reason];
}

// ── States (F7) ─────────────────────────────────────────────────────────────

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardEmpty extends AdminDashboardState {
  const AdminDashboardEmpty();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminStats stats;
  final List<AdminArtisan> pendingArtisans;
  final List<AdminCategory> categories;
  final bool isFromCache;
  final String? notificationMessage;
  final bool notificationIsError;

  const AdminDashboardLoaded({
    required this.stats,
    this.pendingArtisans = const [],
    this.categories = const [],
    this.isFromCache = false,
    this.notificationMessage,
    this.notificationIsError = false,
  });

  AdminDashboardLoaded copyWith({
    AdminStats? stats,
    List<AdminArtisan>? pendingArtisans,
    List<AdminCategory>? categories,
    bool? isFromCache,
    String? notificationMessage,
    bool clearNotification = false,
    bool? notificationIsError,
  }) {
    return AdminDashboardLoaded(
      stats: stats ?? this.stats,
      pendingArtisans: pendingArtisans ?? this.pendingArtisans,
      categories: categories ?? this.categories,
      isFromCache: isFromCache ?? this.isFromCache,
      notificationMessage: clearNotification
          ? null
          : (notificationMessage ?? this.notificationMessage),
      notificationIsError: notificationIsError ?? this.notificationIsError,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        pendingArtisans,
        categories,
        isFromCache,
        notificationMessage,
        notificationIsError,
      ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC (F9: Cache-then-network) ───────────────────────────────────────────

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminDashboardRepository _dashboardRepository;
  final AdminArtisansRepository _artisansRepository;
  final AdminCategoriesRepository _categoriesRepository;

  AdminDashboardBloc({
    required AdminDashboardRepository dashboardRepository,
    required AdminArtisansRepository artisansRepository,
    required AdminCategoriesRepository categoriesRepository,
  })  : _dashboardRepository = dashboardRepository,
        _artisansRepository = artisansRepository,
        _categoriesRepository = categoriesRepository,
        super(AdminDashboardInitial()) {
    on<LoadAdminDashboard>(_onLoad);
    on<QuickVerifyArtisan>(_onQuickVerify);
    on<QuickRejectArtisan>(_onQuickReject);
  }

  Future<void> _onLoad(
    LoadAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // 1. Cache-then-network (F9): display cached stats immediately if available
    AdminStats? cachedStats;
    if (!event.forceRefresh) {
      cachedStats = await _dashboardRepository.getCachedStats();
      if (cachedStats != null) {
        emit(AdminDashboardLoaded(stats: cachedStats, isFromCache: true));
      } else {
        emit(AdminDashboardLoading());
      }
    } else if (state is! AdminDashboardLoaded) {
      emit(AdminDashboardLoading());
    }

    // 2. Network refresh in parallel
    final statsResult = await _dashboardRepository.getStats();
    final pendingResult = await _artisansRepository.listArtisans(
      status: 'pending',
      page: 1,
      limit: 5,
    );
    final categoriesResult = await _categoriesRepository.listCategories();

    final pendingList =
        pendingResult.dataOrNull?.items ?? const <AdminArtisan>[];
    final categoryList = categoriesResult.dataOrNull ?? const <AdminCategory>[];

    statsResult.when(
      success: (stats) {
        final isCompletelyEmpty = stats.users.total == 0 &&
            stats.artisans.total == 0 &&
            stats.requests.total == 0 &&
            stats.categories.total == 0;
        if (isCompletelyEmpty) {
          emit(const AdminDashboardEmpty());
        } else {
          emit(
            AdminDashboardLoaded(
              stats: stats,
              pendingArtisans: pendingList,
              categories: categoryList,
              isFromCache: false,
            ),
          );
        }
      },
      failure: (failure) {
        if (cachedStats != null) {
          emit(
            AdminDashboardLoaded(
              stats: cachedStats,
              pendingArtisans: pendingList,
              categories: categoryList,
              isFromCache: true,
              notificationMessage: 'Mode hors-ligne : ${failure.message}',
              notificationIsError: true,
            ),
          );
        } else {
          emit(AdminDashboardError(failure.message));
        }
      },
    );
  }

  Future<void> _onQuickVerify(
    QuickVerifyArtisan event,
    Emitter<AdminDashboardState> emit,
  ) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;

    final previousPending = current.pendingArtisans;
    final previousStats = current.stats;

    final updatedPending =
        previousPending.where((a) => a.id != event.artisanId).toList();
    final updatedArtisanStats = ArtisanStats(
      total: previousStats.artisans.total,
      verified: previousStats.artisans.verified + 1,
      pending: (previousStats.artisans.pending - 1).clamp(0, 1 << 30),
      rejected: previousStats.artisans.rejected,
    );

    // Optimistic update
    emit(
      current.copyWith(
        pendingArtisans: updatedPending,
        stats: AdminStats(
          users: previousStats.users,
          artisans: updatedArtisanStats,
          requests: previousStats.requests,
          quotes: previousStats.quotes,
          categories: previousStats.categories,
          reports: previousStats.reports,
          charts: previousStats.charts,
        ),
        notificationMessage: 'Validation en cours...',
        notificationIsError: false,
      ),
    );

    final result = await _artisansRepository.verifyArtisan(event.artisanId);
    result.when(
      success: (_) {
        final latest = state;
        if (latest is AdminDashboardLoaded) {
          emit(
            latest.copyWith(
              notificationMessage: 'Artisan vérifié avec succès',
              notificationIsError: false,
            ),
          );
        }
      },
      failure: (failure) {
        // Rollback on failure
        emit(
          current.copyWith(
            pendingArtisans: previousPending,
            stats: previousStats,
            notificationMessage: 'Échec de la validation : ${failure.message}',
            notificationIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onQuickReject(
    QuickRejectArtisan event,
    Emitter<AdminDashboardState> emit,
  ) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;

    final previousPending = current.pendingArtisans;
    final previousStats = current.stats;

    final updatedPending =
        previousPending.where((a) => a.id != event.artisanId).toList();
    final updatedArtisanStats = ArtisanStats(
      total: previousStats.artisans.total,
      verified: previousStats.artisans.verified,
      pending: (previousStats.artisans.pending - 1).clamp(0, 1 << 30),
      rejected: previousStats.artisans.rejected + 1,
    );

    // Optimistic update
    emit(
      current.copyWith(
        pendingArtisans: updatedPending,
        stats: AdminStats(
          users: previousStats.users,
          artisans: updatedArtisanStats,
          requests: previousStats.requests,
          quotes: previousStats.quotes,
          categories: previousStats.categories,
          reports: previousStats.reports,
          charts: previousStats.charts,
        ),
        notificationMessage: 'Refus en cours...',
        notificationIsError: false,
      ),
    );

    final result =
        await _artisansRepository.rejectArtisan(event.artisanId, event.reason);
    result.when(
      success: (_) {
        final latest = state;
        if (latest is AdminDashboardLoaded) {
          emit(
            latest.copyWith(
              notificationMessage: 'Dossier artisan refusé',
              notificationIsError: false,
            ),
          );
        }
      },
      failure: (failure) {
        // Rollback on failure
        emit(
          current.copyWith(
            pendingArtisans: previousPending,
            stats: previousStats,
            notificationMessage: 'Échec du refus : ${failure.message}',
            notificationIsError: true,
          ),
        );
      },
    );
  }
}
