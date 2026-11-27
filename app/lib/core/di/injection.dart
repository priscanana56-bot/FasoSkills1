import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';
import '../network/ws_client.dart';
import '../storage/cache_service.dart';
import '../storage/secure_storage_service.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/artisans/domain/repositories/artisan_repository.dart';
import '../../features/artisans/data/repositories/artisan_repository_impl.dart';
import '../../features/artisans/presentation/bloc/artisan_list_bloc.dart';

import '../../features/requests/domain/repositories/request_repository.dart';
import '../../features/requests/data/repositories/request_repository_impl.dart';
import '../../features/requests/presentation/bloc/request_bloc.dart';

import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/conversations_cubit.dart';

import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/presentation/bloc/notifications_cubit.dart';

import '../../features/agent/presentation/bloc/artisan_work_cubit.dart';

import '../../features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';
import '../../features/admin/dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import '../../features/admin/dashboard/presentation/bloc/admin_dashboard_bloc.dart';

import '../../features/admin/artisans/domain/repositories/admin_artisans_repository.dart';
import '../../features/admin/artisans/data/repositories/admin_artisans_repository_impl.dart';
import '../../features/admin/artisans/presentation/bloc/admin_artisans_bloc.dart';

import '../../features/admin/categories/domain/repositories/admin_categories_repository.dart';
import '../../features/admin/categories/data/repositories/admin_categories_repository_impl.dart';
import '../../features/admin/categories/presentation/bloc/categories_bloc.dart';

import '../../features/admin/moderation/domain/repositories/moderation_repository.dart';
import '../../features/admin/moderation/data/repositories/moderation_repository_impl.dart';
import '../../features/admin/moderation/presentation/bloc/moderation_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // 1. Core Services & Storage
  getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService());
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      client: getIt<http.Client>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton<WebSocketClient>(
    () => WebSocketClient(storage: getIt<SecureStorageService>()),
  );

  // 2. Repositories (Domain contracts mapped to Data implementations - F3)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton<ArtisanRepository>(
    () => ArtisanRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      cacheService: getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton<RequestRepository>(
    () => RequestRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  // Admin repositories
  getIt.registerLazySingleton<AdminDashboardRepository>(
    () => AdminDashboardRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      cacheService: getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton<AdminArtisansRepository>(
    () => AdminArtisansRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AdminCategoriesRepository>(
    () => AdminCategoriesRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ModerationRepository>(
    () => ModerationRepositoryImpl(apiClient: getIt<ApiClient>()),
  );

  // 3. BLoCs / Cubits (State management - F2)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<ArtisanListBloc>(
    () => ArtisanListBloc(repository: getIt<ArtisanRepository>()),
  );

  getIt.registerFactory<RequestBloc>(
    () => RequestBloc(repository: getIt<RequestRepository>()),
  );

  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      repository: getIt<ChatRepository>(),
      wsClient: getIt<WebSocketClient>(),
    ),
  );

  getIt.registerFactory<ConversationsCubit>(
    () => ConversationsCubit(
      repository: getIt<ChatRepository>(),
      wsClient: getIt<WebSocketClient>(),
    ),
  );

  getIt.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      repository: getIt<NotificationRepository>(),
      wsClient: getIt<WebSocketClient>(),
    ),
  );

  getIt.registerFactory<ArtisanWorkCubit>(
    () => ArtisanWorkCubit(
      requestRepository: getIt<RequestRepository>(),
      artisanRepository: getIt<ArtisanRepository>(),
      wsClient: getIt<WebSocketClient>(),
    ),
  );

  // Admin BLoCs
  getIt.registerFactory<AdminDashboardBloc>(
    () => AdminDashboardBloc(
      dashboardRepository: getIt<AdminDashboardRepository>(),
      artisansRepository: getIt<AdminArtisansRepository>(),
      categoriesRepository: getIt<AdminCategoriesRepository>(),
    ),
  );

  getIt.registerFactory<AdminArtisansBloc>(
    () => AdminArtisansBloc(repository: getIt<AdminArtisansRepository>()),
  );

  getIt.registerFactory<CategoriesBloc>(
    () => CategoriesBloc(repository: getIt<AdminCategoriesRepository>()),
  );

  getIt.registerFactory<ModerationBloc>(
    () => ModerationBloc(repository: getIt<ModerationRepository>()),
  );
}
