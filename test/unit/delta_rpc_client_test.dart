// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:omega/core/network/delta_rpc_client.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late DeltaRpcClient client;

  setUp(() async {
    client = DeltaRpcClient();
    await client.start(); // seeds dev data
  });

  tearDown(() async {
    await client.stop();
  });

  // ── Account tests ──────────────────────────────────────────────────────────

  group('DeltaRpcClient – getAllAccountIds', () {
    test('returns a non-empty list after start()', () async {
      final ids = await client.getAllAccountIds();
      expect(ids, isNotEmpty);
    });

    test('returns list containing account id 1 (seeded)', () async {
      final ids = await client.getAllAccountIds();
      expect(ids, contains(1));
    });

    test('addAccount appends a new id to the list', () async {
      final before = await client.getAllAccountIds();
      final newId = await client.addAccount();
      final after = await client.getAllAccountIds();

      expect(after.length, before.length + 1);
      expect(after, contains(newId));
    });

    test('addAccount returns a positive integer id', () async {
      final id = await client.addAccount();
      expect(id, greaterThan(0));
    });
  });

  group('DeltaRpcClient – getAccountInfo', () {
    test('returns map with "addr" for seeded account 1', () async {
      final info = await client.getAccountInfo(1);
      expect(info['addr'], 'you@example.com');
    });

    test('returns map with "configured" true for seeded account 1', () async {
      final info = await client.getAccountInfo(1);
      expect(info['configured'], isTrue);
    });

    test('returns empty map for unknown account id', () async {
      final info = await client.getAccountInfo(9999);
      expect(info, isEmpty);
    });
  });

  // ── Chat list tests ────────────────────────────────────────────────────────

  group('DeltaRpcClient – getChatListIds', () {
    test('returns a non-empty list with default params', () async {
      final ids = await client.getChatListIds();
      expect(ids, isNotEmpty);
    });

    test('pinned chats appear first in the returned list', () async {
      // Chat 1 has visibility == 2 (pinned) in dev seed data
      final ids = await client.getChatListIds();
      expect(ids.first, 1);
    });

    test('archived-only returns empty list when no chats are archived',
        () async {
      // Seeded chats have visibility 1 (normal) or 2 (pinned) – not 0 (archived)
      final ids = await client.getChatListIds(archivedOnly: true);
      expect(ids, isEmpty);
    });

    test('archiving a chat moves it to archived-only result', () async {
      await client.setChatVisibility(2, 0); // archive chat 2
      final archived = await client.getChatListIds(archivedOnly: true);
      expect(archived, contains(2));
    });

    test('query filter returns only matching chats', () async {
      final ids = await client.getChatListIds(query: 'Alice');
      // Chat 1 is named "Alice Johnson"
      expect(ids, contains(1));
      // Chat 2 is "Engineering Team" – should not match
      expect(ids, isNot(contains(2)));
    });

    test('empty query returns all non-archived chats', () async {
      final withEmpty = await client.getChatListIds(query: '');
      final withNull = await client.getChatListIds();
      expect(withEmpty, withNull);
    });
  });

  // ── Message tests ──────────────────────────────────────────────────────────

  group('DeltaRpcClient – sendTextMessage', () {
    test('returns a positive message id', () async {
      final id = await client.sendTextMessage(chatId: 1, text: 'Hello');
      expect(id, greaterThan(0));
    });

    test('sent message appears in getMessages for that chat', () async {
      await client.sendTextMessage(chatId: 1, text: 'Unit test message');
      final messages = await client.getMessages(chatId: 1);
      final texts = messages.map((m) => m['text']).toList();
      expect(texts, contains('Unit test message'));
    });

    test('chat lastMessage is updated after sending', () async {
      await client.sendTextMessage(chatId: 1, text: 'Latest update');
      final chatInfo = await client.getChatInfo(1);
      expect(chatInfo['last_message'], 'Latest update');
    });

    test('messages for a new chat start empty then grow', () async {
      // Create a brand new chat to isolate
      final chatId = await client.createGroupChat(name: 'Test Only Group');
      final before = await client.getMessages(chatId: chatId);
      expect(before, isEmpty);

      await client.sendTextMessage(chatId: chatId, text: 'First');
      final after = await client.getMessages(chatId: chatId);
      expect(after.length, 1);
      expect(after.first['text'], 'First');
    });

    test('quoted message id is stored in the message map', () async {
      final msgId = await client.sendTextMessage(
        chatId: 1,
        text: 'Reply',
        quotedMessageId: 99,
      );
      final messages = await client.getMessages(chatId: 1);
      final reply = messages.firstWhere((m) => m['id'] == msgId);
      expect(reply['quoted_message_id'], 99);
    });
  });

  // ── Group chat tests ───────────────────────────────────────────────────────

  group('DeltaRpcClient – createGroupChat', () {
    test('returns a positive chat id', () async {
      final id = await client.createGroupChat(name: 'My Team');
      expect(id, greaterThan(0));
    });

    test('created group chat appears in getChatInfo', () async {
      final id = await client.createGroupChat(name: 'Alpha Squad');
      final info = await client.getChatInfo(id);
      expect(info['name'], 'Alpha Squad');
    });

    test('created group chat has type 120', () async {
      final id = await client.createGroupChat(name: 'Beta Squad');
      final info = await client.getChatInfo(id);
      expect(info['type'], 120);
    });

    test('verified group chat sets is_verified to true', () async {
      final id = await client.createGroupChat(
        name: 'Secure Group',
        verified: true,
      );
      final info = await client.getChatInfo(id);
      expect(info['is_verified'], isTrue);
    });

    test('unverified group chat has is_verified absent or false', () async {
      final id = await client.createGroupChat(
        name: 'Public Group',
        verified: false,
      );
      final info = await client.getChatInfo(id);
      // The seed does not set is_verified for non-verified groups,
      // so it is either false or null-ish.
      expect(info['is_verified'] == true, isFalse);
    });

    test('addContactToChat adds contact id to member list', () async {
      final chatId = await client.createGroupChat(name: 'New Group');
      await client.addContactToChat(chatId, 1);
      final info = await client.getChatInfo(chatId);
      final members = info['contact_ids'] as List;
      expect(members, contains(1));
    });
  });

  // ── Contact / block tests ──────────────────────────────────────────────────

  group('DeltaRpcClient – blockContact', () {
    test('blockContact sets blocked=true in contact info', () async {
      await client.blockContact(1);
      final info = await client.getContactInfo(1);
      expect(info['blocked'], isTrue);
    });

    test('unblockContact sets blocked=false after being blocked', () async {
      await client.blockContact(2);
      await client.unblockContact(2);
      final info = await client.getContactInfo(2);
      expect(info['blocked'], isFalse);
    });

    test('getContacts(blockedOnly: true) returns only blocked contacts',
        () async {
      // Block contact 1 and verify
      await client.blockContact(1);
      final blockedIds = await client.getContacts(blockedOnly: true);
      expect(blockedIds, contains(1));
      // Contact 2 is not blocked yet
      expect(blockedIds, isNot(contains(2)));
    });

    test('blocking a nonexistent contact is a no-op (no exception)', () async {
      // Should complete without throwing
      await expectLater(
        client.blockContact(9999),
        completes,
      );
    });
  });

  group('DeltaRpcClient – createContact', () {
    test('returns positive contact id', () async {
      final id = await client.createContact(addr: 'new@example.com');
      expect(id, greaterThan(0));
    });

    test('created contact appears in getContactInfo', () async {
      final id = await client.createContact(
        addr: 'test@example.com',
        name: 'Test User',
      );
      final info = await client.getContactInfo(id);
      expect(info['addr'], 'test@example.com');
      expect(info['display_name'], 'Test User');
    });

    test('deleteContact removes the contact', () async {
      final id = await client.createContact(addr: 'del@example.com');
      await client.deleteContact(id);
      final info = await client.getContactInfo(id);
      expect(info, isEmpty);
    });
  });

  // ── Misc ───────────────────────────────────────────────────────────────────

  group('DeltaRpcClient – marknoticedChat', () {
    test('sets unread count to 0 for the specified chat', () async {
      // Chat 1 has unread = 2 from seed data
      await client.marknoticedChat(1);
      final info = await client.getChatInfo(1);
      expect(info['unread'], 0);
    });
  });

  group('DeltaRpcClient – deleteChat', () {
    test('removes chat from getChatListIds after deletion', () async {
      await client.deleteChat(3);
      final ids = await client.getChatListIds();
      expect(ids, isNot(contains(3)));
    });

    test('getChatInfo returns empty map for deleted chat', () async {
      await client.deleteChat(2);
      final info = await client.getChatInfo(2);
      expect(info, isEmpty);
    });
  });

  group('DeltaRpcClient – start/stop idempotency', () {
    test('calling start() twice does not throw', () async {
      await expectLater(client.start(), completes);
    });

    test('calling stop() then start() re-enables the client', () async {
      await client.stop();
      await client.start();
      final ids = await client.getAllAccountIds();
      // After restart the in-memory map is still in scope
      expect(ids, isNotEmpty);
    });
  });
}
