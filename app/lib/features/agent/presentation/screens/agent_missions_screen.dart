import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../requests/domain/models/quote.dart';
import '../../../requests/domain/models/service_request.dart';
import '../bloc/artisan_work_cubit.dart';

/// The artisan's work: missions in progress, quotes awaiting an answer, history.
class AgentMissionsScreen extends StatelessWidget {
  const AgentMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          title: const Text('Mes missions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink)),
          bottom: const TabBar(
            labelColor: Palette.primary,
            unselectedLabelColor: Palette.muted,
            indicatorColor: Palette.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Mes devis'),
              Tab(text: 'Terminées')
            ],
          ),
        ),
        body: BlocBuilder<ArtisanWorkCubit, ArtisanWorkState>(
          builder: (context, state) {
            final refresh = context.read<ArtisanWorkCubit>().refresh;
            if (state.loading &&
                state.missions.isEmpty &&
                state.quotes.isEmpty) {
              return const LoadingView();
            }
            return TabBarView(children: [
              _list(
                refresh,
                state.activeMissions
                    .map((m) => _MissionCard(request: m))
                    .toList(),
                const EmptyState(
                  icon: Icons.construction_rounded,
                  title: 'Aucune mission en cours',
                  message:
                      'Quand un client accepte votre devis, la mission apparaît ici.',
                ),
              ),
              _list(
                refresh,
                state.quotes.map((q) => _QuoteTile(quote: q)).toList(),
                const EmptyState(
                  icon: Icons.request_quote_outlined,
                  title: 'Aucun devis envoyé',
                  message:
                      'Répondez aux demandes de votre métier depuis l’onglet Demandes.',
                ),
              ),
              _list(
                refresh,
                state.completedMissions
                    .map((m) => _MissionCard(request: m))
                    .toList(),
                const EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Pas encore de mission terminée',
                  message:
                      'Vos missions terminées et les avis des clients s’afficheront ici.',
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _list(
      Future<void> Function() refresh, List<Widget> items, Widget empty) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: items.isEmpty
          ? ListView(children: [empty])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => items[i],
            ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final ServiceRequest request;
  const _MissionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/agent/requests/${r.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Palette.ink)),
            ),
            const SizedBox(width: 8),
            Flexible(child: Pill.requestStatus(r.status)),
          ]),
          const SizedBox(height: 6),
          Text('${r.clientName ?? 'Client'} · ${r.city}',
              style: const TextStyle(fontSize: 12.5, color: Palette.muted)),
          if (r.acceptedQuote != null) ...[
            const SizedBox(height: 8),
            Text(Fmt.fcfa(r.acceptedQuote!.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Palette.primary)),
          ],
          if (r.hasReview) ...[
            const SizedBox(height: 6),
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < r.reviewRating!
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 15,
                        color: Palette.star))),
          ],
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  final Quote quote;
  const _QuoteTile({required this.quote});

  @override
  Widget build(BuildContext context) {
    final r = quote.request;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/agent/requests/${quote.requestId}'),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r?.title ?? 'Demande',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Palette.ink)),
            const SizedBox(height: 3),
            Text(
                '${r?.clientName ?? 'Client'} · ${Fmt.relative(quote.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Palette.muted)),
            const SizedBox(height: 6),
            Text(Fmt.fcfa(quote.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Palette.primary)),
          ]),
        ),
        Pill.quoteStatus(quote.status),
      ]),
    );
  }
}
