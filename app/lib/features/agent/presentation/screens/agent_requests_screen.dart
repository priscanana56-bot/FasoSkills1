import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../requests/domain/models/service_request.dart';
import '../bloc/artisan_work_cubit.dart';

/// Open client requests the artisan can answer with a quote.
class AgentRequestsScreen extends StatelessWidget {
  const AgentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Demandes clients'),
      body: BlocBuilder<ArtisanWorkCubit, ArtisanWorkState>(
        builder: (context, state) {
          final cubit = context.read<ArtisanWorkCubit>();
          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _scopeChip(context, 'Mon métier', !state.allCategories,
                      () => cubit.toggleAllCategories(false)),
                  _scopeChip(context, 'Tous les métiers', state.allCategories,
                      () => cubit.toggleAllCategories(true)),
                ]),
                const SizedBox(height: 12),
                if (state.loading && state.openRequests.isEmpty)
                  const LoadingView(),
                if (!state.loading && state.openRequests.isEmpty)
                  EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Aucune demande ouverte',
                    message: state.allCategories
                        ? 'Aucun client n’attend de devis pour le moment.'
                        : 'Aucune demande dans votre métier pour l’instant. Vous serez notifié dès qu’il y en a une.',
                  ),
                for (final r in state.openRequests) ...[
                  OpenRequestCard(request: r),
                  const SizedBox(height: 10)
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _scopeChip(BuildContext context, String label, bool selected,
          VoidCallback onTap) =>
      ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
            color: selected ? Colors.white : Palette.text,
            fontWeight: FontWeight.w700,
            fontSize: 12.5),
        selectedColor: Palette.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? Palette.primary : Palette.border),
        onSelected: (_) => onTap(),
      );
}

class OpenRequestCard extends StatelessWidget {
  final ServiceRequest request;
  const OpenRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final mine = r.myQuote;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/agent/requests/${r.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(categoryIcon(r.categoryIcon),
                size: 18, color: Palette.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(r.categoryName ?? 'Service',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Palette.primary,
                      fontWeight: FontWeight.w700)),
            ),
            Text(Fmt.relative(r.createdAt),
                style: const TextStyle(fontSize: 11.5, color: Palette.faint)),
          ]),
          const SizedBox(height: 8),
          Text(r.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink)),
          const SizedBox(height: 4),
          Text(r.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: Palette.muted, height: 1.35)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 15, color: Palette.muted),
            const SizedBox(width: 3),
            Expanded(
              child: Text('${r.city} · ${r.clientName ?? 'Client'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Palette.muted)),
            ),
            if (mine != null)
              Flexible(
                  child: Pill(
                      label: 'Devis envoyé',
                      color: Palette.success,
                      background: Palette.successSoft,
                      icon: Icons.check_rounded))
            else
              Flexible(
                  child: Pill(
                label: r.quotesCount == 0
                    ? 'Soyez le premier'
                    : '${r.quotesCount} devis',
                color: Palette.primary,
                background: Palette.primarySoft,
              )),
          ]),
        ],
      ),
    );
  }
}
