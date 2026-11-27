import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../chat/presentation/bloc/conversations_cubit.dart';
import '../../domain/models/artisan.dart';
import '../../domain/models/artisan_stats.dart';
import '../../domain/repositories/artisan_repository.dart';

/// Public profile of an artisan, as seen by a client.
class ArtisanProfileScreen extends StatefulWidget {
  final String artisanId;
  const ArtisanProfileScreen({super.key, required this.artisanId});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  Artisan? _artisan;
  List<ArtisanReview> _reviews = const [];
  String? _error;
  bool _loading = true;
  bool _contacting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = getIt<ArtisanRepository>();
    final results = await Future.wait([
      repo.getArtisanById(widget.artisanId),
      repo.getReviews(widget.artisanId)
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _artisan = results[0].dataOrNull as Artisan?;
      _reviews = (results[1].dataOrNull as List<ArtisanReview>?) ?? const [];
      _error = results[0].failureOrNull?.message;
    });
  }

  Future<void> _contact() async {
    final artisan = _artisan;
    if (artisan == null || artisan.userId.isEmpty) return;
    setState(() => _contacting = true);
    final conversationId =
        await context.read<ConversationsCubit>().startWith(artisan.userId);
    if (!mounted) return;
    setState(() => _contacting = false);
    if (conversationId != null) {
      context.push('/chat/$conversationId');
    } else {
      showFeedback(
          context,
          context.read<ConversationsCubit>().state.error ??
              'Impossible de contacter cet artisan',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artisan = _artisan;
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Profil artisan'),
      body: _loading
          ? const LoadingView()
          : artisan == null
              ? ErrorState(
                  message: _error ?? 'Artisan introuvable', onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _header(artisan),
                      const SizedBox(height: 14),
                      _stats(artisan),
                      const SizedBox(height: 18),
                      if (artisan.bio.isNotEmpty) ...[
                        const SectionTitle('À propos'),
                        const SizedBox(height: 6),
                        AppCard(
                            child: Text(artisan.bio,
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Palette.text))),
                        const SizedBox(height: 18),
                      ],
                      SectionTitle('Avis clients (${artisan.reviewsCount})'),
                      const SizedBox(height: 6),
                      if (_reviews.isEmpty)
                        const AppCard(
                          child: Text(
                              'Pas encore d’avis. Les avis sont laissés par les clients après une mission terminée.',
                              style: TextStyle(
                                  color: Palette.muted, fontSize: 13)),
                        ),
                      for (final r in _reviews) ...[
                        _reviewTile(r),
                        const SizedBox(height: 8)
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: artisan == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _contacting ? null : _contact,
                      icon: _contacting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Discuter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.primary,
                        side: const BorderSide(color: Palette.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/request-quote',
                          extra: {'categoryId': artisan.category?.id}),
                      icon: const Icon(Icons.request_quote_rounded),
                      label: const Text('Demander un devis'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header(Artisan a) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: Palette.heroGradient,
          borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Avatar(name: a.fullName, size: 70, verified: a.isVerified),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  <String>{
                    if (a.specialty.isNotEmpty) a.specialty,
                    if (a.category != null) a.category!.name
                  }.join(' • '),
                  style: const TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _tag(Icons.location_on_rounded, a.city),
                  _tag(Icons.schedule_rounded, a.availability),
                  if (a.isVerified) _tag(Icons.verified_rounded, 'Vérifié'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _stats(Artisan a) {
    Widget cell(String value, String label, IconData icon) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(children: [
              Icon(icon, color: Palette.primary, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Palette.ink)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Palette.muted)),
            ]),
          ),
        );
    return Row(children: [
      cell(a.rating > 0 ? a.rating.toStringAsFixed(1) : '—', 'Note',
          Icons.star_rounded),
      const SizedBox(width: 8),
      cell('${a.completedJobs}', 'Missions', Icons.task_alt_rounded),
      const SizedBox(width: 8),
      cell('${a.experienceYears} an${a.experienceYears > 1 ? 's' : ''}',
          'Expérience', Icons.workspace_premium_rounded),
    ]);
  }

  Widget _reviewTile(ArtisanReview r) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Avatar(name: r.clientName, size: 32),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(r.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Palette.ink))),
              Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                          i < r.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 15,
                          color: Palette.star))),
            ]),
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment,
                  style: const TextStyle(
                      fontSize: 13.5, color: Palette.text, height: 1.4)),
            ],
            const SizedBox(height: 4),
            Text(Fmt.relative(r.createdAt),
                style: const TextStyle(fontSize: 11, color: Palette.faint)),
          ],
        ),
      );
}
