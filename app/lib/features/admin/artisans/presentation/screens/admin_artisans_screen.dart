import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';
import '../../domain/models/admin_artisan.dart';
import '../bloc/admin_artisans_bloc.dart';

class AdminArtisansScreen extends StatefulWidget {
  const AdminArtisansScreen({super.key});

  @override
  State<AdminArtisansScreen> createState() => _AdminArtisansScreenState();
}

class _AdminArtisansScreenState extends State<AdminArtisansScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<AdminArtisansBloc>();
    if (bloc.state is AdminArtisansInitial) {
      bloc.add(const LoadAdminArtisans(statusFilter: 'all'));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<AdminArtisansBloc>().add(const LoadMoreAdminArtisans());
    }
  }

  void _selectStatus(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    context.read<AdminArtisansBloc>().add(
          LoadAdminArtisans(
            statusFilter: status,
            query: _searchController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width >= 760 ? 24.0 : 16.0;

    return AdminShellScaffold(
      currentIndex: 1,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    context.read<AdminArtisansBloc>().add(
                          SearchAdminArtisans(q, statusFilter: _statusFilter),
                        );
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un artisan, un métier, une ville...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              context.read<AdminArtisansBloc>().add(
                                    SearchAdminArtisans(
                                      '',
                                      statusFilter: _statusFilter,
                                    ),
                                  );
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppTheme.adminCardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ArtisanStatusTabs(
                  activeStatus: _statusFilter,
                  onSelect: _selectStatus,
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<AdminArtisansBloc, AdminArtisansState>(
              listener: (context, state) {
                if (state is AdminArtisansLoaded &&
                    state.actionMessage != null) {
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
                if (state is AdminArtisansLoading ||
                    state is AdminArtisansInitial) {
                  return const AdminLoadingView(
                    message: 'Recherche des artisans...',
                  );
                }

                if (state is AdminArtisansError) {
                  return AdminErrorView(
                    message: state.message,
                    onRetry: () => context.read<AdminArtisansBloc>().add(
                          LoadAdminArtisans(
                            statusFilter: _statusFilter,
                            query: _searchController.text,
                          ),
                        ),
                  );
                }

                if (state is AdminArtisansEmpty) {
                  return AdminEmptyView(
                    icon: Icons.person_search_rounded,
                    title: 'Aucun artisan trouvé',
                    subtitle:
                        'Aucun profil ne correspond au filtre ou à la recherche actuelle.',
                    actionLabel: 'Réinitialiser',
                    onAction: () {
                      _searchController.clear();
                      setState(() => _statusFilter = 'all');
                      context
                          .read<AdminArtisansBloc>()
                          .add(const LoadAdminArtisans(statusFilter: 'all'));
                    },
                  );
                }

                final loaded = state as AdminArtisansLoaded;
                final columns = width >= 900 ? 2 : 1;

                return RefreshIndicator(
                  color: AppTheme.adminIndigo,
                  onRefresh: () async {
                    context.read<AdminArtisansBloc>().add(
                          LoadAdminArtisans(
                            statusFilter: _statusFilter,
                            query: _searchController.text,
                          ),
                        );
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      8,
                      horizontalPad,
                      24,
                    ),
                    children: [
                      if (columns == 1)
                        ...loaded.artisans.map(
                          (artisan) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ArtisanDirectoryCard(artisan: artisan),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loaded.artisans.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 104,
                          ),
                          itemBuilder: (_, i) => _ArtisanDirectoryCard(
                            artisan: loaded.artisans[i],
                          ),
                        ),
                      if (loaded.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.adminIndigo,
                            ),
                          ),
                        )
                      else if (loaded.pagination.hasNextPage)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () => context
                                  .read<AdminArtisansBloc>()
                                  .add(const LoadMoreAdminArtisans()),
                              child: Text(
                                'Charger plus (${loaded.artisans.length}/${loaded.pagination.total})',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanStatusTabs extends StatelessWidget {
  final String activeStatus;
  final ValueChanged<String> onSelect;

  const _ArtisanStatusTabs({
    required this.activeStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('pending', 'À vérifier'),
      ('verified', 'Vérifiés'),
      ('all', 'Tous'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = activeStatus == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.adminIndigo,
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

class _ArtisanDirectoryCard extends StatelessWidget {
  final AdminArtisan artisan;
  const _ArtisanDirectoryCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    final specialty = artisan.specialty.isNotEmpty
        ? artisan.specialty
        : (artisan.category?.name ?? 'Artisan');

    return InkWell(
      onTap: () => context.push('/admin/artisans/${artisan.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.adminCardBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AdminStatusChip.artisanStatus(
                        isVerified: artisan.isVerified,
                        verificationStatus: artisan.verificationStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$specialty • ${artisan.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inscrit le ${AdminFormatters.formatDate(artisan.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
