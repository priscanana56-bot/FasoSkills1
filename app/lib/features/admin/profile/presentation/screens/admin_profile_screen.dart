import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../dashboard/domain/models/admin_stats.dart';
import '../../../dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import '../../../moderation/presentation/bloc/moderation_bloc.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final dashState = context.watch<AdminDashboardBloc>().state;
    final AdminStats? stats =
        dashState is AdminDashboardLoaded ? dashState.stats : null;

    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppTheme.adminIndigo),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
        centerTitle: false,
        title: const Text(
          'Profil Admin',
          style: TextStyle(
            color: AppTheme.adminIndigo,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.inputFillColor,
              child: Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: AppTheme.adminIndigo,
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.adminCardBorder),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'CONSOLE D’ADMINISTRATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AdminHeroCard(
                      fullName: user?.fullName ?? 'Administrateur FasoSkills',
                      email: user?.email ?? 'admin@fasoskills.bf',
                    ),
                    const SizedBox(height: 18),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _PlatformStatsSection(stats: stats)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _AccountSettingsSection(stats: stats),
                                const SizedBox(height: 16),
                                const _EmergencyAccessCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _PlatformStatsSection(stats: stats),
                      const SizedBox(height: 18),
                      _AccountSettingsSection(stats: stats),
                      const SizedBox(height: 16),
                      const _EmergencyAccessCard(),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.adminDangerSoft,
                        foregroundColor: AppTheme.adminDanger,
                        side: BorderSide(
                          color: AppTheme.adminDanger.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FasoSkills Admin • Burkina Faso\nSession sécurisée JWT avec rotation des jetons',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  final String fullName;
  final String email;

  const _AdminHeroCard({required this.fullName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.adminCardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.adminIndigo, AppTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    AdminFormatters.initials(fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminIndigo,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const AdminStatusChip(
                      label: 'Administrateur certifié',
                      backgroundColor: AppTheme.adminMintSoft,
                      textColor: AppTheme.adminSuccess,
                      icon: Icons.verified_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'Ouagadougou, BF',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Spacer(),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'Console active',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformStatsSection extends StatelessWidget {
  final AdminStats? stats;
  const _PlatformStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final artisansTotal = stats?.artisans.total ?? 0;
    final usersTotal = stats?.users.total ?? 0;
    final verifiedTotal = stats?.artisans.verified ?? 0;
    final pendingArtisans = stats?.artisans.pending ?? 0;
    final reportsTotal = stats?.reports.total ?? 0;
    final pendingReports = stats?.reports.pending ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.adminOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Statistiques de la plateforme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminIndigo,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.adminCardBorder),
              ),
              child: const Text(
                'Temps réel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.adminCardBorder),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL ARTISANS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AdminFormatters.formatNumber(artisansTotal),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AdminStatusChip(
                    label: '$pendingArtisans en attente',
                    backgroundColor: AppTheme.adminAmberSoft,
                    textColor: AppTheme.adminOrange,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ouaga, Bobo, Koudougou',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _ProfileMiniStat(
              label: 'UTILISATEURS',
              value: AdminFormatters.formatNumber(usersTotal),
              sub: 'Comptes actifs',
              icon: Icons.groups_outlined,
              color: AppTheme.primaryColor,
            ),
            _ProfileMiniStat(
              label: 'DOSSIERS',
              value: AdminFormatters.formatNumber(verifiedTotal),
              sub: 'Artisans vérifiés',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.adminSuccess,
            ),
            _ProfileMiniStat(
              label: 'DEMANDES',
              value: AdminFormatters.formatNumber(stats?.requests.total ?? 0),
              sub: '${stats?.requests.completed ?? 0} terminées',
              icon: Icons.speed_rounded,
              color: AppTheme.adminOrange,
            ),
            _ProfileMiniStat(
              label: 'SIGNALEMENTS',
              value: AdminFormatters.formatNumber(reportsTotal),
              sub: '$pendingReports en attente',
              icon: Icons.flag_outlined,
              color: AppTheme.adminDanger,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _ProfileMiniStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.adminIndigo,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AccountSettingsSection extends StatelessWidget {
  final AdminStats? stats;
  const _AccountSettingsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pendingTotal =
        (stats?.artisans.pending ?? 0) + (stats?.reports.pending ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.adminIndigo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Paramètres du compte & Sécurité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.adminIndigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.adminCardBorder),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text(
                  'Notifications administratives',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '$pendingTotal alerte(s) en attente de traitement',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/admin/artisans'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text(
                  'Journal d’audit & Activité',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Historique des modérations et décisions',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context
                      .read<ModerationBloc>()
                      .add(const LoadModerationLogs());
                  context.go('/admin/moderation');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_rounded),
                title: const Text(
                  'Sécurité & Session',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Stockage sécurisé + rotation des tokens',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const AdminStatusChip(
                  label: 'Actif',
                  backgroundColor: AppTheme.adminMintSoft,
                  textColor: AppTheme.adminSuccess,
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.translate_rounded),
                title: Text(
                  'Langue de l’interface',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  'Français (Burkina Faso)',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  'FR',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyAccessCard extends StatelessWidget {
  const _EmergencyAccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACCÈS D’URGENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppTheme.adminIndigo,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Support Interne'),
                        content: const Text(
                          'Contact équipe technique FasoSkills : support@fasoskills.bf',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded, size: 17),
                  label: const Text('Support Interne'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Guide Régulateur'),
                        content: const Text(
                          'Vérifiez la concordance CNIB + attestation métier avant d’attribuer le badge Vérifié. Toute suppression de contenu est journalisée.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Compris'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.policy_outlined,
                    size: 17,
                    color: AppTheme.adminOrange,
                  ),
                  label: const Text('Guide Régulateur'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
