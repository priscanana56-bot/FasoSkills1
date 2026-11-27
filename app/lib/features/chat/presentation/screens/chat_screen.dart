import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/conversations_cubit.dart';

/// One conversation, identical for clients and artisans: messages are aligned
/// by sender id, and the header always shows the other participant.
class ChatScreen extends StatelessWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>()..add(LoadMessages(conversationId)),
      child: _ChatView(conversationId: conversationId),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String conversationId;
  const _ChatView({required this.conversationId});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ChatPeer? _peer;
  late final ConversationsCubit _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = context.read<ConversationsCubit>();
    _conversations.setOpenConversation(widget.conversationId);
    _peer = _conversations.byId(widget.conversationId)?.peer;
    if (_peer == null) _fetchPeer();
  }

  Future<void> _fetchPeer() async {
    final result =
        await getIt<ChatRepository>().getConversation(widget.conversationId);
    if (!mounted) return;
    setState(() => _peer = result.dataOrNull?.peer);
  }

  @override
  void dispose() {
    _conversations.setOpenConversation(null);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send(String myId) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(SendMessageSubmitted(
        conversationId: widget.conversationId, text: text, senderId: myId));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final me = auth is Authenticated ? auth.user : null;
    final myId = me?.id ?? '';
    final peer = _peer;
    final canOpenProfile =
        me?.isClient == true && peer?.artisanProfileId != null;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        title: InkWell(
          onTap: canOpenProfile
              ? () => context.push('/artisans/${peer!.artisanProfileId}')
              : null,
          child: Row(
            children: [
              Avatar(
                  name: peer?.fullName ?? '?',
                  size: 38,
                  verified: peer?.isVerified ?? false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(peer?.fullName ?? 'Discussion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Palette.ink)),
                    if (peer != null)
                      Text(peer.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Palette.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (canOpenProfile)
            IconButton(
              tooltip: 'Voir le profil',
              icon: const Icon(Icons.person_search_rounded,
                  color: Palette.primary),
              onPressed: () =>
                  context.push('/artisans/${peer!.artisanProfileId}'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  _scrollToBottom();
                  if (state.lastSent != null) {
                    _conversations.onMessageSent(state.lastSent!);
                  }
                }
              },
              builder: (context, state) {
                if (state is ChatLoading || state is ChatInitial) {
                  return const LoadingView();
                }
                if (state is ChatError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => context
                        .read<ChatBloc>()
                        .add(LoadMessages(widget.conversationId)),
                  );
                }
                final loaded = state as ChatLoaded;
                if (loaded.messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.waving_hand_rounded,
                    title: 'Démarrez la discussion',
                    message: peer == null
                        ? 'Écrivez votre premier message.'
                        : 'Écrivez votre premier message à ${peer.fullName}.',
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: loaded.messages.length,
                  itemBuilder: (context, i) {
                    final m = loaded.messages[i];
                    final previous = i > 0 ? loaded.messages[i - 1] : null;
                    final showDay = previous == null ||
                        !_sameDay(previous.createdAt, m.createdAt);
                    return Column(
                      children: [
                        if (showDay) _DayDivider(date: m.createdAt),
                        _Bubble(
                          message: m,
                          mine: m.senderId == myId,
                          pending: loaded.pendingIds.contains(m.id),
                          failed: loaded.failedIds.contains(m.id),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(controller: _input, onSend: () => _send(myId)),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

class _DayDivider extends StatelessWidget {
  final DateTime? date;
  const _DayDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date == null) {
      label = '';
    } else if (date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day) {
      label = "Aujourd'hui";
    } else {
      label = Fmt.chatTime(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12)),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Palette.muted,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool pending;
  final bool failed;

  const _Bubble(
      {required this.message,
      required this.mine,
      this.pending = false,
      this.failed = false});

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt != null
        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
          decoration: BoxDecoration(
            color: failed
                ? Palette.dangerSoft
                : (mine ? Palette.primary : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: mine ? null : Border.all(color: Palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.3,
                      color: mine && !failed ? Colors.white : Palette.ink),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    failed ? 'Échec de l’envoi' : time,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: failed
                          ? Palette.danger
                          : (mine ? Colors.white70 : Palette.faint),
                    ),
                  ),
                  if (mine && !failed) ...[
                    const SizedBox(width: 4),
                    Icon(
                      pending
                          ? Icons.schedule_rounded
                          : (message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded),
                      size: 13,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  filled: true,
                  fillColor: Palette.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: Palette.primary,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
