import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/service_request.dart';
import '../../domain/repositories/request_repository.dart';

// Events
abstract class RequestEvent extends Equatable {
  const RequestEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyRequests extends RequestEvent {}

class CreateRequestSubmitted extends RequestEvent {
  final String title;
  final String description;
  final String categoryId;
  final String city;
  final String? address;

  const CreateRequestSubmitted({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.city,
    this.address,
  });

  @override
  List<Object?> get props => [title, description, categoryId, city, address];
}

// Requirement F8: Optimistic update with rollback
class CancelRequestOptimistic extends RequestEvent {
  final String requestId;
  const CancelRequestOptimistic(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RequestStatusUpdatedFromWs extends RequestEvent {
  final String requestId;
  final String newStatus;
  const RequestStatusUpdatedFromWs(
      {required this.requestId, required this.newStatus});
  @override
  List<Object?> get props => [requestId, newStatus];
}

// States (Requirement F7: loading, empty, error with retry, content)
abstract class RequestState extends Equatable {
  const RequestState();
  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}

class RequestLoaded extends RequestState {
  final List<ServiceRequest> requests;
  final String? notificationMessage;

  const RequestLoaded(this.requests, {this.notificationMessage});

  RequestLoaded copyWith({
    List<ServiceRequest>? requests,
    String? notificationMessage,
  }) {
    return RequestLoaded(
      requests ?? this.requests,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [requests, notificationMessage];
}

class RequestEmpty extends RequestState {
  final String message;
  const RequestEmpty([this.message = 'Aucune demande enregistrée']);
  @override
  List<Object?> get props => [message];
}

class RequestError extends RequestState {
  final String message;
  const RequestError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository _repository;

  RequestBloc({required RequestRepository repository})
      : _repository = repository,
        super(RequestInitial()) {
    on<LoadMyRequests>(_onLoadMyRequests);
    on<CreateRequestSubmitted>(_onCreateRequestSubmitted);
    on<CancelRequestOptimistic>(_onCancelRequestOptimistic);
    on<RequestStatusUpdatedFromWs>(_onRequestStatusUpdatedFromWs);
  }

  Future<void> _onLoadMyRequests(
      LoadMyRequests event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    final result = await _repository.getMyRequests();
    result.when(
      success: (requests) {
        if (requests.isEmpty) {
          emit(const RequestEmpty());
        } else {
          emit(RequestLoaded(requests));
        }
      },
      failure: (failure) => emit(RequestError(failure.message)),
    );
  }

  Future<void> _onCreateRequestSubmitted(
      CreateRequestSubmitted event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    final result = await _repository.createRequest(
      title: event.title,
      description: event.description,
      categoryId: event.categoryId,
      city: event.city,
      address: event.address,
    );

    result.when(
      success: (_) => add(LoadMyRequests()),
      failure: (failure) => emit(RequestError(failure.message)),
    );
  }

  /// Requirement F8: Optimistic update with rollback
  Future<void> _onCancelRequestOptimistic(
      CancelRequestOptimistic event, Emitter<RequestState> emit) async {
    if (state is! RequestLoaded) return;
    final currentRequests = (state as RequestLoaded).requests;

    // 1. Optimistic apply: mark request status as 'cancelled' immediately in UI
    final previousRequests = List<ServiceRequest>.from(currentRequests);
    final optimisticList = currentRequests.map((r) {
      if (r.id == event.requestId) {
        return r.copyWith(status: 'cancelled');
      }
      return r;
    }).toList();

    emit(RequestLoaded(optimisticList,
        notificationMessage: 'Annulation en cours...'));

    // 2. Perform API request in background
    final result = await _repository.cancelRequest(event.requestId);

    result.when(
      success: (updatedRequest) {
        // Confirmed by server
        final finalizedList = optimisticList.map((r) {
          return r.id == updatedRequest.id ? updatedRequest : r;
        }).toList();
        emit(RequestLoaded(finalizedList,
            notificationMessage: 'Demande annulée avec succès'));
      },
      failure: (failure) {
        // Rollback on failure!
        emit(RequestLoaded(previousRequests,
            notificationMessage: 'Échec de l’annulation: ${failure.message}'));
      },
    );
  }

  /// Real-time update from WebSocket: instant sync without manual reload!
  void _onRequestStatusUpdatedFromWs(
      RequestStatusUpdatedFromWs event, Emitter<RequestState> emit) {
    if (state is RequestLoaded) {
      final list = (state as RequestLoaded).requests.map((r) {
        if (r.id == event.requestId) {
          return r.copyWith(status: event.newStatus);
        }
        return r;
      }).toList();
      emit(RequestLoaded(list,
          notificationMessage: 'Mise à jour reçue en temps réel'));
    }
  }
}
