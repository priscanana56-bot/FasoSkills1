import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/models/artisan.dart';
import '../../domain/repositories/artisan_repository.dart';
import '../bloc/artisan_list_bloc.dart';

/// Client "Explorer": search artisans by name/trade and filter by category.
class ArtisansScreen extends StatelessWidget {
  final String? initialCategoryId;
  const ArtisansScreen({super.key, this.initialCategoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ArtisanListBloc>()
        ..add(LoadArtisans(categoryId: initialCategoryId)),
      child: _ArtisansView(initialCategoryId: initialCategoryId),
    );
  }
}

class _ArtisansView extends StatefulWidget {
  final String? initialCategoryId;
  const _ArtisansView({this.initialCategoryId});

  @override
  State<_ArtisansView> createState() => _ArtisansViewState();
}

class _ArtisansViewState extends State<_ArtisansView> {
  final _search = TextEditingController();
  List<Category> _categories = const [];
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    getIt<ArtisanRepository>().getCategories().then((r) {
      if (mounted) setState(() => _categories = r.dataOrNull ?? const []);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    final query = _search.text.trim();
    final bloc = context.read<ArtisanListBloc>();
    if (query.isEmpty) {
      bloc.add(LoadArtisans(categoryId: _categoryId));
    } else {
      bloc.add(SearchQueryChanged(query, categoryId: _categoryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Trouver un artisan'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => _reload(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Nom, métier (plombier, électricien...)',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Palette.muted),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          _reload();
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Palette.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Palette.border)),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Tous', null, Icons.apps_rounded),
                for (final c in _categories)
                  _chip(c.name, c.id, categoryIcon(c.icon)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: BlocBuilder<ArtisanListBloc, ArtisanListState>(
              builder: (context, state) {
                if (state is ArtisanListLoading ||
                    state is ArtisanListInitial) {
                  return const LoadingView();
                }
                if (state is ArtisanListError) {
                  return ErrorState(message: state.message, onRetry: _reload);
                }
                if (state is ArtisanListEmpty) {
                  return EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'Aucun artisan',
                    message:
                        '${state.message}.\nPubliez une demande : les artisans du métier vous enverront leurs devis.',
                    actionLabel: 'Publier une demande',
                    onAction: () => context.push('/request-quote',
                        extra: {'categoryId': _categoryId}),
                  );
                }
                final artisans = (state as ArtisanListLoaded).artisans;
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                    itemCount: artisans.length + (state.isFromCache ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (state.isFromCache && i == 0) {
                        return const Row(children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 14, color: Palette.warning),
                          SizedBox(width: 6),
                          Text('Données hors-ligne, mise à jour...',
                              style: TextStyle(
                                  fontSize: 12, color: Palette.warning)),
                        ]);
                      }
                      return ArtisanCard(
                          artisan: artisans[i - (state.isFromCache ? 1 : 0)]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? id, IconData icon) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon,
            size: 16, color: selected ? Colors.white : Palette.primary),
        label: Text(label),
        labelStyle: TextStyle(
            color: selected ? Colors.white : Palette.text,
            fontWeight: FontWeight.w700,
            fontSize: 12.5),
        selectedColor: Palette.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? Palette.primary : Palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() => _categoryId = id);
          _reload();
        },
      ),
    );
  }
}

/// Artisan row used by the explorer and the home screen.
class ArtisanCard extends StatelessWidget {
  final Artisan artisan;
  const ArtisanCard({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final available = artisan.availability.toLowerCase().startsWith('dispo');
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/artisans/${artisan.id}'),
      child: Row(
        children: [
          Avatar(
              name: artisan.fullName, size: 54, verified: artisan.isVerified),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artisan.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Palette.ink)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (artisan.specialty.isNotEmpty)
                      artisan.specialty
                    else
                      (artisan.category?.name ?? 'Artisan'),
                    artisan.city,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: Palette.primary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StarRating(
                        rating: artisan.rating,
                        count: artisan.reviewsCount,
                        size: 13),
                    Text('${artisan.completedJobs} missions',
                        style: const TextStyle(
                            fontSize: 12, color: Palette.muted)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: available ? Palette.success : Palette.faint,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                          child: Text(artisan.availability,
                              style: const TextStyle(
                                  fontSize: 12, color: Palette.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.faint),
        ],
      ),
    );
  }
}
