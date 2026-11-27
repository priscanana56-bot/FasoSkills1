import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/message.dart';
import '../bloc/conversations_cubit.dart';

/// Conversation list of the logged-in user. The API only returns the user's own
/// conversations and tells who the *other* participant is, so a client only sees
/// artisans here and an artisan only sees clients.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ConversationsCubit>().load(silent: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final me = auth is Authenticated ? auth.user : null;
    final isArtisan = me?.isArtisan ?? false;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Discussions'),
      body: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          if (state.status == ConversationsStatus.loading &&
              state.conversations.isEmpty) {
            return const LoadingView();
          }
          if (state.status == ConversationsStatus.error) {
            return ErrorState(
              message: state.error ?? 'Erreur réseau',
              onRetry: () => context.read<ConversationsCubit>().load(),
            );
          }
          if (state.conversations.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: 'Aucune discussion',
              message: isArtisan
                  ? 'Les clients qui vous contactent apparaîtront ici.'
                  : 'Contactez un artisan depuis son profil ou depuis un devis pour démarrer une discussion.',
              actionLabel: isArtisan ? null : 'Trouver un artisan',
              onAction: isArtisan ? null : () => context.push('/artisans'),
            );
          }

          final query = _search.text.trim().toLowerCase();
          final list = state.conversations.where((c) {
            if (query.isEmpty) return true;
            final peer = c.peer;
            return (peer?.fullName.toLowerCase().contains(query) ?? false) ||
                (peer?.subtitle.toLowerCase().contains(query) ?? false) ||
                c.lastMessage.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                context.read<ConversationsCubit>().load(silent: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: isArtisan
                        ? 'Rechercher un client...'
                        : 'Rechercher un artisan...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Palette.muted),
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
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                        child: Text('Aucun résultat',
                            style: TextStyle(color: Palette.muted))),
                  ),
                for (final c in list) ...[
                  _ConversationTile(conversation: c, myId: me?.id ?? ''),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String myId;

  const _ConversationTile({required this.conversation, required this.myId});

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final unread = conversation.unreadCount;
    final fromMe = conversation.lastSenderId == myId;
    final preview = conversation.lastMessage.isEmpty
        ? 'Nouvelle discussion'
        : (fromMe
            ? 'Vous : ${conversation.lastMessage}'
            : conversation.lastMessage);

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/chat/${conversation.id}'),
      child: Row(
        children: [
          Avatar(
              name: peer?.fullName ?? '?',
              size: 50,
              verified: peer?.isVerified ?? false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        peer?.fullName ?? 'Utilisateur',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Palette.ink),
                      ),
                    ),
                    Text(
                      Fmt.chatTime(conversation.lastMessageAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: unread > 0 ? Palette.primary : Palette.faint,
                        fontWeight:
                            unread > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(peer?.subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Palette.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: unread > 0 ? Palette.ink : Palette.muted,
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: Palette.primary,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
