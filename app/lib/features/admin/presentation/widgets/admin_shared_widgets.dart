import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/bloc/admin_dashboard_bloc.dart';

/// Utilitaires de formatage sans dépendance à l'initialisation de locale Intl.
class AdminFormatters {
  AdminFormatters._();

  static const _monthsFr = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static String formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${_monthsFr[d.month - 1]} ${d.year}';
  }

  static String formatNumber(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(' ');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String formatCompactFcfa(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(0)}k';
    }
    return formatNumber(amount);
  }

  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static IconData categoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plumbing':
      case 'water_drop':
        return Icons.plumbing_rounded;
      case 'electrical_services':
      case 'bolt':
        return Icons.electrical_services_rounded;
      case 'carpenter':
      case 'handyman':
        return Icons.carpenter_rounded;
      case 'format_paint':
      case 'paint':
        return Icons.format_paint_rounded;
      case 'ac_unit':
      case 'hvac':
        return Icons.ac_unit_rounded;
      case 'construction':
      case 'foundation':
        return Icons.construction_rounded;
      case 'checkroom':
      case 'cut':
        return Icons.content_cut_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

/// Shell responsive : BottomNavigationBar sur mobile, NavigationRail sur tablette/desktop.
class AdminShellScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;

  const AdminShellScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
  });

  static const _routes = [
    '/admin/dashboard',
    '/admin/artisans',
    '/admin/categories',
    '/admin/moderation',
  ];

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 760;
    final isExtended = width >= 1120;

    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      appBar: isWide ? null : const _AdminMobileAppBar(),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  extended: isExtended,
                  backgroundColor: Colors.white,
                  indicatorColor: AppTheme.adminIndigo.withValues(alpha: 0.10),
                  selectedIconTheme:
                      const IconThemeData(color: AppTheme.adminOrange),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.adminIndigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedIconTheme:
                      const IconThemeData(color: AppTheme.textSecondary),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  onDestinationSelected: (i) =>
                      _onDestinationSelected(context, i),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: isExtended
                        ? Row(
                            children: [
                              const Text(
                                'FASOSKILLS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.6,
                                  color: AppTheme.adminIndigo,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _AdminBadgePill(),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.adminIndigo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _AdminBadgePill(),
                            ],
                          ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: isExtended
                            ? TextButton.icon(
                                onPressed: () => context.push('/admin/profile'),
                                icon: const Icon(Icons.person_outline_rounded),
                                label: const Text('Profil Admin'),
                              )
                            : IconButton(
                                tooltip: 'Profil Admin',
                                onPressed: () => context.push('/admin/profile'),
                                icon: const Icon(Icons.person_outline_rounded),
                              ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: Text('Tableau de bord'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.handyman_outlined),
                      selectedIcon: Icon(Icons.handyman_rounded),
                      label: Text('Artisans'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.category_outlined),
                      selectedIcon: Icon(Icons.category_rounded),
                      label: Text('Catégories'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      selectedIcon: Icon(Icons.verified_user_rounded),
                      label: Text('Modération'),
                    ),
                  ],
                ),
                const VerticalDivider(
                    width: 1, color: AppTheme.adminCardBorder),
                Expanded(
                  child: Column(
                    children: [
                      const _AdminDesktopTopBar(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.adminCardBorder, width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) => _onDestinationSelected(context, i),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: AppTheme.adminOrange,
                unselectedItemColor: AppTheme.textSecondary,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Bord',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.handyman_outlined),
                    activeIcon: Icon(Icons.handyman_rounded),
                    label: 'Artisans',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category_outlined),
                    activeIcon: Icon(Icons.category_rounded),
                    label: 'Catégories',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.verified_user_outlined),
                    activeIcon: Icon(Icons.verified_user_rounded),
                    label: 'Modération',
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdminBadgePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.adminAmberSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          color: AppTheme.adminOrange,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _AdminMobileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdminMobileAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          const Text(
            'FASOSKILLS',
            style: TextStyle(
              color: AppTheme.adminIndigo,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          _AdminBadgePill(),
        ],
      ),
      actions: const [
        _AdminNotificationBell(),
        SizedBox(width: 6),
        _AdminAvatarButton(),
        SizedBox(width: 12),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppTheme.adminCardBorder),
      ),
    );
  }
}

