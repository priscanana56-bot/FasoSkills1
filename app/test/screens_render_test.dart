// Renders every client and artisan screen with realistic data on small and
// regular phone sizes. Any layout overflow makes the test fail.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/di/injection.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/core/network/ws_client.dart';
import 'package:app/features/agent/presentation/bloc/artisan_work_cubit.dart';
import 'package:app/features/agent/presentation/screens/agent_home_screen.dart';
import 'package:app/features/agent/presentation/screens/agent_missions_screen.dart';
import 'package:app/features/agent/presentation/screens/agent_profile_screen.dart';
import 'package:app/features/agent/presentation/screens/agent_requests_screen.dart';
import 'package:app/features/artisans/domain/models/artisan.dart';
import 'package:app/features/artisans/domain/models/artisan_stats.dart';
import 'package:app/features/artisans/domain/repositories/artisan_repository.dart';
import 'package:app/features/artisans/presentation/bloc/artisan_list_bloc.dart';
import 'package:app/features/artisans/presentation/screens/artisan_profile_screen.dart';
import 'package:app/features/artisans/presentation/screens/artisans_screen.dart';
import 'package:app/features/artisans/presentation/screens/home_screen.dart';
import 'package:app/features/auth/domain/models/user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/screens/profile_screen.dart';
import 'package:app/features/chat/domain/models/message.dart';
import 'package:app/features/chat/domain/repositories/chat_repository.dart';
import 'package:app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:app/features/chat/presentation/bloc/conversations_cubit.dart';
import 'package:app/features/chat/presentation/screens/chat_screen.dart';
import 'package:app/features/chat/presentation/screens/conversations_screen.dart';
import 'package:app/features/notifications/domain/models/app_notification.dart';
import 'package:app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:app/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:app/features/requests/domain/models/quote.dart';
import 'package:app/features/requests/domain/models/service_request.dart';
import 'package:app/features/requests/domain/repositories/request_repository.dart';
import 'package:app/features/requests/presentation/bloc/request_bloc.dart';
import 'package:app/features/requests/presentation/screens/my_requests_screen.dart';
import 'package:app/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:app/features/requests/presentation/screens/request_quote_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockWs extends Mock implements WebSocketClient {}

// ── Fixtures (long names on purpose, to stress layouts) ────────────────────
final now = DateTime.now();
const plomberie =
    Category(id: 'c1', name: 'Plomberie', slug: 'plomberie', icon: 'plumbing');
const electricite = Category(
    id: 'c2',
    name: 'Électricité',
    slug: 'electricite',
    icon: 'electrical_services');
const clientUser = User(
    id: 'u-client',
    email: 'aminata.ouedraogo@fasoskills.bf',
    fullName: 'Aminata Ouédraogo Kaboré',
    role: 'client',
    phone: '+22670111111');
const artisanUser = User(
    id: 'u-artisan',
    email: 'moussa@fasoskills.bf',
    fullName: 'Moussa Kaboré',
    role: 'artisan',
    artisanProfileId: 'a1');

const artisan = Artisan(
  id: 'a1',
  userId: 'u-artisan',
  fullName: 'Moussa Kaboré Sawadogo Ouédraogo',
  specialty: 'Plombier Sanitaire & Chauffe-eau solaire',
  city: 'Bobo-Dioulasso',
  category: plomberie,
  experienceYears: 12,
  bio:
      'Artisan qualifié avec 12 ans d’expérience en dépannage et rénovation de réseaux sanitaires.',
  availability: 'Disponible le week-end',
  rating: 4.8,
  reviewsCount: 124,
  completedJobs: 153,
  isVerified: true,
);

final quotePending = Quote(
  id: 'q1',
  requestId: 'r1',
  artisanId: 'a1',
  artisanName: 'Moussa Kaboré Sawadogo Ouédraogo',
  artisanUserId: 'u-artisan',
  artisanSpecialty: 'Plombier Sanitaire & Chauffe-eau solaire',
  artisanRating: 4.8,
  artisanVerified: true,
  amount: 1250000,
  estimatedDays: 12,
  message:
      'Je peux intervenir dès ce soir avec toutes les pièces de rechange nécessaires.',
  createdAt: now,
);

