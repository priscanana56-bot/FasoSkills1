import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/models/service_request.dart';
import '../bloc/request_bloc.dart';

/// Client tab "Demandes": every request with its status and number of quotes.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String _filter = 'all';

  static const _filters = {
    'all': 'Toutes',
    'pending': 'En attente',
    'active': 'En cours',
    'completed': 'Terminées',
    'cancelled': 'Annulées',
  };

  @override
  void initState() {
    super.initState();
    context.read<RequestBloc>().add(LoadMyRequests());
  }

  bool _matches(ServiceRequest r) => switch (_filter) {
        'pending' => r.isPending,
        'active' => r.isActive,
        'completed' => r.isCompleted,
        'cancelled' => r.isCancelled,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Mes demandes'),
      body: BlocConsumer<RequestBloc, RequestState>(
        listener: (context, state) {
          if (state is RequestLoaded && state.notificationMessage != null) {
            showFeedback(context, state.notificationMessage!);
          }
        },
        builder: (context, state) {
          if (state is RequestLoading || state is RequestInitial) {
            return const LoadingView();
          }
          if (state is RequestError) {
            return ErrorState(
                message: state.message,
                onRetry: () =>
                    context.read<RequestBloc>().add(LoadMyRequests()));
          }
          if (state is RequestEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Aucune demande',
              message:
                  'Décrivez votre besoin : les artisans du métier vous enverront leurs devis.',
              actionLabel: 'Nouvelle demande',
              onAction: () => context.push('/request-quote'),
            );
          }
          final all = (state as RequestLoaded).requests;
          final list = all.where(_matches).toList();
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<RequestBloc>().add(LoadMyRequests()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final e in _filters.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: _filter == e.key,
                            showCheckmark: false,
                            label: Text(e.value),
                            labelStyle: TextStyle(
                              color: _filter == e.key
                                  ? Colors.white
                                  : Palette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                            selectedColor: Palette.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                                color: _filter == e.key
                                    ? Palette.primary
                                    : Palette.border),
                            onSelected: (_) => setState(() => _filter = e.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                        child: Text('Aucune demande dans cette catégorie',
                            style: TextStyle(color: Palette.muted))),
                  ),
                for (final r in list) ...[
                  RequestCard(request: r),
                  const SizedBox(height: 10)
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Request summary card, used by the client list and the home screen.
class RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final String? route;
  const RequestCard({super.key, required this.request, this.route});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final String footer;
    if (r.isPending) {
      footer = r.quotesCount == 0
          ? 'En attente de devis'
          : '${r.quotesCount} devis reçu${r.quotesCount > 1 ? 's' : ''} — à comparer';
    } else if ((r.isActive || r.isCompleted) && r.acceptedQuote != null) {
      footer =
          '${r.acceptedQuote!.artisanName ?? 'Artisan'} · ${Fmt.fcfa(r.acceptedQuote!.amount)}';
    } else {
      footer = Fmt.relative(r.createdAt);
    }
    final highlight = r.isPending && r.quotesCount > 0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(route ?? '/requests/${r.id}'),
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
            Flexible(child: Pill.requestStatus(r.status)),
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
          Text('${r.city} · ${Fmt.relative(r.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Palette.muted)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: highlight ? Palette.primarySoft : Palette.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(
                  highlight
                      ? Icons.request_quote_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: highlight ? Palette.primary : Palette.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(footer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: highlight ? Palette.primary : Palette.text,
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Palette.faint),
            ]),
          ),
        ],
      ),
    );
  }
}
