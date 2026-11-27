import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';
import '../../domain/models/admin_report.dart';
import '../bloc/moderation_bloc.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  String _targetType = 'request';
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ModerationBloc>();
    if (bloc.state is ModerationInitial) {
      bloc.add(
          const LoadReports(targetType: 'request', statusFilter: 'pending'));
    }
  }

  void _reload({String? type, String? status}) {
    setState(() {
      if (type != null) _targetType = type;
      if (status != null) _statusFilter = status;
    });
    context.read<ModerationBloc>().add(
          LoadReports(targetType: _targetType, statusFilter: _statusFilter),
        );
  }

  Future<void> _confirmDeleteContent(
    BuildContext context,
    AdminReport report,
  ) async {
    final reasonController = TextEditingController(
      text: 'Contenu non conforme aux règles FasoSkills',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le contenu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette suppression est définitive et sera enregistrée dans le journal d’audit.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motif de modération',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed == true && context.mounted) {
      context.read<ModerationBloc>().add(
            DeleteReportedContentRequested(
              reportId: report.id,
              targetType: report.targetType,
              targetId: report.targetId,
              reason: reason.isNotEmpty ? reason : null,
            ),
          );
    }
  }

  void _openAuditLogsSheet(BuildContext context) {
    context.read<ModerationBloc>().add(const LoadModerationLogs());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ModerationBloc>(),
        child: const _ModerationLogsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width >= 760 ? 24.0 : 16.0;

    return AdminShellScaffold(
      currentIndex: 3,
      body: BlocConsumer<ModerationBloc, ModerationState>(
        listener: (context, state) {
          if (state is ModerationLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  backgroundColor: state.actionIsError
                      ? AppTheme.adminDanger
                      : AppTheme.adminSuccess,
                ),
              );
          }
        },
        builder: (context, state) {
          final pendingCount = state is ModerationLoaded
              ? state.reports.where((r) => r.isPending).length
              : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  16,
                  horizontalPad,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modération & Signalements',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.adminIndigo,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Espace de contrôle et conformité Burkina',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.adminDangerSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: AppTheme.adminDanger,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$pendingCount EN ATTENTE',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.adminDanger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _TypeTabs(
                      activeType: _targetType,
                      onSelect: (t) => _reload(type: t),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('En attente'),
                          selected: _statusFilter == 'pending',
                          onSelected: (_) => _reload(status: 'pending'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tous'),
                          selected: _statusFilter == 'all',
                          onSelected: (_) => _reload(status: 'all'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openAuditLogsSheet(context),
                          icon: const Icon(Icons.history_rounded, size: 17),
                          label: const Text('Journal d’audit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(context, state, width, horizontalPad),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ModerationState state,
    double width,
    double horizontalPad,
  ) {
    if (state is ModerationLoading || state is ModerationInitial) {
      return const AdminLoadingView(message: 'Chargement des signalements...');
    }

    if (state is ModerationError) {
      return AdminErrorView(
        message: state.message,
        onRetry: () => _reload(),
      );
    }

    if (state is ModerationEmpty) {
      return AdminEmptyView(
        icon: Icons.verified_user_outlined,
        title: 'Aucun signalement',
        subtitle:
            'Tout est conforme dans cet onglet pour le filtre sélectionné.',
        actionLabel: 'Actualiser',
        onAction: () => _reload(),
      );
    }

    final loaded = state as ModerationLoaded;
    final columns = width >= 900 ? 2 : 1;

    return RefreshIndicator(
      color: AppTheme.adminIndigo,
      onRefresh: () async => _reload(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 24),
        children: [
          if (columns == 1)
            ...loaded.reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(
                  report: report,
                  onDismiss: () => context
                      .read<ModerationBloc>()
                      .add(DismissReportRequested(report.id)),
                  onDeleteContent: () => _confirmDeleteContent(context, report),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: loaded.reports.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 250,
              ),
              itemBuilder: (_, i) {
                final report = loaded.reports[i];
                return _ReportCard(
                  report: report,
                  onDismiss: () => context
                      .read<ModerationBloc>()
                      .add(DismissReportRequested(report.id)),
                  onDeleteContent: () => _confirmDeleteContent(context, report),
                );
              },
            ),
          if (loaded.pagination.hasNextPage)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: OutlinedButton(
                  onPressed: () => context
                      .read<ModerationBloc>()
                      .add(const LoadMoreReports()),
                  child: const Text('Charger plus de signalements'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  final String activeType;
  final ValueChanged<String> onSelect;

  const _TypeTabs({required this.activeType, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('request', 'Demandes'),
      ('review', 'Avis'),
      ('message', 'Messages'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = activeType == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? AppTheme.cardShadow : null,
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.adminIndigo
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AdminReport report;
  final VoidCallback onDismiss;
  final VoidCallback onDeleteContent;

  const _ReportCard({
    required this.report,
    required this.onDismiss,
    required this.onDeleteContent,
  });

  @override
  Widget build(BuildContext context) {
    final statusChip = switch (report.status) {
      'dismissed' => const AdminStatusChip(
          label: 'Ignoré',
          backgroundColor: AppTheme.adminBackground,
          textColor: AppTheme.textSecondary,
        ),
      'action_taken' => const AdminStatusChip(
          label: 'Supprimé',
          backgroundColor: AppTheme.adminMintSoft,
          textColor: AppTheme.adminSuccess,
        ),
      _ => const AdminStatusChip(
          label: 'En attente',
          backgroundColor: AppTheme.adminDangerSoft,
          textColor: AppTheme.adminDanger,
          icon: Icons.flag_rounded,
        ),
    };

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
              Expanded(
                child: Text(
                  report.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              statusChip,
            ],
          ),
          const SizedBox(height: 6),
          if (report.displayExcerpt.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.adminBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.displayExcerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Motif : ${report.reason}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.adminOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Signalé par ${report.reporter?.fullName ?? 'Utilisateur'} • ${AdminFormatters.formatDate(report.createdAt)}'
            '${report.authorName != null ? ' • Auteur : ${report.authorName}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          if (report.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.adminIndigo,
                      side: const BorderSide(color: AppTheme.adminCardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ignorer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDeleteContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminDanger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: const Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModerationLogsSheet extends StatelessWidget {
  const _ModerationLogsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return BlocBuilder<ModerationBloc, ModerationState>(
          builder: (context, state) {
            final logs = state is ModerationLoaded
                ? state.logs
                : const <ModerationLogEntry>[];
            final isLoading = state is ModerationLoaded && state.isLoadingLogs;

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.adminCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppTheme.adminIndigo),
                      SizedBox(width: 8),
                      Text(
                        'Journal d’audit & modération',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: isLoading
                      ? const AdminLoadingView(
                          message: 'Chargement du journal d’audit...',
                        )
                      : logs.isEmpty
                          ? const AdminEmptyView(
                              icon: Icons.receipt_long_outlined,
                              title: 'Aucune action journalisée',
                              subtitle:
                                  'Les décisions de modération apparaîtront ici.',
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: logs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final log = logs[i];
                                final isDelete = log.action == 'delete_content';
                                return ListTile(
                                  tileColor: AppTheme.adminBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: AppTheme.adminCardBorder,
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isDelete
                                        ? AppTheme.adminDangerSoft
                                        : AppTheme.adminAmberSoft,
                                    child: Icon(
                                      isDelete
                                          ? Icons.delete_sweep_outlined
                                          : Icons.check_circle_outline,
                                      color: isDelete
                                          ? AppTheme.adminDanger
                                          : AppTheme.adminOrange,
                                    ),
                                  ),
                                  title: Text(
                                    isDelete
                                        ? 'Contenu supprimé (${log.targetType})'
                                        : 'Signalement ignoré',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.adminIndigo,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${log.reason}\nPar ${log.adminName} • ${AdminFormatters.formatDate(log.createdAt)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