ServiceRequest request(String status,
        {Quote? accepted, Quote? mine, int quotes = 3, int? review}) =>
    ServiceRequest(
      id: 'r1',
      clientId: 'u-client',
      categoryId: 'c1',
      title:
          'Fuite d’eau importante sous l’évier de la cuisine qui inonde tout',
      description:
          'Une fuite permanente sous l’évier inonde la cuisine depuis hier soir. Besoin d’intervention rapide.',
      city: 'Ouagadougou',
      address: 'Ouaga 2000, secteur 15, villa 42 près du rond-point',
      status: status,
      createdAt: now.subtract(const Duration(hours: 3)),
      clientName: 'Aminata Ouédraogo Kaboré',
      clientPhone: '+22670111111',
      categoryName: 'Plomberie',
      categoryIcon: 'plumbing',
      quotesCount: quotes,
      acceptedQuote: accepted,
      myQuote: mine,
      reviewRating: review,
      reviewComment: review != null
          ? 'Travail impeccable et ponctuel, je recommande vivement !'
          : null,
    );

final acceptedQuote = Quote(
  id: 'q1',
  requestId: 'r1',
  artisanId: 'a1',
  artisanName: 'Moussa Kaboré Sawadogo',
  artisanUserId: 'u-artisan',
  amount: 85000,
  estimatedDays: 2,
  status: 'accepted',
  createdAt: now,
);

final conversation = ChatConversation(
  id: 'conv1',
  peer: const ChatPeer(
      id: 'u-artisan',
      fullName: 'Moussa Kaboré Sawadogo Ouédraogo',
      role: 'artisan',
      artisanProfileId: 'a1',
      specialty: 'Plombier Sanitaire & Chauffe-eau solaire',
      city: 'Bobo-Dioulasso',
      isVerified: true),
  lastMessage:
      'Bonjour, je peux passer vers 16h avec le matériel pour remplacer le siphon et les joints.',
  lastSenderId: 'u-artisan',
  lastMessageAt: now,
  unreadCount: 128,
);

// ── Fakes ────────────────────────────────────────────────────────────────
class FakeChatRepo implements ChatRepository {
  @override
  Future<Result<List<ChatConversation>>> getConversations() async =>
      Success([conversation, conversation.copyWith(unreadCount: 0)]);
  @override
  Future<Result<ChatConversation>> getConversation(String id) async =>
      Success(conversation);
  @override
  Future<Result<List<ChatMessage>>> getMessages(String id) async => Success([
        ChatMessage(
            id: 'm1',
            conversationId: 'conv1',
            senderId: 'u-artisan',
            text: 'Bonjour, je peux passer vers 16h.',
            createdAt: now.subtract(const Duration(days: 1))),
        ChatMessage(
            id: 'm2',
            conversationId: 'conv1',
            senderId: 'u-client',
            text: 'Parfait, merci beaucoup ! ' * 8,
            createdAt: now,
            isRead: true),
      ]);
  @override
  Future<Result<ChatMessage>> sendMessage(
          {required String conversationId, required String text}) async =>
      Success(ChatMessage(
          id: 'm3',
          conversationId: conversationId,
          senderId: 'u-client',
          text: text));
  @override
  Future<Result<void>> markRead(String conversationId) async =>
      const Success(null);
  @override
  Future<Result<ChatConversation>> startOrGetConversation(
          {required String recipientId,
          String? initialMessage,
          String? requestId}) async =>
      Success(conversation);
}

