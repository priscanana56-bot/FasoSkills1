import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/admin/artisans/domain/models/admin_artisan.dart';
import 'package:app/features/admin/artisans/domain/repositories/admin_artisans_repository.dart';
import 'package:app/features/admin/artisans/presentation/bloc/admin_artisans_bloc.dart';
import 'package:app/features/admin/categories/domain/models/admin_category.dart';
import 'package:app/features/admin/categories/domain/repositories/admin_categories_repository.dart';
import 'package:app/features/admin/categories/presentation/bloc/categories_bloc.dart';
import 'package:app/features/admin/dashboard/domain/models/admin_stats.dart';
import 'package:app/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:app/features/admin/dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:app/features/admin/moderation/domain/models/admin_report.dart';
import 'package:app/features/admin/moderation/domain/repositories/moderation_repository.dart';
import 'package:app/features/admin/moderation/presentation/bloc/moderation_bloc.dart';

class MockAdminDashboardRepository extends Mock
    implements AdminDashboardRepository {}

class MockAdminArtisansRepository extends Mock
    implements AdminArtisansRepository {}

class MockAdminCategoriesRepository extends Mock
    implements AdminCategoriesRepository {}

class MockModerationRepository extends Mock implements ModerationRepository {}

void main() {
  const tCachedStats = AdminStats(
    users: UserStats(total: 10, clients: 6, artisans: 3, admins: 1),
    artisans: ArtisanStats(total: 3, verified: 2, pending: 1, rejected: 0),
    requests: RequestStats(total: 5, pending: 2, inProgress: 1, completed: 2),
    quotes: QuoteStats(total: 4, accepted: 2, totalAcceptedAmount: 45000),
  );

  const tFreshStats = AdminStats(
    users: UserStats(total: 12, clients: 7, artisans: 4, admins: 1),
    artisans: ArtisanStats(total: 4, verified: 2, pending: 2, rejected: 0),
    requests: RequestStats(total: 6, pending: 3, inProgress: 1, completed: 2),
    quotes: QuoteStats(total: 5, accepted: 2, totalAcceptedAmount: 55000),
  );

  const tPendingArtisan = AdminArtisan(
    id: 'art_1',
    userId: 'usr_1',
    fullName: 'Moussa Sawadogo',
    email: 'moussa@fasoskills.bf',
    phone: '+22670000001',
    specialty: 'Électricien Bâtiment',
    city: 'Ouagadougou',
    isVerified: false,
    verificationStatus: 'pending',
  );

  const tVerifiedArtisan = AdminArtisan(
    id: 'art_1',
    userId: 'usr_1',
    fullName: 'Moussa Sawadogo',
    email: 'moussa@fasoskills.bf',
    phone: '+22670000001',
    specialty: 'Électricien Bâtiment',
    city: 'Ouagadougou',
    isVerified: true,
    verificationStatus: 'verified',
  );

  const tCategory = AdminCategory(
    id: 'cat_1',
    name: 'Plomberie',
    slug: 'plomberie',
    icon: 'plumbing',
    description: 'Dépannage sanitaire',
    isActive: true,
  );

  const tReport = AdminReport(
    id: 'rep_1',
    targetType: 'request',
    targetId: 'req_1',
    reason: 'Contenu inapproprié',
    status: 'pending',
    targetSnapshot: {'title': 'Demande test', 'description': 'Texte test'},
  );

  group('AdminDashboardBloc (§7.3, F9)', () {
    late MockAdminDashboardRepository dashRepo;
    late MockAdminArtisansRepository artisansRepo;
    late MockAdminCategoriesRepository catRepo;

    setUp(() {
      dashRepo = MockAdminDashboardRepository();
      artisansRepo = MockAdminArtisansRepository();
      catRepo = MockAdminCategoriesRepository();
    });

    blocTest<AdminDashboardBloc, AdminDashboardState>(
      'F9 cache-then-network: emits cached stats first, then fresh network stats',
      build: () {
        when(() => dashRepo.getCachedStats())
            .thenAnswer((_) async => tCachedStats);
        when(() => dashRepo.getStats())
            .thenAnswer((_) async => const Success(tFreshStats));
        when(() => artisansRepo.listArtisans(
              status: 'pending',
              page: 1,
              limit: 5,
            )).thenAnswer(
          (_) async => const Success(
            AdminArtisansPage(
              items: [tPendingArtisan],
              pagination: AdminPagination(total: 1),
            ),
          ),
        );
        when(() => catRepo.listCategories())
            .thenAnswer((_) async => const Success([tCategory]));

        return AdminDashboardBloc(
          dashboardRepository: dashRepo,
          artisansRepository: artisansRepo,
          categoriesRepository: catRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadAdminDashboard()),
      expect: () => [
        const AdminDashboardLoaded(stats: tCachedStats, isFromCache: true),
        const AdminDashboardLoaded(
          stats: tFreshStats,
          pendingArtisans: [tPendingArtisan],
          categories: [tCategory],
          isFromCache: false,
        ),
      ],
    );

    blocTest<AdminDashboardBloc, AdminDashboardState>(
      'emits [AdminDashboardLoading, AdminDashboardError] when network fails with no cache',
      build: () {
        when(() => dashRepo.getCachedStats()).thenAnswer((_) async => null);
        when(() => dashRepo.getStats())
            .thenAnswer((_) async => const FailureResult(NetworkFailure()));
        when(() => artisansRepo.listArtisans(
              status: 'pending',
              page: 1,
              limit: 5,
            )).thenAnswer((_) async => const FailureResult(NetworkFailure()));
        when(() => catRepo.listCategories())
            .thenAnswer((_) async => const FailureResult(NetworkFailure()));

        return AdminDashboardBloc(
          dashboardRepository: dashRepo,
          artisansRepository: artisansRepo,
          categoriesRepository: catRepo,
        );
      },
      act: (bloc) => bloc.add(const LoadAdminDashboard()),
      expect: () => [
        AdminDashboardLoading(),
        const AdminDashboardError('Problème de connexion internet'),
      ],
    );

    blocTest<AdminDashboardBloc, AdminDashboardState>(
      'QuickVerifyArtisan rolls back pending list & stats when API fails',
      build: () {
        when(() => artisansRepo.verifyArtisan('art_1')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('Erreur serveur')),
        );
        return AdminDashboardBloc(
          dashboardRepository: dashRepo,
          artisansRepository: artisansRepo,
          categoriesRepository: catRepo,
        );
      },
      seed: () => const AdminDashboardLoaded(
        stats: tFreshStats,
        pendingArtisans: [tPendingArtisan],
        categories: [tCategory],
      ),
      act: (bloc) => bloc.add(const QuickVerifyArtisan('art_1')),
      expect: () => [
        AdminDashboardLoaded(
          stats: AdminStats(
            users: tFreshStats.users,
            artisans: const ArtisanStats(
              total: 4,
              verified: 3,
              pending: 1,
              rejected: 0,
            ),
            requests: tFreshStats.requests,
            quotes: tFreshStats.quotes,
          ),
          pendingArtisans: const [],
          categories: const [tCategory],
          notificationMessage: 'Validation en cours...',
          notificationIsError: false,
        ),
        const AdminDashboardLoaded(
          stats: tFreshStats,
          pendingArtisans: [tPendingArtisan],
          categories: [tCategory],
          notificationMessage: 'Échec de la validation : Erreur serveur',
          notificationIsError: true,
        ),
      ],
    );
  });

  group('AdminArtisansBloc (§7.3, F8)', () {
    late MockAdminArtisansRepository repo;

    setUp(() {
      repo = MockAdminArtisansRepository();
    });

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'emits [AdminArtisansLoading, AdminArtisansLoaded] on LoadAdminArtisans success',
      build: () {
        when(() => repo.listArtisans(
              status: 'all',
              query: '',
              page: 1,
              limit: 10,
            )).thenAnswer(
          (_) async => const Success(
            AdminArtisansPage(
              items: [tPendingArtisan],
              pagination: AdminPagination(total: 1),
            ),
          ),
        );
        return AdminArtisansBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const LoadAdminArtisans()),
      expect: () => [
        const AdminArtisansLoading(statusFilter: 'all', searchQuery: ''),
        const AdminArtisansLoaded(
          artisans: [tPendingArtisan],
          pagination: AdminPagination(total: 1),
        ),
      ],
    );

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'emits [AdminArtisansLoading, AdminArtisansError] on failure',
      build: () {
        when(() => repo.listArtisans(
              status: 'pending',
              query: '',
              page: 1,
              limit: 10,
            )).thenAnswer(
          (_) async => const FailureResult(ForbiddenFailure('Accès refusé')),
        );
        return AdminArtisansBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const LoadAdminArtisans(statusFilter: 'pending')),
      expect: () => [
        const AdminArtisansLoading(statusFilter: 'pending', searchQuery: ''),
        const AdminArtisansError(
          'Accès refusé',
          statusFilter: 'pending',
          searchQuery: '',
        ),
      ],
    );

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'F8 debounced search triggers after 300ms',
      build: () {
        when(() => repo.listArtisans(
              status: 'all',
              query: 'Moussa',
              page: 1,
              limit: 10,
            )).thenAnswer(
          (_) async => const Success(
            AdminArtisansPage(
              items: [tPendingArtisan],
              pagination: AdminPagination(total: 1),
            ),
          ),
        );
        return AdminArtisansBloc(repository: repo);
      },
      act: (bloc) {
        bloc.add(const SearchAdminArtisans('Mo'));
        bloc.add(const SearchAdminArtisans('Moussa'));
      },
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const AdminArtisansLoading(statusFilter: 'all', searchQuery: 'Moussa'),
        const AdminArtisansLoaded(
          artisans: [tPendingArtisan],
          pagination: AdminPagination(total: 1),
          searchQuery: 'Moussa',
        ),
      ],
      verify: (_) {
        verify(() => repo.listArtisans(
              status: 'all',
              query: 'Moussa',
              page: 1,
              limit: 10,
            )).called(1);
      },
    );

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'F8 optimistic verify: updates immediately and confirms on success',
      build: () {
        when(() => repo.verifyArtisan('art_1'))
            .thenAnswer((_) async => const Success(tVerifiedArtisan));
        return AdminArtisansBloc(repository: repo);
      },
      seed: () => const AdminArtisansLoaded(
        artisans: [tPendingArtisan],
        selectedArtisan: tPendingArtisan,
      ),
      act: (bloc) => bloc.add(const VerifyAdminArtisanOptimistic('art_1')),
      expect: () => [
        AdminArtisansLoaded(
          artisans: [
            tPendingArtisan.copyWith(
              isVerified: true,
              verificationStatus: 'verified',
            ),
          ],
          selectedArtisan: tPendingArtisan.copyWith(
            isVerified: true,
            verificationStatus: 'verified',
          ),
          actionMessage: 'Attribution du badge en cours...',
          actionIsError: false,
        ),
        const AdminArtisansLoaded(
          artisans: [tVerifiedArtisan],
          selectedArtisan: tVerifiedArtisan,
          actionMessage: 'Badge Vérifié attribué avec succès',
          actionIsError: false,
        ),
      ],
    );

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'F8 optimistic verify rollback: reverts to pending state when verify fails',
      build: () {
        when(() => repo.verifyArtisan('art_1')).thenAnswer(
          (_) async => const FailureResult(NetworkFailure('Hors ligne')),
        );
        return AdminArtisansBloc(repository: repo);
      },
      seed: () => const AdminArtisansLoaded(
        artisans: [tPendingArtisan],
        selectedArtisan: tPendingArtisan,
      ),
      act: (bloc) => bloc.add(const VerifyAdminArtisanOptimistic('art_1')),
      expect: () => [
        AdminArtisansLoaded(
          artisans: [
            tPendingArtisan.copyWith(
              isVerified: true,
              verificationStatus: 'verified',
            ),
          ],
          selectedArtisan: tPendingArtisan.copyWith(
            isVerified: true,
            verificationStatus: 'verified',
          ),
          actionMessage: 'Attribution du badge en cours...',
          actionIsError: false,
        ),
        const AdminArtisansLoaded(
          artisans: [tPendingArtisan],
          selectedArtisan: tPendingArtisan,
          actionMessage: 'Échec de la vérification : Hors ligne',
          actionIsError: true,
        ),
      ],
    );

    blocTest<AdminArtisansBloc, AdminArtisansState>(
      'F8 optimistic reject rollback: reverts when reject fails',
      build: () {
        when(() => repo.rejectArtisan('art_1', 'CNIB illisible')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('Erreur 500')),
        );
        return AdminArtisansBloc(repository: repo);
      },
      seed: () => const AdminArtisansLoaded(artisans: [tPendingArtisan]),
      act: (bloc) => bloc.add(
        const RejectAdminArtisanOptimistic('art_1', 'CNIB illisible'),
      ),
      expect: () => [
        AdminArtisansLoaded(
          artisans: [
            tPendingArtisan.copyWith(
              isVerified: false,
              verificationStatus: 'rejected',
              rejectionReason: 'CNIB illisible',
            ),
          ],
          actionMessage: 'Refus du dossier en cours...',
          actionIsError: false,
        ),
        const AdminArtisansLoaded(
          artisans: [tPendingArtisan],
          actionMessage: 'Échec du refus : Erreur 500',
          actionIsError: true,
        ),
      ],
    );
  });

  group('CategoriesBloc (§7.3, F10)', () {
    late MockAdminCategoriesRepository repo;

    setUp(() {
      repo = MockAdminCategoriesRepository();
    });

    blocTest<CategoriesBloc, CategoriesState>(
      'emits [CategoriesLoading, CategoriesLoaded] on LoadCategories success',
      build: () {
        when(() => repo.listCategories())
            .thenAnswer((_) async => const Success([tCategory]));
        return CategoriesBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [
        CategoriesLoading(),
        const CategoriesLoaded(categories: [tCategory]),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'F10 exposes 422 field errors when CreateCategorySubmitted fails validation',
      build: () {
        when(() => repo.createCategory(
              name: 'A',
              icon: null,
              description: null,
              isActive: true,
            )).thenAnswer(
          (_) async => const FailureResult(
            ValidationFailure(
              'Invalid request payload',
              errors: [
                {'field': 'name', 'message': 'Minimum 2 caractères'},
              ],
            ),
          ),
        );
        return CategoriesBloc(repository: repo);
      },
      seed: () => const CategoriesLoaded(categories: [tCategory]),
      act: (bloc) => bloc.add(const CreateCategorySubmitted(name: 'A')),
      expect: () => [
        const CategoriesLoaded(categories: [tCategory], isSubmitting: true),
        const CategoriesLoaded(
          categories: [tCategory],
          isSubmitting: false,
          formFieldErrors: {'name': 'Minimum 2 caractères'},
          actionMessage: 'Invalid request payload',
          actionIsError: true,
        ),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'ToggleCategoryActiveOptimistic rolls back on failure',
      build: () {
        when(() => repo.updateCategory('cat_1', isActive: false)).thenAnswer(
          (_) async => const FailureResult(ServerFailure('Erreur réseau')),
        );
        return CategoriesBloc(repository: repo);
      },
      seed: () => const CategoriesLoaded(categories: [tCategory]),
      act: (bloc) => bloc.add(
        const ToggleCategoryActiveOptimistic(id: 'cat_1', isActive: false),
      ),
      expect: () => [
        CategoriesLoaded(categories: [tCategory.copyWith(isActive: false)]),
        const CategoriesLoaded(
          categories: [tCategory],
          actionMessage: 'Échec de la mise à jour : Erreur réseau',
          actionIsError: true,
        ),
      ],
    );
  });

  group('ModerationBloc (§7.3)', () {
    late MockModerationRepository repo;

    setUp(() {
      repo = MockModerationRepository();
    });

    blocTest<ModerationBloc, ModerationState>(
      'emits [ModerationLoading, ModerationLoaded] on LoadReports success',
      build: () {
        when(() => repo.listReports(
              type: 'request',
              status: 'pending',
              page: 1,
              limit: 15,
            )).thenAnswer(
          (_) async => const Success(
            AdminReportsPage(
              items: [tReport],
              pagination: AdminPagination(total: 1),
            ),
          ),
        );
        return ModerationBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const LoadReports()),
      expect: () => [
        const ModerationLoading(targetType: 'request', statusFilter: 'pending'),
        const ModerationLoaded(
          reports: [tReport],
          pagination: AdminPagination(total: 1),
        ),
      ],
    );

    blocTest<ModerationBloc, ModerationState>(
      'emits [ModerationLoading, ModerationError] on LoadReports failure',
      build: () {
        when(() => repo.listReports(
              type: 'review',
              status: 'pending',
              page: 1,
              limit: 15,
            )).thenAnswer(
          (_) async => const FailureResult(NetworkFailure()),
        );
        return ModerationBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const LoadReports(targetType: 'review')),
      expect: () => [
        const ModerationLoading(targetType: 'review', statusFilter: 'pending'),
        const ModerationError(
          'Problème de connexion internet',
          targetType: 'review',
          statusFilter: 'pending',
        ),
      ],
    );

    blocTest<ModerationBloc, ModerationState>(
      'DeleteReportedContentRequested removes report from pending view on success',
      build: () {
        when(() => repo.deleteContent(
              type: 'request',
              targetId: 'req_1',
              reason: 'Spam',
            )).thenAnswer((_) async => const Success(null));
        return ModerationBloc(repository: repo);
      },
      seed: () => const ModerationLoaded(reports: [tReport]),
      act: (bloc) => bloc.add(
        const DeleteReportedContentRequested(
          reportId: 'rep_1',
          targetType: 'request',
          targetId: 'req_1',
          reason: 'Spam',
        ),
      ),
      expect: () => [
        const ModerationEmpty(targetType: 'request', statusFilter: 'pending'),
      ],
    );
  });
}