class _AdminDesktopTopBar extends StatelessWidget {
  const _AdminDesktopTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.adminCardBorder),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 18, color: AppTheme.adminIndigo),
          const SizedBox(width: 8),
          const Text(
            'Console d’administration • Burkina Faso',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const _AdminNotificationBell(),
          const SizedBox(width: 10),
          const _AdminAvatarButton(),
        ],
      ),
    );
  }
}

class _AdminNotificationBell extends StatelessWidget {
  const _AdminNotificationBell();

  @override
  Widget build(BuildContext context) {
    final dashState = context.watch<AdminDashboardBloc>().state;
    int pendingCount = 0;
    int pendingReports = 0;
    if (dashState is AdminDashboardLoaded) {
      pendingCount = dashState.stats.artisans.pending;
      pendingReports = dashState.stats.reports.pending;
    }
    final totalAlerts = pendingCount + pendingReports;

    return IconButton(
      tooltip: 'Alertes en attente',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertes de la plateforme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.adminIndigo,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.adminAmberSoft,
                    child: Icon(Icons.handyman_rounded,
                        color: AppTheme.adminOrange),
                  ),
                  title: Text('$pendingCount artisan(s) à vérifier'),
                  subtitle: const Text('Dossiers en attente de validation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/admin/artisans');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.adminDangerSoft,
                    child:
                        Icon(Icons.flag_rounded, color: AppTheme.adminDanger),
                  ),
                  title: Text('$pendingReports signalement(s) ouverts'),
                  subtitle: const Text('Demandes, avis ou messages signalés'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/admin/moderation');
                  },
                ),
              ],
            ),
          ),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.adminBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.adminCardBorder),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppTheme.adminIndigo,
            ),
          ),
          if (totalAlerts > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppTheme.adminOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminAvatarButton extends StatelessWidget {
  const _AdminAvatarButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/profile'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.adminIndigo,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.adminCardBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppTheme.adminSuccess,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── F7 Reusable State Views ─────────────────────────────────────────────────

class AdminLoadingView extends StatelessWidget {
  final String message;
  const AdminLoadingView({super.key, this.message = 'Chargement en cours...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.adminIndigo),
            const SizedBox(height: 16),
            Text(
              message,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppTheme.adminAmberSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppTheme.adminOrange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.adminIndigo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.adminDangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppTheme.adminDanger,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les données',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.adminIndigo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminIndigo,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AdminStatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory AdminStatusChip.artisanStatus({
    required bool isVerified,
    required String verificationStatus,
  }) {
    if (isVerified) {
      return const AdminStatusChip(
        label: 'Vérifié',
        backgroundColor: AppTheme.adminMintSoft,
        textColor: AppTheme.adminSuccess,
        icon: Icons.check_circle_outline_rounded,
      );
    }
    if (verificationStatus == 'rejected') {
      return const AdminStatusChip(
        label: 'Refusé',
        backgroundColor: AppTheme.adminDangerSoft,
        textColor: AppTheme.adminDanger,
        icon: Icons.cancel_outlined,
      );
    }
    return const AdminStatusChip(
      label: 'En attente',
      backgroundColor: AppTheme.adminAmberSoft,
      textColor: AppTheme.adminOrange,
      icon: Icons.circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: icon == Icons.circle ? 7 : 13, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Boîte de dialogue partagée pour saisir un motif de refus d'artisan (min 3 car.).
Future<String?> showRejectArtisanDialog(
  BuildContext context, {
  required String artisanName,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  const presets = [
    'Pièce d’identité illisible',
    'Attestation professionnelle manquante',
    'Informations de profil incomplètes',
  ];

  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Refuser $artisanName'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indiquez le motif du refus qui sera communiqué à l’artisan :',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets
                    .map(
                      (p) => ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        onPressed: () => controller.text = p,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motif du refus *',
                  hintText: 'Ex: Numéro CNIB non lisible sur la photo',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Saisissez au moins 3 caractères';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.adminDanger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer le refus'),
        ),
      ],
    ),
  );

  controller.dispose();
  return reason;
}
