import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/account_section.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../notifications/presentation/bloc/notifications_cubit.dart';
import '../../../requests/presentation/bloc/request_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/profile_photo_sheet.dart';

/// Client profile tab.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! Authenticated) return const Scaffold(body: LoadingView());
    final user = auth.user;
    final unread =
        context.select<NotificationsCubit, int>((c) => c.state.unreadCount);
    final requests = context.select<RequestBloc, List<dynamic>>((b) =>
        b.state is RequestLoaded
            ? (b.state as RequestLoaded).requests
            : const []);

    return Scaffold(
      backgroundColor: Palette.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  gradient: Palette.heroGradient,
                  borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                EditableProfileAvatar(user: user, size: 66),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(user.email,
                            style: const TextStyle(
                                color: Color(0xFFBFDBFE), fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('Espace client',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Mon activité'),
          const SizedBox(height: 6),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _link(
                  context,
                  Icons.assignment_outlined,
                  'Mes demandes',
                  '${requests.length} demande${requests.length > 1 ? 's' : ''}',
                  () => context.go('/requests')),
              const Divider(height: 1, indent: 52),
              _link(
                  context,
                  Icons.notifications_none_rounded,
                  'Notifications',
                  unread > 0
                      ? '$unread non lue${unread > 1 ? 's' : ''}'
                      : 'À jour',
                  () => context.push('/notifications')),
              const Divider(height: 1, indent: 52),
              _link(
                  context,
                  Icons.person_search_outlined,
                  'Trouver un artisan',
                  'Rechercher par métier ou par nom',
                  () => context.push('/artisans')),
            ]),
          ),
          const SizedBox(height: 18),
          AccountSection(user: user),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String title,
          String subtitle, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, color: Palette.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Palette.ink)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Palette.muted)),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.faint),
          ]),
        ),
      );
}
