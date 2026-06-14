import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// ── Database version ───────────────────────────────────────────────────────

const int _kDbVersion = 1;
const String _kDbName = 'omega.db';

// ── Table names ────────────────────────────────────────────────────────────

const String _tAccounts = 'accounts';
const String _tChats = 'chats';
const String _tMessages = 'messages';
const String _tContacts = 'contacts';
const String _tDrafts = 'drafts';

// ── CREATE TABLE statements ────────────────────────────────────────────────

const String _sqlCreateAccounts = '''
CREATE TABLE $_tAccounts (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id     INTEGER NOT NULL UNIQUE,
  email          TEXT    NOT NULL,
  display_name   TEXT    NOT NULL,
  profile_image  TEXT,
  status_message TEXT,
  configured     INTEGER NOT NULL DEFAULT 0,
  last_sync_at   INTEGER,
  fcm_token      TEXT
)
''';

const String _sqlCreateChats = '''
CREATE TABLE $_tChats (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id         INTEGER NOT NULL,
  chat_id            INTEGER NOT NULL,
  name               TEXT    NOT NULL,
  type               INTEGER NOT NULL,
  visibility         INTEGER NOT NULL DEFAULT 1,
  profile_image      TEXT,
  last_message_text  TEXT,
  last_message_time  INTEGER,
  unread_count       INTEGER NOT NULL DEFAULT 0,
  is_muted           INTEGER NOT NULL DEFAULT 0,
  mute_until         INTEGER,
  is_verified        INTEGER NOT NULL DEFAULT 0,
  is_protected       INTEGER NOT NULL DEFAULT 0,
  color              TEXT,
  ephemeral_timer    INTEGER,
  cached_at          INTEGER,
  UNIQUE (account_id, chat_id)
)
''';

const String _sqlCreateMessages = '''
CREATE TABLE $_tMessages (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id           INTEGER NOT NULL,
  chat_id              INTEGER NOT NULL,
  message_id           INTEGER NOT NULL,
  from_contact_id      INTEGER NOT NULL,
  type                 INTEGER NOT NULL,
  state                INTEGER NOT NULL DEFAULT 0,
  text                 TEXT,
  html_text            TEXT,
  file_path            TEXT,
  file_mime_type       TEXT,
  file_name            TEXT,
  file_bytes           INTEGER,
  duration_ms          INTEGER,
  latitude             REAL,
  longitude            REAL,
  timestamp            INTEGER NOT NULL,
  received_at          INTEGER,
  is_outgoing          INTEGER NOT NULL DEFAULT 0,
  is_forwarded         INTEGER NOT NULL DEFAULT 0,
  is_info              INTEGER NOT NULL DEFAULT 0,
  show_padlock         INTEGER NOT NULL DEFAULT 0,
  quoted_message_id    INTEGER,
  quoted_text          TEXT,
  quoted_contact_id    INTEGER,
  override_sender_name TEXT,
  reaction_counts      TEXT,
  is_edited            INTEGER NOT NULL DEFAULT 0,
  cached_at            INTEGER,
  UNIQUE (account_id, chat_id, message_id)
)
''';

const String _sqlCreateContacts = '''
CREATE TABLE $_tContacts (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id     INTEGER NOT NULL,
  contact_id     INTEGER NOT NULL,
  email          TEXT    NOT NULL,
  display_name   TEXT    NOT NULL,
  auth_name      TEXT,
  profile_image  TEXT,
  status_message TEXT,
  is_verified    INTEGER NOT NULL DEFAULT 0,
  is_blocked     INTEGER NOT NULL DEFAULT 0,
  is_bot         INTEGER NOT NULL DEFAULT 0,
  color          TEXT,
  last_seen      INTEGER,
  cached_at      INTEGER,
  UNIQUE (account_id, contact_id)
)
''';

const String _sqlCreateDrafts = '''
CREATE TABLE $_tDrafts (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id        INTEGER NOT NULL,
  chat_id           INTEGER NOT NULL,
  text              TEXT    NOT NULL,
  quoted_message_id INTEGER,
  quoted_text       TEXT,
  saved_at          INTEGER,
  UNIQUE (account_id, chat_id)
)
''';

// ── Index statements ───────────────────────────────────────────────────────

