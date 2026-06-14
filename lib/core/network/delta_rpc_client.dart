import 'dart:async';


import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/logger.dart';


part 'delta_rpc_client.g.dart';

/// Abstraction over the DeltaChat JSON-RPC interface.
/// Production: spawns deltachat-rpc-server via dart:io Process, communicates over stdio.
/// This layer is swappable: same interface whether talking to a local RPC process,
/// a remote WebSocket, or a mock for testing.
class DeltaRpcClient {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  int _requestId = 0;
  final _pending = <int, Completer<dynamic>>{};

  // Simulated in-memory state for development (replaces real RPC process)
  final _accounts = <int, Map<String, dynamic>>{};
  final _chats = <int, Map<String, dynamic>>{};
  final _messages = <int, List<Map<String, dynamic>>>{};
  final _contacts = <int, Map<String, dynamic>>{};
  bool _isStarted = false;

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    AppLogger.i('DeltaRpcClient started (dev mode)');
    _seedDevData();
  }

  Future<void> stop() async {
    _isStarted = false;
    AppLogger.i('DeltaRpcClient stopped');
  }

  void _seedDevData() {
    _accounts[1] = {
      'id': 1,
      'addr': 'you@example.com',
      'display_name': 'You',
      'configured': true,
      'color': '#2B5BE8',
    };

    _contacts[1] = {'id': 1, 'addr': 'alice@example.com', 'display_name': 'Alice Johnson', 'is_verified': true};
    _contacts[2] = {'id': 2, 'addr': 'bob@example.com', 'display_name': 'Bob Smith'};
    _contacts[3] = {'id': 3, 'addr': 'carol@example.com', 'display_name': 'Carol White', 'is_verified': true};

    _chats[1] = {
      'id': 1, 'name': 'Alice Johnson', 'type': 100, 'contact_ids': [1],
      'last_message': 'See you tomorrow!', 'last_message_time': DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch ~/ 1000,
      'unread': 2, 'is_verified': true, 'visibility': 2,
    };
    _chats[2] = {
      'id': 2, 'name': 'Engineering Team', 'type': 120, 'contact_ids': [1, 2, 3],
      'last_message': 'Bob: Deploy is ready', 'last_message_time': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'unread': 5,
    };
    _chats[3] = {
      'id': 3, 'name': 'Bob Smith', 'type': 100, 'contact_ids': [2],
      'last_message': 'Thanks!', 'last_message_time': DateTime.now().subtract(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 1000,
      'unread': 0, 'muted': true,
    };

    _messages[1] = [
      {'id': 1, 'chat_id': 1, 'from': 0, 'type': 10, 'text': 'Hey! Are you coming to the meeting tomorrow?', 'ts': DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000, 'is_outgoing': true, 'state': 3},
      {'id': 2, 'chat_id': 1, 'from': 1, 'type': 10, 'text': 'Yes! What time?', 'ts': DateTime.now().subtract(const Duration(minutes: 8)).millisecondsSinceEpoch ~/ 1000, 'is_outgoing': false, 'state': 2},
      {'id': 3, 'chat_id': 1, 'from': 0, 'type': 10, 'text': '10am. Sending agenda now.', 'ts': DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000, 'is_outgoing': true, 'state': 3},
      {'id': 4, 'chat_id': 1, 'from': 1, 'type': 10, 'text': 'Perfect, see you then! 🎉', 'ts': DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch ~/ 1000, 'is_outgoing': false, 'state': 2},
    ];
  }

  // ── Account methods ──────────────────────────────────────────────────────

  Future<List<int>> getAllAccountIds() async {
    await _delay();
    return _accounts.keys.toList();
  }

  Future<Map<String, dynamic>> getAccountInfo(int accountId) async {
    await _delay();
    return _accounts[accountId] ?? {};
  }

  Future<int> addAccount() async {
    await _delay();
    final id = _accounts.length + 1;
    _accounts[id] = {'id': id, 'configured': false};
    return id;
  }

  Future<void> configureAccount({
    required int accountId,
    required String addr,
    required String password,
    String? mailServer,
    int? mailPort,
    String? sendServer,
    int? sendPort,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    _accounts[accountId] = {
      'id': accountId,
      'addr': addr,
      'configured': true,
      'display_name': addr.split('@').first,
    };
  }

  Future<void> selectAccount(int accountId) async {
    await _delay();
    AppLogger.i('Selected account $accountId');
  }

  Future<void> startIo(int accountId) async {
    await _delay();
    AppLogger.i('IO started for account $accountId');
  }

  // ── Chat list methods ────────────────────────────────────────────────────

  Future<List<int>> getChatListIds({int accountId = 1, String? query, bool archivedOnly = false}) async {
    await _delay();
    var ids = _chats.keys.toList();
    if (archivedOnly) {
      ids = ids.where((id) => _chats[id]?['visibility'] == 0).toList();
    } else {
      ids = ids.where((id) => _chats[id]?['visibility'] != 0).toList();
    }
    if (query != null && query.isNotEmpty) {
      ids = ids.where((id) => (_chats[id]?['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase())).toList();
    }
    // Sort: pinned first (visibility==2), then by last_message_time desc
    ids.sort((a, b) {
      final aPin = (_chats[a]?['visibility'] ?? 1) == 2 ? 1 : 0;
      final bPin = (_chats[b]?['visibility'] ?? 1) == 2 ? 1 : 0;
      if (aPin != bPin) return bPin - aPin;
      final aTs = _chats[a]?['last_message_time'] as int? ?? 0;
      final bTs = _chats[b]?['last_message_time'] as int? ?? 0;
      return bTs.compareTo(aTs);
    });
    return ids;
  }

  Future<Map<String, dynamic>> getChatInfo(int chatId) async {
    await _delay();
    return _chats[chatId] ?? {};
  }

  Future<int> createChatByContactId(int contactId) async {
    await _delay();
    // Return existing chat or create new
    for (final entry in _chats.entries) {
      final ids = entry.value['contact_ids'] as List? ?? [];
      if (ids.length == 1 && ids[0] == contactId) return entry.key;
    }
    final id = _chats.length + 10;
    final contact = _contacts[contactId];
    _chats[id] = {
      'id': id, 'name': contact?['display_name'] ?? 'Unknown',
      'type': 100, 'contact_ids': [contactId], 'unread': 0,
    };
    return id;
  }

  Future<int> createGroupChat({required String name, bool verified = false}) async {
    await _delay();
    final id = _chats.length + 10;
    _chats[id] = {
      'id': id, 'name': name, 'type': 120, 'contact_ids': [], 'unread': 0,
      'is_verified': verified,
    };
    return id;
  }

  Future<void> addContactToChat(int chatId, int contactId) async {
    await _delay();
    final chat = _chats[chatId];
    if (chat != null) {
      final ids = List<int>.from(chat['contact_ids'] as List? ?? []);
      if (!ids.contains(contactId)) {
        ids.add(contactId);
        _chats[chatId] = {...chat, 'contact_ids': ids};
      }
    }
  }

  Future<void> setChatVisibility(int chatId, int visibility) async {
    await _delay();
    final chat = _chats[chatId];
    if (chat != null) _chats[chatId] = {...chat, 'visibility': visibility};
  }

  Future<void> setChatMuteDuration(int chatId, int seconds) async {
    await _delay();
    final chat = _chats[chatId];
    if (chat != null) _chats[chatId] = {...chat, 'muted': seconds != 0, 'mute_until': seconds};
  }

  Future<void> marknoticedChat(int chatId) async {
    await _delay();
    final chat = _chats[chatId];
    if (chat != null) _chats[chatId] = {...chat, 'unread': 0};
  }

  Future<void> deleteChat(int chatId) async {
    await _delay();
    _chats.remove(chatId);
    _messages.remove(chatId);
  }

  // ── Message methods ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages({required int chatId, int offset = 0, int limit = 50}) async {
    await _delay();
    final msgs = _messages[chatId] ?? [];
    final sorted = [...msgs]..sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));
    return sorted.skip(offset).take(limit).toList();
  }

  Future<int> sendTextMessage({required int chatId, required String text, int? quotedMessageId}) async {
    await _delay();
    final msgs = _messages[chatId] ?? [];
    final id = msgs.length + 100;
    final msg = {
      'id': id, 'chat_id': chatId, 'from': 0, 'type': 10, 'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'is_outgoing': true, 'state': 1,
      if (quotedMessageId != null) 'quoted_message_id': quotedMessageId,
    };
    _messages[chatId] = [...msgs, msg];
    _chats[chatId] = {...(_chats[chatId] ?? {}), 'last_message': text, 'last_message_time': msg['ts']};
    return id;
  }

  Future<int> sendFileMessage({
    required int chatId,
    required String filePath,
    required String mimeType,
    String? caption,
  }) async {
    await _delay();
    final msgs = _messages[chatId] ?? [];
    final id = msgs.length + 200;
    final msg = {
      'id': id, 'chat_id': chatId, 'from': 0,
      'type': mimeType.startsWith('image/') ? 20 : (mimeType.startsWith('video/') ? 21 : 60),
      'file': filePath, 'mime': mimeType, 'text': caption ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'is_outgoing': true, 'state': 1,
    };
    _messages[chatId] = [...msgs, msg];
    return id;
  }

  Future<void> deleteMessage(int messageId) async => await _delay();

  Future<void> markSeenMessages(List<int> messageIds) async => await _delay();

  // ── Contact methods ──────────────────────────────────────────────────────

  Future<List<int>> getContacts({String? query, bool blockedOnly = false}) async {
    await _delay();
    var ids = _contacts.keys.toList();
    if (blockedOnly) {
      ids = ids.where((id) => _contacts[id]?['blocked'] == true).toList();
    }
    if (query != null && query.isNotEmpty) {
      ids = ids.where((id) {
        final c = _contacts[id]!;
        return (c['display_name'] as String? ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (c['addr'] as String? ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    return ids;
  }

  Future<Map<String, dynamic>> getContactInfo(int contactId) async {
    await _delay();
    return _contacts[contactId] ?? {};
  }

  Future<int> createContact({required String addr, String? name}) async {
    await _delay();
    final id = _contacts.length + 10;
    _contacts[id] = {'id': id, 'addr': addr, 'display_name': name ?? addr.split('@').first};
    return id;
  }

  Future<void> blockContact(int contactId) async {
    await _delay();
    final c = _contacts[contactId];
    if (c != null) _contacts[contactId] = {...c, 'blocked': true};
  }

  Future<void> unblockContact(int contactId) async {
    await _delay();
    final c = _contacts[contactId];
    if (c != null) _contacts[contactId] = {...c, 'blocked': false};
  }

  Future<void> deleteContact(int contactId) async {
    await _delay();
    _contacts.remove(contactId);
  }

  // ── QR / invite methods ──────────────────────────────────────────────────

  Future<String> getQrCode({int accountId = 1, int? chatId}) async {
    await _delay();
    return chatId != null
        ? 'OPENPGP4FPR:group-$chatId@omega.app'
        : 'OPENPGP4FPR:account-$accountId@omega.app';
  }

  Future<Map<String, dynamic>> checkQr({required String qr, int accountId = 1}) async {
    await _delay();
    if (qr.startsWith('OPENPGP4FPR:')) {
      return {'state': 200, 'type': 'qr_ask_verifycontact', 'id': 1, 'text': 'Verify contact'};
    }
    if (qr.startsWith('https://i.delta.chat/')) {
      return {'state': 200, 'type': 'qr_account', 'text': 'Create account'};
    }
    return {'state': 400, 'type': 'qr_error', 'text': 'Unknown QR code'};
  }

  Future<void> continueKeyTransfer({required int accountId, required int messageId, required String setupCode}) async {
    await Future.delayed(const Duration(seconds: 3));
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getConfig(int accountId) async {
    await _delay();
    return {
      'mvbox_enabled': true,
      'sentbox_watch': true,
      'bcc_self': false,
      'show_emails': 0,
      'download_limit': 26214400,
      'read_receipts': true,
      'auto_delete_device_days': 0,
      'auto_delete_server_days': 0,
    };
  }

  Future<void> setConfig(int accountId, String key, dynamic value) async {
    await _delay();
    AppLogger.d('setConfig $accountId.$key = $value');
  }

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 80));
}

@riverpod
DeltaRpcClient deltaRpcClient(DeltaRpcClientRef ref) {
  final client = DeltaRpcClient();
  client.start();
  ref.onDispose(() => client.stop());
  return client;
}
