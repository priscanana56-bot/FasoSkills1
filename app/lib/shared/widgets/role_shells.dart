import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/bloc/conversations_cubit.dart';
import 'floating_dock_nav_bar.dart';

/// Client space: Accueil · Discussions · (+ nouvelle demande) · Demandes · Explorer... kept as tabs
/// so switching never stacks pages on top of each other.
class ClientShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ClientShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final unread =
        context.select<ConversationsCubit, int>((c) => c.state.totalUnread);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingDockNavBar(
        currentIndex: shell.currentIndex,
        onItemSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        onCenterFabTap: () => context.push('/request-quote'),
        items: [
          const DockItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Accueil'),
          DockItem(
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'Discussions',
              badge: unread),
          const DockItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: 'Demandes'),
          const DockItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil'),
        ],
      ),
    );
  }
}

/// Artisan space: Accueil · Demandes · Discussions · Missions · Profil.
class ArtisanShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ArtisanShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final unread =
        context.select<ConversationsCubit, int>((c) => c.state.totalUnread);
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingDockNavBar(
        currentIndex: shell.currentIndex,
        onItemSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          const DockItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Accueil'),
          const DockItem(
              icon: Icons.inbox_outlined,
              activeIcon: Icons.inbox_rounded,
              label: 'Demandes'),
          DockItem(
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'Discussions',
              badge: unread),
          const DockItem(
              icon: Icons.handyman_outlined,
              activeIcon: Icons.handyman_rounded,
              label: 'Missions'),
          const DockItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil'),
        ],
      ),
    );
  }
}
