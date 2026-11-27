import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/ws_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../chat/presentation/bloc/conversations_cubit.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/service_request.dart';
import '../../domain/repositories/request_repository.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_detail_cubit.dart';

/// A service request. [asArtisan] switches between the client view (quotes,
/// accept, complete, review) and the artisan view (send quote, mission).
class RequestDetailScreen extends StatelessWidget {
  final String requestId;
  final bool asArtisan;

  const RequestDetailScreen(
      {super.key, required this.requestId, this.asArtisan = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RequestDetailCubit(
        repository: getIt<RequestRepository>(),
        wsClient: getIt<WebSocketClient>(),
        requestId: requestId,
        isClient: !asArtisan,
      )..load(),
      child: _RequestDetailView(asArtisan: asArtisan),
    );
  }
}

class _RequestDetailView extends StatelessWidget {
  final bool asArtisan;
  const _RequestDetailView({required this.asArtisan});

  Future<void> _chatWith(
      BuildContext context, String? userId, String requestId) async {
    if (userId == null || userId.isEmpty) return;
    final id = await context
        .read<ConversationsCubit>()
        .startWith(userId, requestId: requestId);
    if (!context.mounted) return;
    if (id != null) {
      context.push('/chat/$id');
    } else {
      showFeedback(context, 'Impossible d’ouvrir la discussion', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestDetailCubit, RequestDetailState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, state) {
        showFeedback(context, state.message!, error: state.messageIsError);
        // Keep the client's list in sync with what just changed here.
        if (!asArtisan && !state.messageIsError) {
          context.read<RequestBloc>().add(LoadMyRequests());
        }
      },
      builder: (context, state) {
        final request = state.request;
        return Scaffold(
          backgroundColor: Palette.background,
          appBar:
              pageAppBar(context, asArtisan ? 'Demande client' : 'Ma demande'),
          body: state.loading && request == null
              ? const LoadingView()
              : request == null
                  ? ErrorState(
                      message: state.error ?? 'Demande introuvable',
                      onRetry: () => context.read<RequestDetailCubit>().load())
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () => context
                              .read<RequestDetailCubit>()
                              .load(silent: true),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            children: [
                              _RequestHeader(
                                  request: request, asArtisan: asArtisan),
                              const SizedBox(height: 18),
                              if (asArtisan)
                                ..._artisanSection(context, request)
                              else
                                ..._clientSection(
                                    context, request, state.quotes),
                            ],
                          ),
                        ),
                        if (state.busy)
                          const Positioned.fill(
                            child: ColoredBox(
                                color: Color(0x33FFFFFF), child: LoadingView()),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  // ── Client ────────────────────────────────────────────────────────────────
  List<Widget> _clientSection(
      BuildContext context, ServiceRequest r, List<Quote> quotes) {
    final cubit = context.read<RequestDetailCubit>();
    final accepted = r.acceptedQuote;

    if (r.isPending) {
      final pending = quotes.where((q) => q.status != 'rejected').toList();
      return [
        SectionTitle('Devis reçus (${pending.length})'),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          const AppCard(
            child: Row(children: [
              Icon(Icons.campaign_rounded, color: Palette.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les artisans de ce métier ont été prévenus. Vous recevrez une notification dès qu’un devis arrive.',
                  style: TextStyle(
                      fontSize: 13.5, color: Palette.text, height: 1.4),
                ),
              ),
            ]),
          ),
        for (final q in pending) ...[
          _QuoteCard(
            quote: q,
            actions: [
              _ActionButton.outlined(
                  'Discuter',
                  Icons.chat_bubble_outline_rounded,
                  () => _chatWith(context, q.artisanUserId, r.id)),
              _ActionButton.outlined('Refuser', Icons.close_rounded, () async {
                if (await _confirm(context, 'Refuser ce devis ?',
                    '${q.artisanName ?? 'L’artisan'} sera prévenu.')) {
                  cubit.rejectQuote(q);
                }
              }, danger: true),
              _ActionButton.filled('Accepter', Icons.check_rounded, () async {
                if (await _confirm(context, 'Accepter ce devis ?',
                    '${Fmt.fcfa(q.amount)} avec ${q.artisanName ?? 'cet artisan'}. Les autres devis seront refusés automatiquement.')) {
                  cubit.acceptQuote(q);
                }
              }),
            ],
            onOpenProfile: () => context.push('/artisans/${q.artisanId}'),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            if (await _confirm(context, 'Annuler la demande ?',
                'Les artisans ne pourront plus vous envoyer de devis.')) {
              cubit.cancel();
            }
          },
          icon: const Icon(Icons.cancel_outlined, color: Palette.danger),
          label: const Text('Annuler la demande',
              style: TextStyle(
                  color: Palette.danger, fontWeight: FontWeight.w700)),
        ),
      ];
    }

    if (r.isActive && accepted != null) {
      return [
        const SectionTitle('Votre artisan'),
        const SizedBox(height: 8),
        _QuoteCard(
          quote: accepted,
          actions: [
            _ActionButton.outlined(
                'Discuter',
                Icons.chat_bubble_outline_rounded,
                () => _chatWith(context, accepted.artisanUserId, r.id)),
            _ActionButton.filled('Travaux terminés', Icons.task_alt_rounded,
                () async {
              if (await _confirm(context, 'Confirmer la fin des travaux ?',
                  'Vous pourrez ensuite noter l’artisan.')) {
                cubit.markCompleted();
              }
            }),
          ],
          onOpenProfile: () => context.push('/artisans/${accepted.artisanId}'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            if (await _confirm(context, 'Annuler la mission ?',
                'L’artisan sera prévenu de l’annulation.')) {
              cubit.cancel();
            }
          },
          icon: const Icon(Icons.cancel_outlined, color: Palette.danger),
          label: const Text('Annuler la mission',
              style: TextStyle(
                  color: Palette.danger, fontWeight: FontWeight.w700)),
        ),
      ];
    }

    if (r.isCompleted && accepted != null) {
      return [
        const SectionTitle('Mission réalisée par'),
        const SizedBox(height: 8),
        _QuoteCard(
          quote: accepted,
          actions: [
            _ActionButton.outlined(
                'Discuter',
                Icons.chat_bubble_outline_rounded,
                () => _chatWith(context, accepted.artisanUserId, r.id)),
          ],
          onOpenProfile: () => context.push('/artisans/${accepted.artisanId}'),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Votre avis'),
        const SizedBox(height: 8),
        r.hasReview
            ? _ReviewDone(rating: r.reviewRating!, comment: r.reviewComment)
            : const _ReviewForm(),
      ];
    }

    return [
      const AppCard(
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: Palette.muted),
          SizedBox(width: 10),
          Expanded(
              child: Text('Cette demande est annulée.',
                  style: TextStyle(color: Palette.muted))),
        ]),
      ),
    ];
  }

