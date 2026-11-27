import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/ws_client.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsState extends Equatable {
  final bool loading;
  final List<AppNotification> items;
  final int unreadCount;
  final String? error;

  const NotificationsState(
      {this.loading = false,
      this.items = const [],
      this.unreadCount = 0,
      this.error});

  NotificationsState copyWith(
          {bool? loading,
          List<AppNotification>? items,
          int? unreadCount,
          String? error}) =>
      NotificationsState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        error: error,
      );

  @override
  List<Object?> get props => [loading, items, unreadCount, error];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _repository;
  StreamSubscription? _wsSub;

  /// Fires for each notification pushed in real time (used to show a banner).
  final _incoming = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get incoming => _incoming.stream;

  NotificationsCubit(
      {required NotificationRepository repository,
      required WebSocketClient wsClient})
      : _repository = repository,
        super(const NotificationsState()) {
    _wsSub = wsClient.on('notification:new').listen((event) {
      final data = event['data'];
      if (data is! Map || data['notification'] is! Map) return;
      final n = AppNotification.fromJson(
          Map<String, dynamic>.from(data['notification']));
      if (state.items.any((i) => i.id == n.id)) return;
      emit(state.copyWith(
          items: [n, ...state.items], unreadCount: state.unreadCount + 1));
      _incoming.add(n);
    });
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _repository.getNotifications();
    result.when(
      success: (page) => emit(
          NotificationsState(items: page.items, unreadCount: page.unreadCount)),
      failure: (f) => emit(state.copyWith(loading: false, error: f.message)),
    );
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    emit(state.copyWith(
      items: state.items
          .map((i) => i.id == n.id ? i.copyWith(isRead: true) : i)
          .toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    ));
    await _repository.markRead(n.id);
  }

  Future<void> markAllRead() async {
    emit(state.copyWith(
        items: state.items.map((i) => i.copyWith(isRead: true)).toList(),
        unreadCount: 0));
    await _repository.markAllRead();
  }

  void reset() => emit(const NotificationsState());

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _incoming.close();
    return super.close();
  }
}
