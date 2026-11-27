import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/app_notification.dart';
import '../bloc/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  /// Opens what the notification is about, in the right space for the user's role.
  void _open(AppNotification n, bool isArtisan) {
    context.read<NotificationsCubit>().markRead(n);
    if (n.conversationId != null) {
      context.push('/chat/${n.conversationId}');
    } else if (n.requestId != null) {
      context.push(isArtisan
          ? '/agent/requests/${n.requestId}'
          : '/requests/${n.requestId}');
    } else if (n.type.startsWith('artisan:')) {
      context.go('/agent/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isArtisan = auth is Authenticated && auth.user.isArtisan;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Notifications', actions: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => state.unreadCount > 0
              ? TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllRead(),
                  child: const Text('Tout lire',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : const SizedBox.shrink(),
        ),
      ]),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) return const LoadingView();
          if (state.error != null && state.items.isEmpty) {
            return ErrorState(
                message: state.error!,
                onRetry: () => context.read<NotificationsCubit>().load());
          }
          if (state.items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Tout est calme',
              message: isArtisan
                  ? 'Vous serez prévenu des nouvelles demandes de votre métier et des réponses à vos devis.'
                  : 'Vous serez prévenu dès qu’un artisan vous envoie un devis ou un message.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _NotificationTile(
                notification: state.items[i],
                onTap: () => _open(state.items[i], isArtisan),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  (IconData, Color) get _style => switch (notification.type) {
        'quote:received' => (Icons.request_quote_rounded, Palette.primary),
        'quote:accepted' => (Icons.celebration_rounded, Palette.success),
        'quote:rejected' => (Icons.do_not_disturb_on_rounded, Palette.muted),
        'request:new' => (Icons.fiber_new_rounded, Palette.warning),
        'request:completed' => (Icons.task_alt_rounded, Palette.success),
        'request:cancelled' => (Icons.cancel_rounded, Palette.danger),
        'message:new' => (Icons.chat_bubble_rounded, Palette.primary),
        'review:new' => (Icons.star_rounded, Palette.star),
        'artisan:verified' => (Icons.verified_rounded, Palette.success),
        'artisan:rejected' => (Icons.report_rounded, Palette.danger),
        _ => (Icons.notifications_rounded, Palette.primary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final unread = !notification.isRead;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: unread ? const Color(0xFFF5F9FF) : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                            color: Palette.ink),
                      ),
                    ),
                    if (unread)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Palette.primary, shape: BoxShape.circle)),
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: const TextStyle(
                          fontSize: 13, color: Palette.text, height: 1.35)),
                ],
                const SizedBox(height: 5),
                Text(Fmt.relative(notification.createdAt),
                    style:
                        const TextStyle(fontSize: 11.5, color: Palette.faint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
