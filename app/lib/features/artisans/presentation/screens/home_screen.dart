import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_cubit.dart';
import '../../../requests/presentation/bloc/request_bloc.dart';
import '../../../requests/presentation/screens/my_requests_screen.dart';
import '../../domain/models/artisan.dart';
import '../../domain/repositories/artisan_repository.dart';
import '../bloc/artisan_list_bloc.dart';
import 'artisans_screen.dart';

/// Client home: what is happening on my requests, services, best-rated artisans.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;
  List<Category> _categories = const [];

  static const _heroCards = [
    (
      tag: 'FASOSKILLS',
      title: 'Trouvez votre artisan qualifié',
      desc: 'Plomberie, électricité, menuiserie, maçonnerie...',
      icon: Icons.handyman_rounded,
      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
    ),
    (
      tag: 'DEVIS GRATUITS',
      title: 'Comparez avant de choisir',
      desc: 'Publiez une demande, recevez plusieurs devis',
      icon: Icons.receipt_long_rounded,
      colors: [Color(0xFF1E1B4B), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    ),
    (
      tag: 'CONFIANCE',
      title: 'Des artisans vérifiés et notés',
      desc: 'Chaque avis vient d’une mission terminée',
      icon: Icons.verified_user_rounded,
      colors: [Color(0xFF0B192C), Color(0xFF0284C7), Color(0xFF2563EB)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _heroTimer = Timer.periodic(const Duration(milliseconds: 4000), (_) {
      if (!mounted || !_heroController.hasClients) return;
      _heroController.animateToPage((_heroIndex + 1) % _heroCards.length,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    });
  }

  Future<void> _load() async {
    context.read<ArtisanListBloc>().add(const LoadArtisans());
    context.read<RequestBloc>().add(LoadMyRequests());
    final result = await getIt<ArtisanRepository>().getCategories();
    if (mounted) setState(() => _categories = result.dataOrNull ?? _categories);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final firstName =
        auth is Authenticated ? auth.user.fullName.split(' ').first : '';
    final unread =
        context.select<NotificationsCubit, int>((c) => c.state.unreadCount);

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Palette.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _header(firstName, unread),
              const SizedBox(height: 14),
              _hero(),
              const SizedBox(height: 12),
              _dots(),
              const SizedBox(height: 20),
              _activeRequests(),
              _services(),
              const SizedBox(height: 22),
              _topArtisans(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String firstName, int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Palette.primaryDark, Palette.primary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FasoSkills',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Palette.ink,
                      letterSpacing: -0.5)),
              if (firstName.isNotEmpty)
                Text('Bonjour $firstName',
                    style:
                        const TextStyle(fontSize: 12.5, color: Palette.muted)),
            ]),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: CountBadge(
                count: unread,
                child: const Icon(Icons.notifications_none_rounded,
                    color: Palette.ink, size: 26)),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _heroController,
        onPageChanged: (i) => setState(() => _heroIndex = i),
        itemCount: _heroCards.length,
        itemBuilder: (context, i) {
          final card = _heroCards[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: card.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                    right: -10,
                    bottom: -18,
                    child: Icon(card.icon,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.08))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(card.tag,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4)),
                    ),
                    const SizedBox(height: 10),
                    Text(card.title,
                        maxLines: 2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.2)),
                    const SizedBox(height: 4),
                    Text(card.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _heroCards.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _heroIndex ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _heroIndex ? Palette.primary : Palette.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );

  /// Requests that need the client's attention (quotes to compare, ongoing missions).
  Widget _activeRequests() {
    return BlocBuilder<RequestBloc, RequestState>(
      builder: (context, state) {
        if (state is! RequestLoaded) return const SizedBox.shrink();
        final relevant = state.requests
            .where((r) => (r.isPending && r.quotesCount > 0) || r.isActive)
            .take(2)
            .toList();
        if (relevant.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle('À suivre',
                actionLabel: 'Mes demandes',
                onAction: () => context.go('/requests')),
            const SizedBox(height: 4),
            for (final r in relevant) ...[
              RequestCard(request: r),
              const SizedBox(height: 10)
            ],
          ]),
        );
      },
    );
  }

  Widget _services() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(
          'Corps de métier',
          actionLabel: 'Explorer tout',
          onAction: () => context.push('/artisans'),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final c = _categories[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/artisans?category=${c.id}'),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Palette.border)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: const BoxDecoration(
                              color: Palette.primarySoft,
                              shape: BoxShape.circle),
                          child: Icon(categoryIcon(c.icon),
                              color: Palette.primary, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Palette.text)),
                      ]),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _topArtisans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('Artisans les mieux notés',
            actionLabel: 'Voir tout',
            onAction: () => context.push('/artisans')),
        const SizedBox(height: 4),
        BlocBuilder<ArtisanListBloc, ArtisanListState>(
          builder: (context, state) {
            if (state is ArtisanListLoading || state is ArtisanListInitial) {
              return const LoadingView();
            }
            if (state is ArtisanListError) {
              return ErrorState(
                  message: state.message,
                  onRetry: () => context
                      .read<ArtisanListBloc>()
                      .add(const LoadArtisans()));
            }
            if (state is! ArtisanListLoaded) {
              return const AppCard(
                  child: Text('Aucun artisan inscrit pour le moment.',
                      style: TextStyle(color: Palette.muted)));
            }
            final List<Artisan> top = state.artisans.take(5).toList();
            return Column(children: [
              for (final a in top) ...[
                ArtisanCard(artisan: a),
                const SizedBox(height: 10)
              ]
            ]);
          },
        ),
      ]),
    );
  }
}
