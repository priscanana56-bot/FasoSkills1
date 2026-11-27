import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/artisans/presentation/screens/home_screen.dart';
import '../../features/artisans/presentation/screens/artisans_screen.dart';
import '../../features/artisans/presentation/screens/artisan_profile_screen.dart';
import '../../features/requests/presentation/screens/my_requests_screen.dart';
import '../../features/requests/presentation/screens/request_quote_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/agent/presentation/screens/agent_home_screen.dart';
import '../../features/agent/presentation/screens/agent_requests_screen.dart';
import '../../features/agent/presentation/screens/agent_missions_screen.dart';
import '../../features/agent/presentation/screens/agent_profile_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/artisans/presentation/screens/admin_artisans_screen.dart';
import '../../features/admin/artisans/presentation/screens/admin_artisan_detail_screen.dart';
import '../../features/admin/categories/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/moderation/presentation/screens/admin_moderation_screen.dart';
import '../../features/admin/profile/presentation/screens/admin_profile_screen.dart';
import '../../shared/widgets/role_shells.dart';

/// Which part of the app a location belongs to. Each role may only enter its own
/// space; `/chat/*` and `/notifications` are shared and scoped by the API.
enum _Space { auth, client, artisan, admin, shared }

_Space _spaceOf(String loc) {
  if (loc == '/splash' || loc == '/login' || loc == '/register') {
    return _Space.auth;
  }
  if (loc.startsWith('/admin')) return _Space.admin;
  if (loc.startsWith('/agent')) return _Space.artisan;
  if (loc.startsWith('/chat/') || loc == '/notifications') return _Space.shared;
  return _Space.client;
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  static String homeFor(Authenticated auth) {
    if (auth.user.isAdmin) return '/admin/dashboard';
    if (auth.user.isArtisan) return '/agent/home';
    return '/home';
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final loc = state.matchedLocation;
      final space = _spaceOf(loc);
      final isAuthScreen = loc == '/login' || loc == '/register';
      final isSplash = loc == '/splash';

      // Initial session check: show splash without redirecting away from it.
      if (authState is AuthInitial) {
        return isSplash ? null : '/splash';
      }

      // Session check in progress on splash: wait there.
      // AuthLoading elsewhere (login, register, logout) must not bounce to splash.
      if (authState is AuthLoading && isSplash) {
        return null;
      }

      // Unauthenticated users may stay on the login and registration screens.
      if (authState is! Authenticated) {
        return isAuthScreen ? null : '/login';
      }

      final home = homeFor(authState);

      // Once the session check is complete, leave splash and auth screens.
      if (space == _Space.auth) return home;

      // Each role stays in its own space (no client screen for an artisan and vice versa).
      final allowed = switch (space) {
        _Space.shared => true,
        _Space.client => authState.user.isClient,
        _Space.artisan => authState.user.isArtisan,
        _Space.admin => authState.user.isAdmin,
        _Space.auth => false,
      };
      return allowed ? null : home;
    },
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),

      // ── Client space ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ClientShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/discussions',
                builder: (_, __) => const ConversationsScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/requests', builder: (_, __) => const MyRequestsScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())
          ]),
        ],
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) =>
            RequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/request-quote',
        builder: (context, state) {
          final extra = state.extra;
          return RequestQuoteScreen(
              initialCategoryId:
                  extra is Map ? extra['categoryId'] as String? : null);
        },
      ),
      GoRoute(
        path: '/artisans',
        builder: (context, state) => ArtisansScreen(
            initialCategoryId: state.uri.queryParameters['category']),
      ),
      GoRoute(
        path: '/artisans/:id',
        builder: (context, state) =>
            ArtisanProfileScreen(artisanId: state.pathParameters['id']!),
      ),

      // ── Artisan space ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ArtisanShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/agent/home',
                builder: (_, __) => const AgentHomeScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/agent/requests',
                builder: (_, __) => const AgentRequestsScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/agent/discussions',
                builder: (_, __) => const ConversationsScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/agent/missions',
                builder: (_, __) => const AgentMissionsScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/agent/profile',
                builder: (_, __) => const AgentProfileScreen())
          ]),
        ],
      ),
      GoRoute(
        path: '/agent/requests/:id',
        builder: (context, state) => RequestDetailScreen(
            requestId: state.pathParameters['id']!, asArtisan: true),
      ),

      // ── Shared (data scoped by the API to the current user) ───────────────
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen()),

      // ── Admin Routes (§7.2) ──────────────────────────────────────────────
      GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(
          path: '/admin/artisans',
          builder: (context, state) => const AdminArtisansScreen()),
      GoRoute(
        path: '/admin/artisans/:id',
        builder: (context, state) =>
            AdminArtisanDetailScreen(artisanId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesScreen()),
      GoRoute(
          path: '/admin/moderation',
          builder: (context, state) => const AdminModerationScreen()),
      GoRoute(
          path: '/admin/profile',
          builder: (context, state) => const AdminProfileScreen()),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
