import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection.dart';
import 'core/network/ws_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/artisans/presentation/bloc/artisan_list_bloc.dart';
import 'features/requests/presentation/bloc/request_bloc.dart';
import 'features/chat/presentation/bloc/conversations_cubit.dart';
import 'features/notifications/presentation/bloc/notifications_cubit.dart';
import 'features/agent/presentation/bloc/artisan_work_cubit.dart';
import 'features/admin/dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import 'features/admin/artisans/presentation/bloc/admin_artisans_bloc.dart';
import 'features/admin/categories/presentation/bloc/categories_bloc.dart';
import 'features/admin/moderation/presentation/bloc/moderation_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // F4: Single composition root via GetIt
  await setupDependencyInjection();

  runApp(const FasoSkillsApp());
}

class FasoSkillsApp extends StatefulWidget {
  const FasoSkillsApp({super.key});

  @override
  State<FasoSkillsApp> createState() => _FasoSkillsAppState();
}

class _FasoSkillsAppState extends State<FasoSkillsApp> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;
  late final ConversationsCubit _conversations;
  late final NotificationsCubit _notifications;
  late final ArtisanWorkCubit _artisanWork;
  late final RequestBloc _requests;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _incomingSub;
  String? _sessionUserId;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _conversations = getIt<ConversationsCubit>();
    _notifications = getIt<NotificationsCubit>();
    _artisanWork = getIt<ArtisanWorkCubit>();
    _requests = getIt<RequestBloc>();
    // F5: Declarative navigation with auth-driven & role-driven route guard
    _appRouter = AppRouter(authBloc: _authBloc);

    // Real-time banner for important events (messages already show a badge).
    _incomingSub = _notifications.incoming.listen((n) {
      if (n.type == 'message:new') return;
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(n.title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
    });
  }

  /// Starts / stops everything tied to the logged-in user.
  void _onAuthChanged(AuthState state) {
    if (state is Authenticated) {
      if (_sessionUserId == state.user.id) {
        return; // same session, just a profile update
      }
      _sessionUserId = state.user.id;
      getIt<WebSocketClient>().connect();
      _conversations.load();
      _notifications.load();
      if (state.user.isArtisan) _artisanWork.loadAll();
      if (state.user.isClient) _requests.add(LoadMyRequests());
    } else if (state is Unauthenticated) {
      _sessionUserId = null;
      getIt<WebSocketClient>().disconnect();
      _conversations.reset();
      _notifications.reset();
      _artisanWork.reset();
    }
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ArtisanListBloc>(create: (_) => getIt<ArtisanListBloc>()),
        BlocProvider<RequestBloc>.value(value: _requests),
        BlocProvider<ConversationsCubit>.value(value: _conversations),
        BlocProvider<NotificationsCubit>.value(value: _notifications),
        BlocProvider<ArtisanWorkCubit>.value(value: _artisanWork),
        BlocProvider<AdminDashboardBloc>(
            create: (_) => getIt<AdminDashboardBloc>()),
        BlocProvider<AdminArtisansBloc>(
            create: (_) => getIt<AdminArtisansBloc>()),
        BlocProvider<CategoriesBloc>(create: (_) => getIt<CategoriesBloc>()),
        BlocProvider<ModerationBloc>(create: (_) => getIt<ModerationBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) => _onAuthChanged(state),
        child: MaterialApp.router(
          title: 'FasoSkills',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scaffoldMessengerKey: _messengerKey,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