const List<String> _sqlCreateIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_chats_account ON $_tChats (account_id)',
  'CREATE INDEX IF NOT EXISTS idx_messages_account ON $_tMessages (account_id)',
  'CREATE INDEX IF NOT EXISTS idx_messages_chat ON $_tMessages (account_id, chat_id)',
  'CREATE INDEX IF NOT EXISTS idx_contacts_account ON $_tContacts (account_id)',
];

// ── OmegaDatabase ──────────────────────────────────────────────────────────

/// Singleton sqflite database for the Omega app.
///
/// Usage:
/// ```dart
/// final db = await OmegaDatabase.getInstance();
/// final chats = await db.getChats(accountId);
/// ```
class OmegaDatabase {
  OmegaDatabase._();

  static OmegaDatabase? _singleton;
  Database? _db;

  // ── Singleton access ─────────────────────────────────────────────────────

  /// Returns the shared [OmegaDatabase] instance, opening the underlying
  /// SQLite file if it has not been opened yet.
  static Future<OmegaDatabase> getInstance() async {
    _singleton ??= OmegaDatabase._();
    await _singleton!._ensureOpen();
    return _singleton!;
  }

  Future<void> _ensureOpen() async {
    if (_db != null && _db!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _kDbName);
    _db = await openDatabase(
      path,
      version: _kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable WAL mode for better concurrent read performance.
        await db.execute('PRAGMA journal_mode=WAL');
        // Enforce foreign-key constraints.
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null || !db.isOpen) {
      throw StateError(
        'OmegaDatabase is not open. Call getInstance() before using it.',
      );
    }
    return db;
  }

