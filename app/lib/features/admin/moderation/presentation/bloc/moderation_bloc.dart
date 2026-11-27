import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import '../../../artisans/domain/models/admin_artisan.dart';
import '../../domain/models/admin_report.dart';
import '../../domain/repositories/moderation_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class ModerationEvent extends Equatable {
  const ModerationEvent();

  @override
  List<Object?> get props => [];
}

class LoadReports extends ModerationEvent {
  final String targetType; // 'request' | 'review' | 'message'
  final String statusFilter; // 'pending' | 'all'

  const LoadReports({
    this.targetType = 'request',
    this.statusFilter = 'pending',
  });

  @override
  List<Object?> get props => [targetType, statusFilter];
}

class LoadMoreReports extends ModerationEvent {
  const LoadMoreReports();
}

class DismissReportRequested extends ModerationEvent {
  final String reportId;
  final String? resolutionNote;

  const DismissReportRequested(this.reportId, {this.resolutionNote});

  @override
  List<Object?> get props => [reportId, resolutionNote];
}

class DeleteReportedContentRequested extends ModerationEvent {
  final String reportId;
  final String targetType;
  final String targetId;
  final String? reason;

  const DeleteReportedContentRequested({
    required this.reportId,
    required this.targetType,
    required this.targetId,
    this.reason,
  });

  @override
  List<Object?> get props => [reportId, targetType, targetId, reason];
}

class LoadModerationLogs extends ModerationEvent {
  const LoadModerationLogs();
}

// ── States (F7) ─────────────────────────────────────────────────────────────

abstract class ModerationState extends Equatable {
  const ModerationState();

  @override
  List<Object?> get props => [];
}

class ModerationInitial extends ModerationState {}

class ModerationLoading extends ModerationState {
  final String targetType;
  final String statusFilter;

  const ModerationLoading({
    this.targetType = 'request',
    this.statusFilter = 'pending',
  });

  @override
  List<Object?> get props => [targetType, statusFilter];
}

class ModerationEmpty extends ModerationState {
  final String targetType;
  final String statusFilter;

  const ModerationEmpty({
    this.targetType = 'request',
    this.statusFilter = 'pending',
  });

  @override
  List<Object?> get props => [targetType, statusFilter];
}

class ModerationError extends ModerationState {
  final String message;
  final String targetType;
  final String statusFilter;

  const ModerationError(
    this.message, {
    this.targetType = 'request',
    this.statusFilter = 'pending',
  });

  @override
  List<Object?> get props => [message, targetType, statusFilter];
}

class ModerationLoaded extends ModerationState {
  final List<AdminReport> reports;
  final AdminPagination pagination;
  final String targetType;
  final String statusFilter;
  final bool isLoadingMore;
  final List<ModerationLogEntry> logs;
  final bool isLoadingLogs;
  final String? actionMessage;
  final bool actionIsError;

  const ModerationLoaded({
    required this.reports,
    this.pagination = const AdminPagination(),
    this.targetType = 'request',
    this.statusFilter = 'pending',
    this.isLoadingMore = false,
    this.logs = const [],
    this.isLoadingLogs = false,
    this.actionMessage,
    this.actionIsError = false,
  });

  ModerationLoaded copyWith({
    List<AdminReport>? reports,
    AdminPagination? pagination,
    String? targetType,
    String? statusFilter,
    bool? isLoadingMore,
    List<ModerationLogEntry>? logs,
    bool? isLoadingLogs,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? actionIsError,
  }) {
    return ModerationLoaded(
      reports: reports ?? this.reports,
      pagination: pagination ?? this.pagination,
      targetType: targetType ?? this.targetType,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      logs: logs ?? this.logs,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      actionIsError: actionIsError ?? this.actionIsError,
    );
  }

  @override
  List<Object?> get props => [
        reports,
        pagination,
        targetType,
        statusFilter,
        isLoadingMore,
        logs,
        isLoadingLogs,
        actionMessage,
        actionIsError,
      ];
}

// ── BLoC ────────────────────────────────────────────────────────────────────

