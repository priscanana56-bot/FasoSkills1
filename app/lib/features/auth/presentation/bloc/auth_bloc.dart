import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final String role;
  final String? specialty;
  final String? city;
  final String? categoryId;

  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    required this.role,
    this.specialty,
    this.city,
    this.categoryId,
  });

  @override
  List<Object?> get props =>
      [email, password, fullName, phone, role, specialty, city, categoryId];
}

class LogoutRequested extends AuthEvent {}

/// The current user's profile was edited: refresh it everywhere.
class UserUpdated extends AuthEvent {
  final User user;
  const UserUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthFailureState extends AuthState {
  final String message;
  final dynamic details;
  const AuthFailureState(this.message, {this.details});
  @override
  List<Object?> get props => [message, details];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<UserUpdated>((event, emit) => emit(Authenticated(event.user)));
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final hasToken = await _authRepository.hasValidToken();
    if (!hasToken) {
      emit(Unauthenticated());
      return;
    }

    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) => emit(Authenticated(user)),
      failure: (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    result.when(
      success: (user) => emit(Authenticated(user)),
      failure: (failure) =>
          emit(AuthFailureState(failure.message, details: failure.details)),
    );
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.register(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phone: event.phone,
      role: event.role,
      specialty: event.specialty,
      city: event.city,
      categoryId: event.categoryId,
    );

    result.when(
      success: (user) => emit(Authenticated(user)),
      failure: (failure) =>
          emit(AuthFailureState(failure.message, details: failure.details)),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