  // ── Schema callbacks ─────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_sqlCreateAccounts);
    await db.execute(_sqlCreateChats);
    await db.execute(_sqlCreateMessages);
    await db.execute(_sqlCreateContacts);
    await db.execute(_sqlCreateDrafts);
    for (final sql in _sqlCreateIndexes) {
      await db.execute(sql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Scaffold for future migrations:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  // ── Account operations ───────────────────────────────────────────────────

  /// Insert or replace an account row.
  ///
  /// The map must contain all non-nullable fields:
  /// `account_id`, `email`, `display_name`, `configured`.
  /// Optional fields: `profile_image`, `status_message`, `last_sync_at`
  /// (epoch ms int), `fcm_token`.
  Future<void> upsertAccount(Map<String, dynamic> account) async {
    await _database.insert(
      _tAccounts,
      account,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all accounts ordered by `account_id`.
  Future<List<Map<String, dynamic>>> getAccounts() async {
    return _database.query(_tAccounts, orderBy: 'account_id ASC');
  }

  // ── Chat operations ──────────────────────────────────────────────────────

  /// Insert or replace a chat row.
  ///
  /// Required keys: `account_id`, `chat_id`, `name`, `type`.
  /// `visibility`: 0 = archived, 1 = normal (default), 2 = pinned.
  Future<void> upsertChat(Map<String, dynamic> chat) async {
    await _database.insert(
      _tChats,
      chat,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns non-archived chats (visibility != 0) for [accountId],
  /// ordered by last message time descending.
  Future<List<Map<String, dynamic>>> getChats(int accountId) async {
    return _database.query(
      _tChats,
      where: 'account_id = ? AND visibility != 0',
      whereArgs: [accountId],
      orderBy: 'last_message_time DESC',
    );
  }

  /// Returns archived chats (visibility = 0) for [accountId].
  Future<List<Map<String, dynamic>>> getArchivedChats(int accountId) async {
    return _database.query(
      _tChats,
      where: 'account_id = ? AND visibility = 0',
      whereArgs: [accountId],
      orderBy: 'last_message_time DESC',
    );
  }

  // ── Message operations ───────────────────────────────────────────────────

  /// Insert or replace a message row.
  ///
  /// Required keys: `account_id`, `chat_id`, `message_id`, `from_contact_id`,
  /// `type`, `state`, `timestamp` (epoch ms int), `is_outgoing`,
  /// `is_forwarded`, `is_info`, `show_padlock`, `is_edited`.
  ///
  /// `reaction_counts` must be a JSON-encoded string if provided
  /// (use [encodeReactionCounts]).
  Future<void> upsertMessage(Map<String, dynamic> message) async {
    await _database.insert(
      _tMessages,
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns messages for a chat, newest first, with pagination support.
  Future<List<Map<String, dynamic>>> getMessages(
    int accountId,
    int chatId, {
    int offset = 0,
    int limit = 50,
  }) async {
    return _database.query(
      _tMessages,
      where: 'account_id = ? AND chat_id = ?',
      whereArgs: [accountId, chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Deletes a specific message by its [messageId] within [accountId].
  Future<void> deleteMessage(int accountId, int messageId) async {
    await _database.delete(
      _tMessages,
      where: 'account_id = ? AND message_id = ?',
      whereArgs: [accountId, messageId],
    );
  }

  // ── Contact operations ───────────────────────────────────────────────────

  /// Insert or replace a contact row.
  ///
  /// Required keys: `account_id`, `contact_id`, `email`, `display_name`,
  /// `is_verified`, `is_blocked`, `is_bot`.
  Future<void> upsertContact(Map<String, dynamic> contact) async {
    await _database.insert(
      _tContacts,
      contact,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns a single contact by [accountId] + [contactId], or `null`.
  Future<Map<String, dynamic>?> getContact(
    int accountId,
    int contactId,
  ) async {
    final rows = await _database.query(
      _tContacts,
      where: 'account_id = ? AND contact_id = ?',
      whereArgs: [accountId, contactId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns all contacts for [accountId] ordered by display name.
  Future<List<Map<String, dynamic>>> getContacts(int accountId) async {
    return _database.query(
      _tContacts,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'display_name ASC',
    );
  }

  /// Full-text search over display_name and email (case-insensitive LIKE).
  Future<List<Map<String, dynamic>>> searchContacts(
    int accountId,
    String query,
  ) async {
    final pattern = '%${query.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    return _database.query(
      _tContacts,
      where:
          'account_id = ? AND (display_name LIKE ? ESCAPE \'\\\' OR email LIKE ? ESCAPE \'\\\')',
      whereArgs: [accountId, pattern, pattern],
      orderBy: 'display_name ASC',
    );
  }

  // ── Draft operations ─────────────────────────────────────────────────────

  /// Persist a draft for the given [accountId] / [chatId] pair.
  Future<void> saveDraft(
    int accountId,
    int chatId,
    String text, {
    int? quotedMessageId,
    String? quotedText,
  }) async {
    await _database.insert(
      _tDrafts,
      {
        'account_id': accountId,
        'chat_id': chatId,
        'text': text,
        'quoted_message_id': quotedMessageId,
        'quoted_text': quotedText,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the stored draft map for [accountId] / [chatId], or `null`.
  ///
  /// Map keys: `text`, `quoted_message_id`, `quoted_text`, `saved_at`.
  Future<Map<String, dynamic>?> getDraft(int accountId, int chatId) async {
    final rows = await _database.query(
      _tDrafts,
      where: 'account_id = ? AND chat_id = ?',
      whereArgs: [accountId, chatId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Deletes any stored draft for [accountId] / [chatId].
  Future<void> clearDraft(int accountId, int chatId) async {
    await _database.delete(
      _tDrafts,
      where: 'account_id = ? AND chat_id = ?',
      whereArgs: [accountId, chatId],
    );
  }

  /// Deletes all drafts for [accountId] (e.g., on account logout).
  Future<void> clearDraftsForAccount(int accountId) async {
    await _database.delete(
      _tDrafts,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Deletes all rows from every table (useful for logout / test reset).
  Future<void> clearAll() async {
    final db = _database;
    await db.transaction((txn) async {
      for (final table in [
        _tDrafts,
        _tMessages,
        _tContacts,
        _tChats,
        _tAccounts,
      ]) {
        await txn.delete(table);
      }
    });
  }

  /// Closes the underlying SQLite connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _singleton = null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Encode a `Map<String, int>` reaction-counts map to a JSON string
  /// suitable for the `reaction_counts` column.
  static String encodeReactionCounts(Map<String, int> counts) =>
      jsonEncode(counts);

  /// Decode a JSON string from the `reaction_counts` column back to a map.
  /// Returns an empty map if [json] is null or malformed.
  static Map<String, int> decodeReactionCounts(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Convert a [DateTime] to an epoch-milliseconds integer for storage.
  static int? dateTimeToMs(DateTime? dt) => dt?.millisecondsSinceEpoch;

  /// Convert an epoch-milliseconds integer from storage to a [DateTime].
  static DateTime? msToDateTime(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}
