import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/account_section.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../artisans/domain/models/artisan.dart';
import '../../../artisans/domain/repositories/artisan_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/profile_photo_sheet.dart';
import '../bloc/artisan_work_cubit.dart';

/// Artisan profile tab: public trade profile (editable) + account settings.
class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! Authenticated) return const Scaffold(body: LoadingView());
    final user = auth.user;

    return Scaffold(
      backgroundColor: Palette.background,
      body: BlocBuilder<ArtisanWorkCubit, ArtisanWorkState>(
        builder: (context, state) {
          final p = state.profile;
          final status = state.stats.verificationStatus;
          return ListView(
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
                    EditableProfileAvatar(
                        user: user,
                        size: 66,
                        verified: status == 'verified'),
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
                            Text(
                              [p?.specialty, p?.city]
                                  .whereType<String>()
                                  .where((e) => e.isNotEmpty)
                                  .join(' • '),
                              style: const TextStyle(
                                  color: Color(0xFFBFDBFE), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Pill(
                              label: switch (status) {
                                'verified' => 'Profil vérifié',
                                'rejected' => 'Vérification refusée',
                                _ => 'Vérification en attente',
                              },
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.18),
                              icon: status == 'verified'
                                  ? Icons.verified_rounded
                                  : Icons.shield_outlined,
                            ),
                          ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(
                'Mon profil artisan',
                actionLabel: p == null ? null : 'Modifier',
                onAction: p == null ? null : () => _edit(context, p),
              ),
              const SizedBox(height: 6),
              if (p == null)
                const LoadingView()
              else
                AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field('Métier',
                            p.specialty.isEmpty ? 'À compléter' : p.specialty),
                        _field('Catégorie', p.category?.name ?? 'À compléter'),
                        _field('Ville', p.city),
                        _field('Expérience',
                            '${p.experienceYears} an${p.experienceYears > 1 ? 's' : ''}'),
                        _field('Disponibilité', p.availability),
                        _field(
                            'Présentation',
                            p.bio.isEmpty
                                ? 'À compléter — décrivez votre savoir-faire'
                                : p.bio,
                            last: true),
                      ]),
                ),
              if (p != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('Mes notifications'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ],
              const SizedBox(height: 18),
              AccountSection(user: user),
            ],
          );
        },
      ),
    );
  }

  Widget _field(String label, String value, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Palette.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Palette.ink, height: 1.35)),
        ]),
      );

  void _edit(BuildContext context, Artisan profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: context.read<ArtisanWorkCubit>(),
        child: _EditProfileSheet(profile: profile),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Artisan profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _specialty = TextEditingController(text: widget.profile.specialty);
  late final _city = TextEditingController(text: widget.profile.city);
  late final _experience =
      TextEditingController(text: '${widget.profile.experienceYears}');
  late final _bio = TextEditingController(text: widget.profile.bio);
  late String _availability = widget.profile.availability;
  late String? _categoryId = widget.profile.category?.id;
  List<Category> _categories = const [];
  bool _saving = false;

  static const _availabilities = [
    'Disponible',
    'Disponible le week-end',
    'Occupé cette semaine',
    'Indisponible'
  ];

  @override
  void initState() {
    super.initState();
    getIt<ArtisanRepository>().getCategories().then((r) {
      if (mounted) setState(() => _categories = r.dataOrNull ?? const []);
    });
  }

  @override
  void dispose() {
    _specialty.dispose();
    _city.dispose();
    _experience.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context.read<ArtisanWorkCubit>().updateProfile(
          specialty:
              _specialty.text.trim().isEmpty ? null : _specialty.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          categoryId: _categoryId,
          experienceYears: int.tryParse(_experience.text) ?? 0,
          bio: _bio.text.trim(),
          availability: _availability,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showFeedback(context, error, error: true);
    } else {
      Navigator.pop(context);
      showFeedback(context, 'Profil artisan mis à jour');
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilities = {..._availabilities, _availability}.toList();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Palette.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            const Text('Modifier mon profil',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name))
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _specialty,
                decoration: const InputDecoration(
                    labelText: 'Métier (ex : Plombier sanitaire)')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'Ville'))),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _experience,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Expérience', suffixText: 'ans'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _availability,
              decoration: const InputDecoration(labelText: 'Disponibilité'),
              items: [
                for (final a in availabilities)
                  DropdownMenuItem(value: a, child: Text(a))
              ],
              onChanged: (v) =>
                  setState(() => _availability = v ?? _availability),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bio,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                  labelText: 'Présentation', alignLabelWithHint: true),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor: Palette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
