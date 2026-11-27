import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_cubit.dart';
import '../bloc/artisan_work_cubit.dart';
import 'agent_requests_screen.dart';

class AgentHomeScreen extends StatelessWidget {
  const AgentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final name =
        auth is Authenticated ? auth.user.fullName.split(' ').first : '';
    final unread =
        context.select<NotificationsCubit, int>((c) => c.state.unreadCount);

    return Scaffold(
      backgroundColor: Palette.background,
      body: BlocBuilder<ArtisanWorkCubit, ArtisanWorkState>(
        builder: (context, state) {
          if (state.loading && state.profile == null) {
            return const SafeArea(child: LoadingView());
          }
          if (state.profile == null && state.error != null) {
            return SafeArea(
                child: ErrorState(
                    message: state.error!,
                    onRetry: () => context.read<ArtisanWorkCubit>().loadAll()));
          }
          final s = state.stats;
          return RefreshIndicator(
            onRefresh: () => context.read<ArtisanWorkCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bonjour $name 👋',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Palette.ink)),
                              Text(
                                [state.profile?.specialty, state.profile?.city]
                                    .whereType<String>()
                                    .where((e) => e.isNotEmpty)
                                    .join(' • '),
                                style: const TextStyle(
                                    fontSize: 13, color: Palette.muted),
                              ),
                            ]),
                      ),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: CountBadge(
                            count: unread,
                            child: const Icon(Icons.notifications_none_rounded,
                                color: Palette.ink, size: 26)),
                      ),
                    ]),
                  ),
                ),
                if (s.verificationStatus != 'verified') ...[
                  _VerificationBanner(
                      status: s.verificationStatus,
                      profileComplete: s.profileStatus == 'complete'),
                  const SizedBox(height: 14),
                ],
                // Carte de statistiques principales de l'agent (sans aucune notion de revenu/paiement)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: Palette.heroGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.primary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.analytics_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text('Activité',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Palette.star, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  s.reviewsCount > 0
                                      ? s.rating.toStringAsFixed(1)
                                      : '5.0',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Indicateurs visuels clés : Clients/Demandes reçues, Missions terminées, Taux de succès
                      Row(
                        children: [
                          Expanded(
                            child: _HeroStatItem(
                              value: '${s.openRequests + s.activeMissions}',
                              label: 'Clients potentiels',
                              icon: Icons.people_alt_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _HeroStatItem(
                              value: '${s.completedJobs}',
                              label: 'Missions réussies',
                              icon: Icons.verified_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _HeroStatItem(
                              value: s.reviewsCount > 0
                                  ? '${s.reviewsCount}'
                                  : '0',
                              label: 'Avis clients',
                              icon: Icons.rate_review_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.75,
                  children: [
                    _StatTile(
                        value: s.openRequests,
                        label: 'Demandes ouvertes',
                        icon: Icons.inbox_rounded,
                        color: Palette.warning,
                        onTap: () => context.go('/agent/requests')),
                    _StatTile(
                        value: s.pendingQuotes,
                        label: 'Devis proposés',
                        icon: Icons.hourglass_top_rounded,
                        color: Palette.primary,
                        onTap: () => context.go('/agent/missions')),
                    _StatTile(
                        value: s.activeMissions,
                        label: 'Interventions en cours',
                        icon: Icons.construction_rounded,
                        color: Palette.success,
                        onTap: () => context.go('/agent/missions')),
                    _StatTile(
                        value: s.completedJobs,
                        label: 'Chantiers terminés',
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: () => context.go('/agent/missions')),
                  ],
                ),
                const SizedBox(height: 20),
                SectionTitle('Nouvelles demandes de votre métier',
                    actionLabel: 'Tout voir',
                    onAction: () => context.go('/agent/requests')),
                const SizedBox(height: 6),
                if (state.openRequests.isEmpty)
                  const AppCard(
                    child: Text(
                        'Aucune demande ouverte pour le moment. Vous serez notifié dès qu’un client publie une demande.',
                        style: TextStyle(color: Palette.muted, fontSize: 13)),
                  ),
                for (final r in state.openRequests.take(3)) ...[
                  OpenRequestCard(request: r),
                  const SizedBox(height: 10)
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatTile(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Palette.ink)),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11.5, color: Palette.muted)),
              ]),
        ),
      ]),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final String status;
  final bool profileComplete;
  const _VerificationBanner(
      {required this.status, required this.profileComplete});

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    final color = rejected ? Palette.danger : Palette.warning;
    final text = rejected
        ? 'Votre vérification a été refusée. Mettez à jour votre profil pour une nouvelle vérification.'
        : profileComplete
            ? 'Votre profil est en cours de vérification par l’équipe FasoSkills.'
            : 'Complétez votre profil (métier, ville, catégorie) pour être vérifié et inspirer confiance.';
    return AppCard(
      onTap: () => context.go('/agent/profile'),
      color: rejected ? Palette.dangerSoft : Palette.warningSoft,
      child: Row(children: [
        Icon(rejected ? Icons.report_rounded : Icons.shield_outlined,
            color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35))),
        Icon(Icons.chevron_right_rounded, color: color),
      ]),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
