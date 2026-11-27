import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/models/user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/artisans/domain/models/artisan.dart';
import 'package:app/features/artisans/domain/repositories/artisan_repository.dart';
import 'package:app/features/artisans/presentation/bloc/artisan_list_bloc.dart';
import 'package:app/features/requests/domain/models/service_request.dart';
import 'package:app/features/requests/domain/repositories/request_repository.dart';
import 'package:app/features/requests/presentation/bloc/request_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockArtisanRepository extends Mock implements ArtisanRepository {}

class MockRequestRepository extends Mock implements RequestRepository {}

void main() {
  group('F11 - Bloc Tests', () {
    const tUser = User(
      id: 'user_123',
      email: 'client@test.bf',
      fullName: 'Test User',
      role: 'client',
    );

    group('AuthBloc', () {
      late MockAuthRepository mockAuthRepository;

      setUp(() {
        mockAuthRepository = MockAuthRepository();
      });

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when LoginSubmitted succeeds',
        build: () {
          when(() => mockAuthRepository.login(
                email: 'client@test.bf',
                password: 'Password123!',
              )).thenAnswer((_) async => const Success(tUser));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const LoginSubmitted(
          email: 'client@test.bf',
          password: 'Password123!',
        )),
        expect: () => [
          AuthLoading(),
          const Authenticated(tUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailureState] when LoginSubmitted fails',
        build: () {
          when(() => mockAuthRepository.login(
                    email: 'wrong@test.bf',
                    password: 'wrong',
                  ))
              .thenAnswer((_) async =>
                  const FailureResult(AuthFailure('Invalid credentials')));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const LoginSubmitted(
          email: 'wrong@test.bf',
          password: 'wrong',
        )),
        expect: () => [
          AuthLoading(),
          const AuthFailureState('Invalid credentials'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] on CheckAuthStatus with no token',
        build: () {
          when(() => mockAuthRepository.hasValidToken())
              .thenAnswer((_) async => false);
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          AuthLoading(),
          Unauthenticated(),
        ],
      );
    });

    group('ArtisanListBloc', () {
      late MockArtisanRepository mockArtisanRepository;

      setUp(() {
        mockArtisanRepository = MockArtisanRepository();
      });

      const tArtisan = Artisan(
        id: 'art_1',
        userId: 'u_1',
        fullName: 'Moussa Plombier',
        specialty: 'Plomberie',
        city: 'Ouagadougou',
      );

      blocTest<ArtisanListBloc, ArtisanListState>(
        'emits [ArtisanListLoading, ArtisanListLoaded] on LoadArtisans success',
        build: () {
          when(() => mockArtisanRepository.getCachedArtisans())
              .thenAnswer((_) async => null);
          when(() => mockArtisanRepository.getArtisans())
              .thenAnswer((_) async => const Success([tArtisan]));
          return ArtisanListBloc(repository: mockArtisanRepository);
        },
        act: (bloc) => bloc.add(const LoadArtisans()),
        expect: () => [
          ArtisanListLoading(),
          const ArtisanListLoaded([tArtisan], isFromCache: false),
        ],
      );

      blocTest<ArtisanListBloc, ArtisanListState>(
        'emits [ArtisanListLoading, ArtisanListEmpty] when artisan list is empty',
        build: () {
          when(() => mockArtisanRepository.getCachedArtisans())
              .thenAnswer((_) async => null);
          when(() => mockArtisanRepository.getArtisans())
              .thenAnswer((_) async => const Success([]));
          return ArtisanListBloc(repository: mockArtisanRepository);
        },
        act: (bloc) => bloc.add(const LoadArtisans()),
        expect: () => [
          ArtisanListLoading(),
          const ArtisanListEmpty(),
        ],
      );
    });

    group('RequestBloc - Optimistic Update & Rollback (F8)', () {
      late MockRequestRepository mockRequestRepository;

      setUp(() {
        mockRequestRepository = MockRequestRepository();
      });

      const tRequest = ServiceRequest(
        id: 'req_1',
        clientId: 'u_1',
        categoryId: 'cat_1',
        title: 'Fuite robinet',
        description: 'Fuite robinet cuisine',
        city: 'Ouagadougou',
        status: 'pending',
      );

      blocTest<RequestBloc, RequestState>(
        'optimistic update: marks cancelled immediately, confirms on success',
        build: () {
          when(() => mockRequestRepository.cancelRequest('req_1')).thenAnswer(
              (_) async => Success(tRequest.copyWith(status: 'cancelled')));
          return RequestBloc(repository: mockRequestRepository);
        },
        seed: () => const RequestLoaded([tRequest]),
        act: (bloc) => bloc.add(const CancelRequestOptimistic('req_1')),
        expect: () => [
          RequestLoaded(
            [tRequest.copyWith(status: 'cancelled')],
            notificationMessage: 'Annulation en cours...',
          ),
          RequestLoaded(
            [tRequest.copyWith(status: 'cancelled')],
            notificationMessage: 'Demande annulée avec succès',
          ),
        ],
      );

      blocTest<RequestBloc, RequestState>(
        'optimistic update rollback: rolls back to previous state when API call fails',
        build: () {
          when(() => mockRequestRepository.cancelRequest('req_1')).thenAnswer(
              (_) async => const FailureResult(ServerFailure('Erreur réseau')));
          return RequestBloc(repository: mockRequestRepository);
        },
        seed: () => const RequestLoaded([tRequest]),
        act: (bloc) => bloc.add(const CancelRequestOptimistic('req_1')),
        expect: () => [
          RequestLoaded(
            [tRequest.copyWith(status: 'cancelled')],
            notificationMessage: 'Annulation en cours...',
          ),
          const RequestLoaded(
            [tRequest], // Rolled back!
            notificationMessage: 'Échec de l’annulation: Erreur réseau',
          ),
        ],
      );
    });
  });
}