class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  final ModerationRepository _repository;
  static const int _pageSize = 15;

  ModerationBloc({required ModerationRepository repository})
      : _repository = repository,
        super(ModerationInitial()) {
    on<LoadReports>(_onLoad);
    on<LoadMoreReports>(_onLoadMore, transformer: droppable());
    on<DismissReportRequested>(_onDismiss);
    on<DeleteReportedContentRequested>(_onDeleteContent);
    on<LoadModerationLogs>(_onLoadLogs);
  }

  Future<void> _onLoad(
    LoadReports event,
    Emitter<ModerationState> emit,
  ) async {
    emit(
      ModerationLoading(
        targetType: event.targetType,
        statusFilter: event.statusFilter,
      ),
    );

    final result = await _repository.listReports(
      type: event.targetType,
      status: event.statusFilter,
      page: 1,
      limit: _pageSize,
    );

    result.when(
      success: (page) {
        if (page.items.isEmpty) {
          emit(
            ModerationEmpty(
              targetType: event.targetType,
              statusFilter: event.statusFilter,
            ),
          );
        } else {
          emit(
            ModerationLoaded(
              reports: page.items,
              pagination: page.pagination,
              targetType: event.targetType,
              statusFilter: event.statusFilter,
            ),
          );
        }
      },
      failure: (failure) {
        emit(
          ModerationError(
            failure.message,
            targetType: event.targetType,
            statusFilter: event.statusFilter,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreReports event,
    Emitter<ModerationState> emit,
  ) async {
    final current = state;
    if (current is! ModerationLoaded) return;
    if (!current.pagination.hasNextPage || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true, clearActionMessage: true));

    final result = await _repository.listReports(
      type: current.targetType,
      status: current.statusFilter,
      page: current.pagination.page + 1,
      limit: _pageSize,
    );

    result.when(
      success: (page) {
        emit(
          current.copyWith(
            reports: [...current.reports, ...page.items],
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

  Future<void> _onDismiss(
    DismissReportRequested event,
    Emitter<ModerationState> emit,
  ) async {
    final current = state;
    if (current is! ModerationLoaded) return;

    final result = await _repository.dismissReport(
      event.reportId,
      resolutionNote: event.resolutionNote,
    );

    result.when(
      success: (updatedReport) {
        final updatedList = current.statusFilter == 'pending'
            ? current.reports.where((r) => r.id != event.reportId).toList()
            : current.reports
                .map((r) => r.id == event.reportId ? updatedReport : r)
                .toList();
        if (updatedList.isEmpty) {
          emit(
            ModerationEmpty(
              targetType: current.targetType,
              statusFilter: current.statusFilter,
            ),
          );
        } else {
          emit(
            current.copyWith(
              reports: updatedList,
              actionMessage: 'Signalement ignoré',
              actionIsError: false,
            ),
          );
        }
      },
      failure: (failure) {
        emit(
          current.copyWith(
            actionMessage: 'Erreur : ${failure.message}',
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteContent(
    DeleteReportedContentRequested event,
    Emitter<ModerationState> emit,
  ) async {
    final current = state;
    if (current is! ModerationLoaded) return;

    final result = await _repository.deleteContent(
      type: event.targetType,
      targetId: event.targetId,
      reason: event.reason,
    );

    result.when(
      success: (_) {
        final remaining = current.statusFilter == 'pending'
            ? current.reports
                .where((r) => r.targetId != event.targetId)
                .toList()
            : current.reports.map((r) {
                if (r.targetId == event.targetId) {
                  return r.copyWith(
                    status: 'action_taken',
                    resolutionNote: event.reason,
                  );
                }
                return r;
              }).toList();

        if (remaining.isEmpty) {
          emit(
            ModerationEmpty(
              targetType: current.targetType,
              statusFilter: current.statusFilter,
            ),
          );
        } else {
          emit(
            current.copyWith(
              reports: remaining,
              actionMessage: 'Contenu supprimé et journalisé',
              actionIsError: false,
            ),
          );
        }
      },
      failure: (failure) {
        emit(
          current.copyWith(
            actionMessage: 'Suppression impossible : ${failure.message}',
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoadLogs(
    LoadModerationLogs event,
    Emitter<ModerationState> emit,
  ) async {
    final current = state;
    if (current is ModerationLoaded) {
      emit(current.copyWith(isLoadingLogs: true, clearActionMessage: true));
      final result = await _repository.listModerationLogs();
      result.when(
        success: (logs) => emit(
          current.copyWith(logs: logs, isLoadingLogs: false),
        ),
        failure: (failure) => emit(
          current.copyWith(
            isLoadingLogs: false,
            actionMessage: failure.message,
            actionIsError: true,
          ),
        ),
      );
    } else {
      final result = await _repository.listModerationLogs();
      result.when(
        success: (logs) =>
            emit(ModerationLoaded(reports: const [], logs: logs)),
        failure: (failure) => emit(ModerationError(failure.message)),
      );
    }
  }
}