  // ── Artisan ───────────────────────────────────────────────────────────────
  List<Widget> _artisanSection(BuildContext context, ServiceRequest r) {
    final cubit = context.read<RequestDetailCubit>();
    final mine = r.myQuote;

    if (mine == null) {
      if (!r.isPending) {
        return [
          const AppCard(
              child: Text('Cette demande n’accepte plus de devis.',
                  style: TextStyle(color: Palette.muted)))
        ];
      }
      return [
        SectionTitle(
            'Proposer un devis${r.quotesCount > 0 ? ' · ${r.quotesCount} déjà reçu${r.quotesCount > 1 ? 's' : ''}' : ''}'),
        const SizedBox(height: 8),
        const _QuoteForm(),
      ];
    }

    final chatButton = _ActionButton.outlined(
      'Discuter avec le client',
      Icons.chat_bubble_outline_rounded,
      () => _chatWith(context, r.clientId, r.id),
    );

    if (mine.isPending) {
      return [
        const SectionTitle('Votre devis'),
        const SizedBox(height: 8),
        _MyQuoteSummary(quote: mine),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: chatButton),
          const SizedBox(width: 8),
          Expanded(
            child:
                _ActionButton.outlined('Retirer', Icons.undo_rounded, () async {
              if (await _confirm(context, 'Retirer votre devis ?',
                  'Vous pourrez en proposer un nouveau tant que la demande est ouverte.')) {
                cubit.withdrawQuote(mine);
              }
            }, danger: true),
          ),
        ]),
      ];
    }

    if (mine.isAccepted) {
      return [
        const SectionTitle('Votre mission'),
        const SizedBox(height: 8),
        _MyQuoteSummary(quote: mine),
        const SizedBox(height: 10),
        chatButton,
        if (r.isActive) ...[
          const SizedBox(height: 8),
          _ActionButton.filled('Marquer comme terminée', Icons.task_alt_rounded,
              () async {
            if (await _confirm(context, 'Mission terminée ?',
                'Le client sera invité à confirmer et à vous noter.')) {
              cubit.markCompleted();
            }
          }),
        ],
        if (r.isCompleted) ...[
          const SizedBox(height: 18),
          const SectionTitle('Avis du client'),
          const SizedBox(height: 8),
          r.hasReview
              ? _ReviewDone(rating: r.reviewRating!, comment: r.reviewComment)
              : const AppCard(
                  child: Text('Le client n’a pas encore laissé d’avis.',
                      style: TextStyle(color: Palette.muted))),
        ],
      ];
    }

    return [
      const SectionTitle('Votre devis'),
      const SizedBox(height: 8),
      _MyQuoteSummary(quote: mine),
      const SizedBox(height: 8),
      const Text('Le client a retenu une autre proposition.',
          style: TextStyle(color: Palette.muted)),
    ];
  }
}

