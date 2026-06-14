// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omega/app/theme/app_theme.dart';
import 'package:omega/features/chat_list/presentation/providers/chat_list_provider.dart';
import 'package:omega/features/chat_list/presentation/screens/chat_list_screen.dart';
import 'package:omega/shared/models/chat.dart';

// ---------------------------------------------------------------------------
// Fake notifier that serves a fixed ChatListState
// ---------------------------------------------------------------------------

class FakeChatListNotifier extends ChatList {
  final ChatListState _fixedState;

  FakeChatListNotifier(this._fixedState);

  @override
  ChatListState build() => _fixedState;

  @override
  Future<void> refresh() async {
    // No-op in tests – avoids hitting real RPC
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Minimal GoRouter wrapping [ChatListScreen] so context.go() works.
GoRouter _router() {
  return GoRouter(
    initialLocation: '/chats',
    routes: [
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':chatId',
            builder: (_, state) => Scaffold(
              body: Text('Chat ${state.pathParameters["chatId"]}'),
            ),
          ),
          GoRoute(
            path: 'group/create',
            builder: (_, __) => const Scaffold(body: Text('Group Create')),
          ),
          GoRoute(
            path: 'starred',
            builder: (_, __) => const Scaffold(body: Text('Starred')),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Global Search')),
      ),
      GoRoute(
        path: '/contacts',
        builder: (_, __) => const Scaffold(body: Text('Contacts')),
      ),
    ],
  );
}

Widget _buildApp(ChatListState fakeState) {
  return ProviderScope(
    overrides: [
      // Override the generated chatListProvider with our fake notifier
      chatListProvider.overrideWith(() => FakeChatListNotifier(fakeState)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _router(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Sample data factories
// ---------------------------------------------------------------------------

Chat _makeChat({
  int id = 1,
  String name = 'Test User',
  ChatType type = ChatType.single,
  int unreadCount = 0,
  bool isMuted = false,
  bool isVerified = false,
  ChatVisibility visibility = ChatVisibility.normal,
  String? lastMessage,
}) {
  return Chat(
    id: id,
    name: name,
    type: type,
    unreadCount: unreadCount,
    isMuted: isMuted,
    isVerified: isVerified,
    visibility: visibility,
    lastMessage: lastMessage,
    lastMessageTime: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChatListScreen – rendering', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      final loadingState = const ChatListState(isLoading: true);
      await tester.pumpWidget(_buildApp(loadingState));
      await tester.pump(); // let first frame render

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows AppBar with title "Omega"', (tester) async {
      final state = const ChatListState();
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Omega'), findsOneWidget);
    });

    testWidgets('shows search icon in AppBar', (tester) async {
      final state = const ChatListState();
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('shows FAB with chat_bubble_outline icon', (tester) async {
      final state = const ChatListState();
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });

  group('ChatListScreen – empty state', () {
    testWidgets('shows "No chats yet" when chat list is empty', (tester) async {
      final state = const ChatListState(chats: [], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No chats yet'), findsOneWidget);
    });

    testWidgets('shows hint text in empty state', (tester) async {
      final state = const ChatListState(chats: [], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(
        find.text('Start a conversation by tapping +'),
        findsOneWidget,
      );
    });

    testWidgets('shows large icon in empty state', (tester) async {
      final state = const ChatListState(chats: [], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      // The empty-state widget has a large chat_bubble_outline icon
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsWidgets);
    });
  });

  group('ChatListScreen – chat tiles', () {
    testWidgets('renders chat tile with chat name', (tester) async {
      final chat = _makeChat(id: 1, name: 'Alice Johnson');
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Alice Johnson'), findsOneWidget);
    });

    testWidgets('renders unread badge when unreadCount > 0', (tester) async {
      final chat = _makeChat(id: 1, name: 'Bob', unreadCount: 5);
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      // The badge text should show the count
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ when unread count exceeds 99', (tester) async {
      final chat = _makeChat(id: 1, name: 'Carol', unreadCount: 150);
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('does NOT render unread badge when unreadCount is 0',
        (tester) async {
      final chat = _makeChat(id: 1, name: 'Dave', unreadCount: 0);
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      // No badge text containing a digit should appear
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders last message snippet in subtitle', (tester) async {
      final chat =
          _makeChat(id: 1, name: 'Eve', lastMessage: 'See you tomorrow!');
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('See you tomorrow!'), findsOneWidget);
    });

    testWidgets('renders mute icon for muted chat', (tester) async {
      final chat = _makeChat(id: 1, name: 'Frank', isMuted: true);
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_off_rounded), findsWidgets);
    });

    testWidgets('renders verified icon for verified chat in title row',
        (tester) async {
      final chat = _makeChat(id: 1, name: 'Grace', isVerified: true);
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified_rounded), findsWidgets);
    });

    testWidgets('renders multiple chat tiles for multiple chats', (tester) async {
      final chats = [
        _makeChat(id: 1, name: 'Alice'),
        _makeChat(id: 2, name: 'Bob'),
        _makeChat(id: 3, name: 'Carol'),
      ];
      final state = ChatListState(chats: chats, isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });
  });

  group('ChatListScreen – archived banner', () {
    testWidgets('shows archived banner when archived chats exist', (tester) async {
      final archivedChat = _makeChat(
        id: 99,
        name: 'Old Chat',
        visibility: ChatVisibility.archived,
      );
      final state = ChatListState(
        chats: [],
        archivedChats: [archivedChat],
        isLoading: false,
      );
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Archived'), findsOneWidget);
    });
  });

  group('ChatListScreen – error state', () {
    testWidgets('shows error message when state has an error', (tester) async {
      final state =
          const ChatListState(isLoading: false, error: 'Connection failed');
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('shows Retry button on error', (tester) async {
      final state =
          const ChatListState(isLoading: false, error: 'Network error');
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('ChatListScreen – pull-to-refresh', () {
    testWidgets('RefreshIndicator is present in the chat list', (tester) async {
      final chat = _makeChat(id: 1, name: 'Alice');
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('fling down triggers pull-to-refresh without throwing',
        (tester) async {
      final chat = _makeChat(id: 1, name: 'Alice');
      final state = ChatListState(chats: [chat], isLoading: false);
      await tester.pumpWidget(_buildApp(state));
      await tester.pumpAndSettle();

      // Fling on the ListView to trigger the RefreshIndicator
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        800,
      );
      await tester.pumpAndSettle();

      // If we reach here without exception the refresh callback was invoked
      // and completed without error.
    });
  });
}
