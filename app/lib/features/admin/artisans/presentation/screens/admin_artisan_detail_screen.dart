import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';
import '../../domain/models/admin_artisan.dart';
import '../bloc/admin_artisans_bloc.dart';

class AdminArtisanDetailScreen extends StatefulWidget {
  final String artisanId;

  const AdminArtisanDetailScreen({
    super.key,
    required this.artisanId,
  });

  @override
  State<AdminArtisanDetailScreen> createState() =>
      _AdminArtisanDetailScreenState();
}

class _AdminArtisanDetailScreenState extends State<AdminArtisanDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<AdminArtisansBloc>()
        .add(LoadAdminArtisanDetail(widget.artisanId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminArtisansBloc, AdminArtisansState>(
      listener: (context, state) {
        if (state is AdminArtisansLoaded && state.actionMessage != null) {
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
        AdminArtisan? artisan;
        bool isLoading = false;
        String? error;

        if (state is AdminArtisansLoaded) {
          if (state.selectedArtisan?.id == widget.artisanId) {
            artisan = state.selectedArtisan;
          } else {
            for (final a in state.artisans) {
              if (a.id == widget.artisanId) {
                artisan = a;
                break;
              }
            }
          }
          isLoading = state.isDetailLoading && artisan == null;
          error = artisan == null ? state.detailError : null;
        } else if (state is AdminArtisansLoading) {
          isLoading = true;
        } else if (state is AdminArtisansError) {
          error = state.message;
        }

        return Scaffold(
          backgroundColor: AppTheme.adminCream,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.adminIndigo),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin/artisans');
                }
              },
            ),
            centerTitle: false,
            title: const Text(
              'Vérification Artisan',
              style: TextStyle(
                color: AppTheme.adminIndigo,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (artisan != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: AdminStatusChip.artisanStatus(
                      isVerified: artisan.isVerified,
                      verificationStatus: artisan.verificationStatus,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.adminIndigo,
                ),
                onPressed: () => context.push('/admin/profile'),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.adminCardBorder),
            ),
          ),
          body: _buildBody(context, artisan, isLoading, error),
          bottomNavigationBar:
              artisan != null ? _BottomActionBar(artisan: artisan) : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminArtisan? artisan,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return const AdminLoadingView(
          message: 'Chargement du dossier artisan...');
    }

    if (error != null) {
      return AdminErrorView(
        message: error,
        onRetry: () => context
            .read<AdminArtisansBloc>()
            .add(LoadAdminArtisanDetail(widget.artisanId)),
      );
    }

    if (artisan == null) {
      return AdminEmptyView(
        icon: Icons.person_off_outlined,
        title: 'Profil introuvable',
        subtitle: 'Ce dossier artisan n’est plus disponible.',
        actionLabel: 'Réessayer',
        onAction: () => context
            .read<AdminArtisansBloc>()
            .add(LoadAdminArtisanDetail(widget.artisanId)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        final pad = isWide ? 24.0 : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ArtisanHeaderCard(artisan: artisan),
                  const SizedBox(height: 14),
                  _StatsGrid(artisan: artisan, columns: isWide ? 4 : 2),
                  const SizedBox(height: 14),
                  if (artisan.isRejected &&
                      artisan.rejectionReason != null &&
                      artisan.rejectionReason!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.adminDangerSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.adminDanger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.adminDanger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Motif du refus : ${artisan.rejectionReason}',
                              style: const TextStyle(
                                color: AppTheme.adminDanger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _ContactCard(artisan: artisan),
                              const SizedBox(height: 14),
                              _AboutCard(artisan: artisan),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              _DocumentsCard(artisan: artisan),
                              const SizedBox(height: 14),
                              _ComplianceCard(artisan: artisan),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ContactCard(artisan: artisan),
                    const SizedBox(height: 14),
                    _AboutCard(artisan: artisan),
                    const SizedBox(height: 14),
                    _DocumentsCard(artisan: artisan),
                    const SizedBox(height: 14),
                    _ComplianceCard(artisan: artisan),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtisanHeaderCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _ArtisanHeaderCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    final specialty = artisan.specialty.isNotEmpty
        ? artisan.specialty
        : (artisan.category?.name ?? 'Artisan');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.inputFillColor,
                child: Text(
                  AdminFormatters.initials(artisan.fullName),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: artisan.isVerified
                        ? AppTheme.adminSuccess
                        : AppTheme.adminOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    artisan.isVerified
                        ? Icons.verified_rounded
                        : Icons.schedule,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artisan.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adminOrange,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      artisan.city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.adminCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.adminPeach),
                  ),
                  child: Text(
                    'Dossier soumis le ${AdminFormatters.formatDate(artisan.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminArtisan artisan;
  final int columns;

  const _StatsGrid({required this.artisan, required this.columns});

  @override
  Widget build(BuildContext context) {
    final statusText = artisan.isVerified
        ? 'Vérifié'
        : (artisan.isRejected ? 'Refusé' : 'En attente');
    final statusColor = artisan.isVerified
        ? AppTheme.adminSuccess
        : (artisan.isRejected ? AppTheme.adminDanger : AppTheme.adminOrange);

    final tiles = [
      (
        '${artisan.experienceYears} ans',
        'Expérience',
        Icons.workspace_premium_outlined,
        AppTheme.primaryColor,
      ),
      (
        statusText,
        'Statut profil',
        Icons.fact_check_outlined,
        statusColor,
      ),
      (
        '${artisan.completedJobs}',
        'Interventions',
        Icons.bolt_rounded,
        AppTheme.adminSuccess,
      ),
      (
        '${artisan.rating.toStringAsFixed(1)} ★',
        '${artisan.reviewsCount} avis',
        Icons.star_outline_rounded,
        AppTheme.adminOrange,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 82,
      ),
      itemBuilder: (_, i) {
        final item = tiles[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.adminCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$3, size: 19, color: item.$4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: i == 1 ? item.$4 : AppTheme.adminIndigo,
                      ),
                    ),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _ContactCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Coordonnées & Enregistrement',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.adminMintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  artisan.profileStatus == 'complete'
                      ? 'DOSSIER COMPLET'
                      : 'INCOMPLET',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone mobile',
            value: artisan.phone ?? 'Non renseigné',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Adresse courriel',
            value: artisan.email ?? 'Non renseignée',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.event_available_outlined,
            label: 'Disponibilité',
            value: artisan.availability,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.storefront_outlined,
            label: 'Zone d’intervention',
            value: artisan.city,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.adminBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _AboutCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'À propos de l’artisan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            artisan.bio.isNotEmpty
                ? artisan.bio
                : 'Aucune biographie renseignée par l’artisan.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (artisan.category != null)
                Chip(label: Text(artisan.category!.name)),
              if (artisan.specialty.isNotEmpty)
                Chip(label: Text(artisan.specialty)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _DocumentsCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 18, color: AppTheme.adminOrange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pièces justificatives',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminIndigo,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.adminAmberSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${artisan.documents.length} document(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adminOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (artisan.documents.isEmpty)
            const Text(
              'Aucune pièce justificative transmise pour le moment.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            )
          else
            ...artisan.documents.map(
              (doc) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.adminBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.adminCardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.adminIndigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.adminIndigo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Type : ${doc.type} • ${AdminFormatters.formatDate(doc.uploadedAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Inspecter',
                      icon: const Icon(
                        Icons.zoom_in_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(doc.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type : ${doc.type}'),
                                const SizedBox(height: 8),
                                SelectableText(
                                  doc.url,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
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
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _ComplianceCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adminCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Contrôle de conformité FasoSkills',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'En attribuant le badge Vérifié, vous activez le référencement public prioritaire avec label de confiance.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'État :',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                artisan.isVerified ? 'Badge actif' : 'Prêt pour décision admin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: artisan.isVerified
                      ? AppTheme.adminSuccess
                      : AppTheme.adminOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final AdminArtisan artisan;
  const _BottomActionBar({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.adminCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final reason = await showRejectArtisanDialog(
                        context,
                        artisanName: artisan.fullName,
                      );
                      if (reason != null && context.mounted) {
                        context.read<AdminArtisansBloc>().add(
                              RejectAdminArtisanOptimistic(artisan.id, reason),
                            );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.adminDanger,
                      side: const BorderSide(color: AppTheme.adminDanger),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Refuser',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: artisan.isVerified
                        ? null
                        : () => context.read<AdminArtisansBloc>().add(
                              VerifyAdminArtisanOptimistic(artisan.id),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminSuccess,
                      disabledBackgroundColor: AppTheme.adminMintSoft,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppTheme.adminSuccess,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: Text(
                      artisan.isVerified
                          ? 'Badge Vérifié attribué'
                          : 'Attribuer le badge Vérifié',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
