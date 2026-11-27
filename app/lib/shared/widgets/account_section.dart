import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../features/auth/domain/models/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/widgets/profile_photo_sheet.dart';
import 'ui_kit.dart';

/// Account settings shared by the client and artisan profiles.
class AccountSection extends StatelessWidget {
  final User user;
  const AccountSection({super.key, required this.user});

  Future<void> _editIdentity(BuildContext context) async {
    final name = TextEditingController(text: user.fullName);
    final phone = TextEditingController(text: user.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mes informations',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nom complet')),
          const SizedBox(height: 10),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    final result = await getIt<AuthRepository>()
        .updateProfile(fullName: name.text.trim(), phone: phone.text.trim());
    if (!context.mounted) return;
    result.when(
      success: (u) {
        context.read<AuthBloc>().add(UserUpdated(u));
        showFeedback(context, 'Profil mis à jour');
      },
      failure: (f) => showFeedback(context, f.message, error: true),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Mot de passe actuel')),
          const SizedBox(height: 10),
          TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Nouveau (6 caractères min.)')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Changer')),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    if (next.text.length < 6) {
      showFeedback(
          context, 'Le nouveau mot de passe doit faire au moins 6 caractères',
          error: true);
      return;
    }
    final result = await getIt<AuthRepository>()
        .changePassword(currentPassword: current.text, newPassword: next.text);
    if (!context.mounted) return;
    result.when(
      success: (_) => showFeedback(context, 'Mot de passe modifié'),
      failure: (f) => showFeedback(context, f.message, error: true),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Palette.danger),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Mon compte'),
        const SizedBox(height: 6),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(
                Icons.add_a_photo_outlined,
                'Photo de profil',
                user.profilePicture != null && user.profilePicture!.isNotEmpty
                    ? 'Modifier ou supprimer la photo'
                    : 'Ajouter une photo de profil',
                () => showProfilePhotoSheet(context, user)),
            const Divider(height: 1, indent: 52),
            _row(
                Icons.badge_outlined,
                'Mes informations',
                '${user.fullName}${(user.phone ?? '').isNotEmpty ? ' · ${user.phone}' : ''}',
                () => _editIdentity(context)),
            const Divider(height: 1, indent: 52),
            _row(Icons.lock_outline_rounded, 'Mot de passe',
                'Modifier mon mot de passe', () => _changePassword(context)),
            const Divider(height: 1, indent: 52),
            _row(Icons.logout_rounded, 'Se déconnecter', user.email,
                () => _logout(context),
                danger: true),
          ]),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? Palette.danger : Palette.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: danger ? Palette.danger : Palette.primary),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Palette.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.faint),
        ]),
      ),
    );
  }
}
