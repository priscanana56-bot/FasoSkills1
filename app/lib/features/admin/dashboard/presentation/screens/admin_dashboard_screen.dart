import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../artisans/domain/models/admin_artisan.dart';
import '../../../categories/domain/models/admin_category.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';
import '../../domain/models/admin_stats.dart';
import '../bloc/admin_dashboard_bloc.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _scrollController = ScrollController();
  final _chartsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AdminDashboardBloc>();
    if (bloc.state is AdminDashboardInitial) {
      bloc.add(const LoadAdminDashboard());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCharts() {
    final ctx = _chartsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final adminName =
        authState is Authenticated ? authState.user.fullName : 'Administrateur';

    return AdminShellScaffold(
      currentIndex: 0,
      body: BlocConsumer<AdminDashboardBloc, AdminDashboardState>(
        listener: (context, state) {
          if (state is AdminDashboardLoaded &&
              state.notificationMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.notificationMessage!),
                  backgroundColor: state.notificationIsError
                      ? AppTheme.adminDanger
                      : AppTheme.adminSuccess,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is AdminDashboardLoading ||
              state is AdminDashboardInitial) {
            return const AdminLoadingView(
              message: 'Chargement du tableau de bord...',
            );
          }

          if (state is AdminDashboardError) {
            return AdminErrorView(
              message: state.message,
              onRetry: () => context
                  .read<AdminDashboardBloc>()
                  .add(const LoadAdminDashboard(forceRefresh: true)),
            );
          }

          if (state is AdminDashboardEmpty) {
            return AdminEmptyView(
              icon: Icons.insights_rounded,
              title: 'Aucune donnée pour le moment',
              subtitle:
                  'Les statistiques apparaîtront dès les premières inscriptions.',
              actionLabel: 'Actualiser',
              onAction: () => context
                  .read<AdminDashboardBloc>()
                  .add(const LoadAdminDashboard(forceRefresh: true)),
            );
          }

          final loaded = state as AdminDashboardLoaded;
          return RefreshIndicator(
            color: AppTheme.adminIndigo,
            onRefresh: () async {
              context
                  .read<AdminDashboardBloc>()
                  .add(const LoadAdminDashboard(forceRefresh: true));
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final kpiColumns = width >= 900 ? 4 : 2;
                final artisanColumns = width >= 860 ? 2 : 1;

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: width >= 760 ? 24 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loaded.isFromCache)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.adminAmberSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 16,
                                color: AppTheme.adminOrange,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Données locales affichées — actualisation réseau en cours...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.adminIndigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _GreetingBanner(
                        adminName: adminName,
                        onChartTap: _scrollToCharts,
                      ),
                      const SizedBox(height: 16),
                      _KpiGrid(stats: loaded.stats, columns: kpiColumns),
                      const SizedBox(height: 16),
                      _CategoriesQuickCard(
                        categories: loaded.categories,
                        onManageTap: () => context.go('/admin/categories'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Artisans à vérifier',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.adminIndigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.adminAmberSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${loaded.stats.artisans.pending} en attente',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.adminOrange,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/admin/artisans'),
                            child: const Text(
                              'TOUT VOIR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (loaded.pendingArtisans.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.adminCardBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: AppTheme.adminSuccess,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Aucun dossier d’artisan en attente de vérification.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _PendingArtisansSection(
                          artisans: loaded.pendingArtisans,
                          columns: artisanColumns,
                        ),
                      const SizedBox(height: 24),
                      _AnalyticsSection(
                        key: _chartsKey,
                        charts: loaded.stats.charts,
                        isWide: width >= 860,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String adminName;
  final VoidCallback onChartTap;

  const _GreetingBanner({
    required this.adminName,
    required this.onChartTap,
  });

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.adminAmberSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: AppTheme.adminOrange,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'EN DIRECT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.adminOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BF • UTC+0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Bonjour, $adminName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Vue d’ensemble de la plateforme FasoSkills',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onChartTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.adminAmberSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.adminOrange,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AdminStats stats;
  final int columns;

  const _KpiGrid({required this.stats, required this.columns});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'UTILISATEURS',
        value: AdminFormatters.formatNumber(stats.users.total),
        subtitle:
            '${stats.users.clients} clients • ${stats.users.artisans} artisans',
        highlight: '+${stats.users.admins} admin(s)',
        highlightColor: AppTheme.adminSuccess,
        icon: Icons.groups_rounded,
        iconBg: AppTheme.adminIndigo,
        iconColor: Colors.white,
      ),
      _KpiCard(
        label: 'ARTISANS',
        value: AdminFormatters.formatNumber(stats.artisans.total),
        subtitle: '${stats.artisans.verified} vérifiés au total',
        pillLabel: '${stats.artisans.pending} en attente',
        pillBg: AppTheme.adminAmberSoft,
        pillColor: AppTheme.adminOrange,
        icon: Icons.handyman_rounded,
        iconBg: AppTheme.adminAmberSoft,
        iconColor: AppTheme.adminOrange,
      ),
      _KpiCard(
        label: 'DEMANDES',
        value: AdminFormatters.formatNumber(stats.requests.total),
        subtitle: '${stats.requests.completed} terminées',
        highlight: '${stats.requests.inProgress} en cours',
        highlightColor: AppTheme.primaryColor,
        icon: Icons.assignment_outlined,
        iconBg: AppTheme.adminIndigo,
        iconColor: Colors.white,
      ),
      _KpiCard(
        label: 'DEVIS',
        value: AdminFormatters.formatCompactFcfa(
          stats.quotes.totalAcceptedAmount,
        ),
        valueUnit: 'FCFA',
        subtitle:
            '${stats.quotes.accepted} acceptés / ${stats.quotes.total} devis',
        icon: Icons.payments_outlined,
        iconBg: AppTheme.adminMintSoft,
        iconColor: AppTheme.adminSuccess,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 152,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? valueUnit;
  final String subtitle;
  final String? highlight;
  final Color? highlightColor;
  final String? pillLabel;
  final Color? pillBg;
  final Color? pillColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    this.valueUnit,
    required this.subtitle,
    this.highlight,
    this.highlightColor,
    this.pillLabel,
    this.pillBg,
    this.pillColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              if (valueUnit != null) ...[
                const SizedBox(width: 4),
                Text(
                  valueUnit!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminOrange,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (pillLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pillLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pillColor,
                ),
              ),
            )
          else if (highlight != null)
            Text(
              highlight!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlightColor ?? AppTheme.adminSuccess,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoriesQuickCard extends StatelessWidget {
  final List<AdminCategory> categories;
  final VoidCallback onManageTap;

  const _CategoriesQuickCard({
    required this.categories,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: AppTheme.adminOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gérer les catégories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              InkWell(
                onTap: onManageTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.adminAmberSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Text(
              'Aucune catégorie enregistrée.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final isFirst = idx == 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor:
                          isFirst ? AppTheme.adminOrange : AppTheme.adminIndigo,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      label: Text(
                        isFirst ? '• ${cat.name}' : cat.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: onManageTap,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingArtisansSection extends StatelessWidget {
  final List<AdminArtisan> artisans;
  final int columns;

  const _PendingArtisansSection({
    required this.artisans,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: artisans
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PendingArtisanCard(artisan: a),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artisans.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 196,
      ),
      itemBuilder: (_, i) => _PendingArtisanCard(artisan: artisans[i]),
    );
  }
}

class _PendingArtisanCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _PendingArtisanCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    final docSummary = artisan.documents.isNotEmpty
        ? artisan.documents.map((d) => d.name).take(2).join(' & ')
        : 'Aucun document joint';

    return InkWell(
      onTap: () => context.push('/admin/artisans/${artisan.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.adminCardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.inputFillColor,
                  child: Text(
                    AdminFormatters.initials(artisan.fullName),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminIndigo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              artisan.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.adminAmberSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.adminIndigo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    artisan.specialty.isNotEmpty
                        ? artisan.specialty
                        : (artisan.category?.name ?? 'Artisan'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.adminIndigoDeep,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        docSummary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context
                        .read<AdminDashboardBloc>()
                        .add(QuickVerifyArtisan(artisan.id)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminMintButton,
                      foregroundColor: AppTheme.adminIndigo,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 17),
                    label: const Text(
                      'Vérifier',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final reason = await showRejectArtisanDialog(
                        context,
                        artisanName: artisan.fullName,
                      );
                      if (reason != null && context.mounted) {
                        context
                            .read<AdminDashboardBloc>()
                            .add(QuickRejectArtisan(artisan.id, reason));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminIndigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text(
                      'Refuser',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final AdminCharts charts;
  final bool isWide;

  const _AnalyticsSection({
    super.key,
    required this.charts,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final categoryCard = _ChartCard(
      title: 'Demandes par métier',
      icon: Icons.work_outline_rounded,
      items: charts.requestsByCategory
          .map((e) => _ChartBarItem(label: e.name, value: e.count))
          .toList(),
      barColor: AppTheme.adminOrange,
    );

    final cityCard = _ChartCard(
      title: 'Artisans par ville',
      icon: Icons.location_city_rounded,
      items: charts.artisansByCity
          .map(
            (e) => _ChartBarItem(
              label: e.city,
              value: e.count,
              suffix: '${e.verifiedCount} vérifiés',
            ),
          )
          .toList(),
      barColor: AppTheme.adminIndigo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytique plateforme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.adminIndigo,
          ),
        ),
        const SizedBox(height: 10),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: categoryCard),
              const SizedBox(width: 14),
              Expanded(child: cityCard),
            ],
          )
        else ...[
          categoryCard,
          const SizedBox(height: 12),
          cityCard,
        ],
      ],
    );
  }
}

class _ChartBarItem {
  final String label;
  final int value;
  final String? suffix;

  const _ChartBarItem({
    required this.label,
    required this.value,
    this.suffix,
  });
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ChartBarItem> items;
  final Color barColor;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = items.isEmpty
        ? 1
        : items
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: barColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Aucune donnée analytique disponible.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          else
            ...items.take(5).map((item) {
              final ratio = item.value / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.adminIndigo,
                            ),
                          ),
                        ),
                        Text(
                          item.suffix != null
                              ? '${item.value} (${item.suffix})'
                              : '${item.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 7,
                        backgroundColor: AppTheme.inputFillColor,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