class FakeRequestRepo implements RequestRepository {
  ServiceRequest detail = request('pending');
  @override
  Future<Result<List<ServiceRequest>>> getMyRequests() async => Success([
        request('pending'),
        request('in_progress', accepted: acceptedQuote),
        request('completed', accepted: acceptedQuote),
        request('cancelled', quotes: 0)
      ]);
  @override
  Future<Result<ServiceRequest>> getRequestById(String requestId) async =>
      Success(detail);
  @override
  Future<Result<List<Quote>>> getQuotesForRequest(String requestId) async =>
      Success([quotePending, quotePending]);
  @override
  Future<Result<List<ServiceRequest>>> getOpenRequests(
          {bool allCategories = false, String? search}) async =>
      Success([request('pending'), request('pending', mine: quotePending)]);
  @override
  Future<Result<List<ServiceRequest>>> getMissions() async => Success([
        request('in_progress', accepted: acceptedQuote),
        request('completed', accepted: acceptedQuote, review: 5)
      ]);
  @override
  Future<Result<List<Quote>>> getMyQuotes() async => Success([
        Quote(
            id: 'q9',
            requestId: 'r1',
            artisanId: 'a1',
            amount: 1250000,
            estimatedDays: 3,
            createdAt: now,
            request: request('pending')),
      ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeArtisanRepo implements ArtisanRepository {
  @override
  Future<Result<List<Category>>> getCategories() async => const Success([
        plomberie,
        electricite,
        plomberie,
        electricite,
        plomberie,
        electricite,
        plomberie
      ]);
  @override
  Future<Result<List<Artisan>>> getArtisans(
          {int page = 1,
          int limit = 10,
          String? search,
          String? city,
          String? categoryId}) async =>
      const Success([artisan, artisan, artisan]);
  @override
  Future<List<Artisan>?> getCachedArtisans() async => null;
  @override
  Future<Result<Artisan>> getArtisanById(String id) async =>
      const Success(artisan);
  @override
  Future<Result<List<ArtisanReview>>> getReviews(String artisanId) async =>
      Success([
        ArtisanReview(
            id: 'rv1',
            clientName: 'Aminata Ouédraogo Kaboré Sawadogo',
            rating: 5,
            comment: 'Excellent travail ! ' * 6,
            createdAt: now),
      ]);
  @override
  Future<Result<Artisan>> getMyProfile() async => const Success(artisan);
  @override
  Future<Result<ArtisanStats>> getMyStats() async => const Success(ArtisanStats(
      openRequests: 128,
      pendingQuotes: 42,
      activeMissions: 7,
      completedJobs: 1530,
      rating: 4.8,
      reviewsCount: 124,
      earnings: 125000000,
      verificationStatus: 'pending',
      profileStatus: 'incomplete'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationRepo implements NotificationRepository {
  @override
  Future<Result<NotificationPage>> getNotifications() async =>
      Success(NotificationPage([
        AppNotification(
            id: 'n1',
            type: 'quote:received',
            title: 'Nouveau devis reçu de la part d’un artisan vérifié',
            body:
                'Moussa Kaboré propose 1 250 000 FCFA pour « Fuite d’eau importante sous l’évier ».',
            createdAt: now),
        AppNotification(
            id: 'n2',
            type: 'quote:accepted',
            title: 'Devis accepté 🎉',
            isRead: true,
            createdAt: now),
      ], 1));
  @override
  Future<Result<void>> markRead(String id) async => const Success(null);
  @override
  Future<Result<void>> markAllRead() async => const Success(null);
}

late FakeRequestRepo requestRepo;

void main() {
  setUpAll(() async {
    await getIt.reset();
    final ws = MockWs();
    when(() => ws.eventStream).thenAnswer((_) => const Stream.empty());
    when(() => ws.on(any())).thenAnswer((_) => const Stream.empty());
    when(() => ws.joinRoom(any())).thenReturn(null);
    when(() => ws.leaveRoom(any())).thenReturn(null);
    requestRepo = FakeRequestRepo();
    getIt
      ..registerSingleton<WebSocketClient>(ws)
      ..registerSingleton<ChatRepository>(FakeChatRepo())
      ..registerSingleton<RequestRepository>(requestRepo)
      ..registerSingleton<ArtisanRepository>(FakeArtisanRepo())
      ..registerSingleton<NotificationRepository>(FakeNotificationRepo())
      ..registerFactory<ChatBloc>(
          () => ChatBloc(repository: getIt(), wsClient: getIt()))
      ..registerFactory<ArtisanListBloc>(
          () => ArtisanListBloc(repository: getIt()));
  });

  Future<void> pump(WidgetTester tester, Widget screen,
      {required User user, Size size = const Size(375, 667)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = AuthBloc(authRepository: MockAuthRepository())
      ..add(UserUpdated(user));
    final work = ArtisanWorkCubit(
        requestRepository: getIt(),
        artisanRepository: getIt(),
        wsClient: getIt());
    if (user.isArtisan) await work.loadAll();
    final requests = RequestBloc(repository: getIt())..add(LoadMyRequests());

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: auth),
        BlocProvider(create: (_) => ArtisanListBloc(repository: getIt())),
        BlocProvider.value(value: requests),
        BlocProvider(
            create: (_) =>
                ConversationsCubit(repository: getIt(), wsClient: getIt())
                  ..load()),
        BlocProvider(
            create: (_) =>
                NotificationsCubit(repository: getIt(), wsClient: getIt())
                  ..load()),
        BlocProvider.value(value: work),
      ],
      child: MaterialApp(home: screen),
    ));
    final original = FlutterError.onError;
    final problems = <String>[];
    FlutterError.onError = (details) {
      final where = RegExp(r'lib/[a-z_/]+\.dart:\d+')
              .firstMatch(details.toString())
              ?.group(0) ??
          '?';
      problems.add('${details.exceptionAsString().split('\n').first} @ $where');
    };
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    FlutterError.onError = original;
    expect(problems, isEmpty, reason: problems.toSet().join('\n'));
  }

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    group('Client screens $label', () {
      testWidgets('home',
          (t) => pump(t, const HomeScreen(), user: clientUser, size: size));
      testWidgets('explorer',
          (t) => pump(t, const ArtisansScreen(), user: clientUser, size: size));
      testWidgets(
          'artisan profile',
          (t) => pump(t, const ArtisanProfileScreen(artisanId: 'a1'),
              user: clientUser, size: size));
      testWidgets(
          'my requests',
          (t) =>
              pump(t, const MyRequestsScreen(), user: clientUser, size: size));
      testWidgets(
          'new request',
          (t) => pump(t, const RequestQuoteScreen(),
              user: clientUser, size: size));
      testWidgets(
          'conversations',
          (t) => pump(t, const ConversationsScreen(),
              user: clientUser, size: size));
      testWidgets(
          'chat',
          (t) => pump(t, const ChatScreen(conversationId: 'conv1'),
              user: clientUser, size: size));
      testWidgets(
          'notifications',
          (t) => pump(t, const NotificationsScreen(),
              user: clientUser, size: size));
      testWidgets('profile',
          (t) => pump(t, const ProfileScreen(), user: clientUser, size: size));
      for (final status in [
        'pending',
        'in_progress',
        'completed',
        'completed-reviewed',
        'cancelled'
      ]) {
        testWidgets('request detail ($status)', (t) async {
          requestRepo.detail = switch (status) {
            'pending' => request('pending'),
            'completed-reviewed' =>
              request('completed', accepted: acceptedQuote, review: 4),
            _ => request(status, accepted: acceptedQuote),
          };
          await pump(t, const RequestDetailScreen(requestId: 'r1'),
              user: clientUser, size: size);
        });
      }
    });

    group('Artisan screens $label', () {
      testWidgets(
          'home',
          (t) =>
              pump(t, const AgentHomeScreen(), user: artisanUser, size: size));
      testWidgets(
          'requests',
          (t) => pump(t, const AgentRequestsScreen(),
              user: artisanUser, size: size));
      testWidgets(
          'missions',
          (t) => pump(t, const AgentMissionsScreen(),
              user: artisanUser, size: size));
      testWidgets(
          'profile',
          (t) => pump(t, const AgentProfileScreen(),
              user: artisanUser, size: size));
      testWidgets(
          'conversations',
          (t) => pump(t, const ConversationsScreen(),
              user: artisanUser, size: size));
      for (final c in [
        ('no quote yet', request('pending', quotes: 0)),
        ('quote pending', request('pending', mine: quotePending)),
        (
          'mission active',
          request('in_progress', mine: acceptedQuote, accepted: acceptedQuote)
        ),
        (
          'mission done',
          request('completed',
              mine: acceptedQuote, accepted: acceptedQuote, review: 5)
        ),
      ]) {
        testWidgets('request detail (${c.$1})', (t) async {
          requestRepo.detail = c.$2;
          await pump(
              t, const RequestDetailScreen(requestId: 'r1', asArtisan: true),
              user: artisanUser, size: size);
        });
      }
    });
  }
}
