import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

part 'isar_schema.g.dart';

// ── Collections ────────────────────────────────────────────────────────────

@collection
class IsarAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late int accountId;

  late String email;
  late String displayName;
  String? profileImagePath;
  String? statusMessage;
  late bool configured;
  DateTime? lastSyncAt;
  String? fcmToken;
}

@collection
class IsarChat {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId;

  @Index(composite: [CompositeIndex('chatId')])
  late int chatId;

  late String name;
  late int type; // 100=single, 120=group, 160=broadcast
  late int visibility; // 0=archived, 1=normal, 2=pinned
  String? profileImagePath;
  String? lastMessageText;
  DateTime? lastMessageTime;
  late int unreadCount;
  late bool isMuted;
  int? muteUntil;
  late bool isVerified;
  late bool isProtected;
  String? color;
  DateTime? ephemeralTimer;
  DateTime? cachedAt;
}

@collection
class IsarMessage {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId;

  @Index(composite: [CompositeIndex('messageId')])
  late int chatId;

  late int messageId;
  late int fromContactId;
  late int type;
  late int state; // 0=pending, 1=sent, 2=delivered, 3=read, 4=failed

  String? text;
  String? htmlText;
  String? filePath;
  String? fileMimeType;
  String? fileName;
  int? fileBytes;
  int? durationMs;
  double? latitude;
  double? longitude;

  late DateTime timestamp;
  DateTime? receivedAt;

  late bool isOutgoing;
  late bool isForwarded;
  late bool isInfo;
  late bool showPadlock;

  int? quotedMessageId;
  String? quotedText;
  int? quotedContactId;

  String? overrideSenderName;
  Map<String, int>? reactionCounts;
  late bool isEdited;

  DateTime? cachedAt;
}

@collection
class IsarContact {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId;

  @Index(composite: [CompositeIndex('contactId')])
  late int contactId;

  late String email;
  late String displayName;
  String? authName;
  String? profileImagePath;
  String? statusMessage;
  late bool isVerified;
  late bool isBlocked;
  late bool isBot;
  String? color;
  DateTime? lastSeen;
  DateTime? cachedAt;
}

@collection
class IsarDraft {
  Id id = Isar.autoIncrement;

  @Index(unique: true, composite: [CompositeIndex('chatId')])
  late int accountId;

  late int chatId;
  late String text;
  int? quotedMessageId;
  String? quotedText;
  DateTime? savedAt;
}

// ── Database singleton ─────────────────────────────────────────────────────

class OmegaDatabase {
  static Isar? _instance;

  static Future<Isar> get instance async {
    _instance ??= await _open();
    return _instance!;
  }

  static Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        IsarAccountSchema,
        IsarChatSchema,
        IsarMessageSchema,
        IsarContactSchema,
        IsarDraftSchema,
      ],
      directory: dir.path,
      name: 'omega',
    );
  }

  // ── Chat queries ───────────────────────────────────────────────────────

  static Future<List<IsarChat>> getChats(int accountId, {bool archivedOnly = false}) async {
    final db = await instance;
    final query = db.isarChats
        .where()
        .accountIdEqualTo(accountId)
        .filter()
        .visibilityEqualTo(archivedOnly ? 0 : 1);
    return query.findAll();
  }

  static Future<void> upsertChat(IsarChat chat) async {
    final db = await instance;
    await db.writeTxn(() async {
      final existing = await db.isarChats
          .where()
          .filter()
          .accountIdEqualTo(chat.accountId)
          .and()
          .chatIdEqualTo(chat.chatId)
          .findFirst();
      if (existing != null) {
        chat.id = existing.id;
      }
      await db.isarChats.put(chat);
    });
  }

  // ── Message queries ────────────────────────────────────────────────────

  static Future<List<IsarMessage>> getMessages(
    int accountId,
    int chatId, {
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await instance;
    return db.isarMessages
        .where()
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  static Future<void> upsertMessage(IsarMessage msg) async {
    final db = await instance;
    await db.writeTxn(() async {
      final existing = await db.isarMessages
          .where()
          .filter()
          .accountIdEqualTo(msg.accountId)
          .and()
          .chatIdEqualTo(msg.chatId)
          .and()
          .messageIdEqualTo(msg.messageId)
          .findFirst();
      if (existing != null) msg.id = existing.id;
      await db.isarMessages.put(msg);
    });
  }

  static Future<void> deleteMessage(int accountId, int messageId) async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.isarMessages
          .where()
          .filter()
          .accountIdEqualTo(accountId)
          .and()
          .messageIdEqualTo(messageId)
          .deleteAll();
    });
  }

  // ── Draft operations ───────────────────────────────────────────────────

  static Future<IsarDraft?> getDraft(int accountId, int chatId) async {
    final db = await instance;
    return db.isarDrafts
        .where()
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .chatIdEqualTo(chatId)
        .findFirst();
  }

  static Future<void> saveDraft(int accountId, int chatId, String text, {int? quotedMessageId, String? quotedText}) async {
    final db = await instance;
    await db.writeTxn(() async {
      final existing = await db.isarDrafts
          .where()
          .filter()
          .accountIdEqualTo(accountId)
          .and()
          .chatIdEqualTo(chatId)
          .findFirst();
      final draft = (existing ?? IsarDraft())
        ..accountId = accountId
        ..chatId = chatId
        ..text = text
        ..quotedMessageId = quotedMessageId
        ..quotedText = quotedText
        ..savedAt = DateTime.now();
      await db.isarDrafts.put(draft);
    });
  }

  static Future<void> clearDraft(int accountId, int chatId) async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.isarDrafts
          .where()
          .filter()
          .accountIdEqualTo(accountId)
          .and()
          .chatIdEqualTo(chatId)
          .deleteAll();
    });
  }

  // ── Contact queries ────────────────────────────────────────────────────

  static Future<List<IsarContact>> searchContacts(int accountId, String query) async {
    final db = await instance;
    final q = query.toLowerCase();
    return db.isarContacts
        .where()
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .group((g) => g
            .displayNameContains(q, caseSensitive: false)
            .or()
            .emailContains(q, caseSensitive: false))
        .findAll();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  static Future<void> clearAll() async {
    final db = await instance;
    await db.writeTxn(() async {
      await db.clear();
    });
  }
}