Future<bool> _confirm(
    BuildContext context, String title, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Palette.primary),
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _RequestHeader extends StatelessWidget {
  final ServiceRequest request;
  final bool asArtisan;
  const _RequestHeader({required this.request, required this.asArtisan});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final showPhone = asArtisan &&
        r.myQuote?.isAccepted == true &&
        (r.clientPhone ?? '').isNotEmpty;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: Palette.primarySoft,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(categoryIcon(r.categoryIcon),
                    color: Palette.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.categoryName ?? 'Service',
                    style: const TextStyle(
                        color: Palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              Flexible(child: Pill.requestStatus(r.status)),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.title,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink,
                  height: 1.25)),
          const SizedBox(height: 8),
          Text(r.description,
              style: const TextStyle(
                  fontSize: 14, color: Palette.text, height: 1.45)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _info(Icons.location_on_outlined,
              [r.city, if (r.address.isNotEmpty) r.address].join(' — ')),
          _info(Icons.schedule_rounded, 'Publiée ${Fmt.relative(r.createdAt)}'),
          if (asArtisan)
            _info(Icons.person_outline_rounded, r.clientName ?? 'Client'),
          if (showPhone)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: r.clientPhone!));
                showFeedback(context, 'Numéro copié');
              },
              child: _info(Icons.phone_outlined,
                  '${r.clientPhone}  (appuyer pour copier)'),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 16, color: Palette.muted),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Palette.muted))),
        ]),
      );
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final List<Widget> actions;
  final VoidCallback onOpenProfile;

  const _QuoteCard(
      {required this.quote,
      required this.actions,
      required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenProfile,
            child: Row(
              children: [
                Avatar(
                    name: q.artisanName ?? 'Artisan',
                    size: 44,
                    verified: q.artisanVerified),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.artisanName ?? 'Artisan',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: Palette.ink)),
                      const SizedBox(height: 2),
                      Row(children: [
                        if ((q.artisanSpecialty ?? '').isNotEmpty) ...[
                          Flexible(
                            child: Text(q.artisanSpecialty!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Palette.muted)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        StarRating(rating: q.artisanRating, size: 12),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Palette.faint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Montant',
                          style:
                              TextStyle(fontSize: 11.5, color: Palette.muted)),
                      Text(Fmt.fcfa(q.amount),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Palette.ink)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Délai',
                    style: TextStyle(fontSize: 11.5, color: Palette.muted)),
                Text('${q.estimatedDays} jour${q.estimatedDays > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink)),
              ]),
            ],
          ),
          if (q.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Palette.background,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('« ${q.message} »',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Palette.text,
                      fontStyle: FontStyle.italic)),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: actions[i]),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;

  const _ActionButton._(this.label, this.icon, this.onPressed,
      {this.filled = false, this.danger = false});

  factory _ActionButton.filled(
          String label, IconData icon, VoidCallback onPressed) =>
      _ActionButton._(label, icon, onPressed, filled: true);

  factory _ActionButton.outlined(
          String label, IconData icon, VoidCallback onPressed,
          {bool danger = false}) =>
      _ActionButton._(label, icon, onPressed, danger: danger);

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const padding = EdgeInsets.symmetric(vertical: 12, horizontal: 6);
    final text = Text(label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: text,
        style: FilledButton.styleFrom(
            backgroundColor: Palette.primary, padding: padding, shape: shape),
      );
    }
    final color = danger ? Palette.danger : Palette.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: text,
      style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: padding,
          shape: shape),
    );
  }
}

class _MyQuoteSummary extends StatelessWidget {
  final Quote quote;
  const _MyQuoteSummary({required this.quote});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(Fmt.fcfa(quote.amount),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Palette.ink))),
            Pill.quoteStatus(quote.status),
          ]),
          const SizedBox(height: 4),
          Text(
              'Délai annoncé : ${quote.estimatedDays} jour${quote.estimatedDays > 1 ? 's' : ''} · envoyé ${Fmt.relative(quote.createdAt)}',
              style: const TextStyle(fontSize: 12.5, color: Palette.muted)),
          if (quote.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('« ${quote.message} »',
                style: const TextStyle(
                    fontSize: 13,
                    color: Palette.text,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _QuoteForm extends StatefulWidget {
  const _QuoteForm();

  @override
  State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _days = TextEditingController(text: '1');
  final _message = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _days.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: _form,
        child: Column(
          children: [
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Montant', suffixText: 'FCFA'),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Montant requis'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Délai', suffixText: 'jours'),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Requis' : null,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _message,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Message au client (facultatif)',
                hintText: 'Matériel inclus, disponibilité, garantie...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  FocusScope.of(context).unfocus();
                  context.read<RequestDetailCubit>().submitQuote(
                        amount: double.parse(_amount.text),
                        days: int.parse(_days.text),
                        message: _message.text,
                      );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer le devis'),
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm();

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  int _rating = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comment s’est passée la mission ?',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Palette.ink)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                iconSize: 34,
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Palette.star),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
                hintText: 'Votre commentaire (facultatif)'),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0
                  ? null
                  : () => context
                      .read<RequestDetailCubit>()
                      .review(_rating, _comment.text),
              style: FilledButton.styleFrom(
                  backgroundColor: Palette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Publier mon avis'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDone extends StatelessWidget {
  final int rating;
  final String? comment;
  const _ReviewDone({required this.rating, this.comment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: List.generate(
                  5,
                  (i) => Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Palette.star))),
          if ((comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment!, style: const TextStyle(color: Palette.text)),
          ],
        ],
      ),
    );
  }
}
