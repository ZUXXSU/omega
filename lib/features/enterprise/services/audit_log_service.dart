import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

/// Audit event types for enterprise compliance tracking.
enum AuditEventType {
  login,
  logout,
  messageSent,
  messageDeleted,
  fileShared,
  contactAdded,
  contactBlocked,
  settingsChanged,
  backupExported,
  accountAdded,
  accountRemoved,
}

extension AuditEventTypeExtension on AuditEventType {
  String get name {
    switch (this) {
      case AuditEventType.login:
        return 'LOGIN';
      case AuditEventType.logout:
        return 'LOGOUT';
      case AuditEventType.messageSent:
        return 'MESSAGE_SENT';
      case AuditEventType.messageDeleted:
        return 'MESSAGE_DELETED';
      case AuditEventType.fileShared:
        return 'FILE_SHARED';
      case AuditEventType.contactAdded:
        return 'CONTACT_ADDED';
      case AuditEventType.contactBlocked:
        return 'CONTACT_BLOCKED';
      case AuditEventType.settingsChanged:
        return 'SETTINGS_CHANGED';
      case AuditEventType.backupExported:
        return 'BACKUP_EXPORTED';
      case AuditEventType.accountAdded:
        return 'ACCOUNT_ADDED';
      case AuditEventType.accountRemoved:
        return 'ACCOUNT_REMOVED';
    }
  }

  static AuditEventType fromString(String value) {
    switch (value) {
      case 'LOGIN':
        return AuditEventType.login;
      case 'LOGOUT':
        return AuditEventType.logout;
      case 'MESSAGE_SENT':
        return AuditEventType.messageSent;
      case 'MESSAGE_DELETED':
        return AuditEventType.messageDeleted;
      case 'FILE_SHARED':
        return AuditEventType.fileShared;
      case 'CONTACT_ADDED':
        return AuditEventType.contactAdded;
      case 'CONTACT_BLOCKED':
        return AuditEventType.contactBlocked;
      case 'SETTINGS_CHANGED':
        return AuditEventType.settingsChanged;
      case 'BACKUP_EXPORTED':
        return AuditEventType.backupExported;
      case 'ACCOUNT_ADDED':
        return AuditEventType.accountAdded;
      case 'ACCOUNT_REMOVED':
        return AuditEventType.accountRemoved;
      default:
        return AuditEventType.login;
    }
  }
}

/// A single audit event recording a compliance-relevant action.
class AuditEvent {
  final AuditEventType type;
  final DateTime timestamp;
  final int? accountId;
  final Map<String, dynamic> metadata;

  const AuditEvent({
    required this.type,
    required this.timestamp,
    this.accountId,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        if (accountId != null) 'accountId': accountId,
        'metadata': metadata,
      };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
        type: AuditEventTypeExtension.fromString(json['type'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accountId: json['accountId'] as int?,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  /// CSV row representation (type, timestamp, accountId, metadata-json)
  String toCsvRow() {
    final meta = jsonEncode(metadata).replaceAll('"', '""');
    return '"${type.name}","${timestamp.toIso8601String()}","${accountId ?? ''}","$meta"';
  }
}

/// Enterprise audit logging service.
///
/// Persists events to SharedPreferences (capped at [_maxEvents]).
/// Use the singleton [instance] to access.
class AuditLogService {
  AuditLogService._();

  static final AuditLogService instance = AuditLogService._();

  static const String _prefsKey = 'omega_audit_log';
  static const int _maxEvents = 10000;

  List<AuditEvent> _cache = [];
  bool _loaded = false;

  // ── Initialisation ──────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) {
        _cache = [];
      } else {
        final list = jsonDecode(raw) as List<dynamic>;
        _cache = list
            .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _loaded = true;
    } catch (e) {
      AppLogger.e('AuditLogService._load failed', e);
      _cache = [];
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cache.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (e) {
      AppLogger.e('AuditLogService._persist failed', e);
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Log a new audit event.
  ///
  /// [type] — the event type.
  /// [accountId] — optional account this event belongs to.
  /// [metadata] — arbitrary key/value context (e.g. chatId, fileName).
  Future<void> log(
    AuditEventType type, {
    int? accountId,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _ensureLoaded();

    final event = AuditEvent(
      type: type,
      timestamp: DateTime.now(),
      accountId: accountId,
      metadata: metadata,
    );

    _cache.add(event);

    // Cap to last _maxEvents entries
    if (_cache.length > _maxEvents) {
      _cache = _cache.sublist(_cache.length - _maxEvents);
    }

    await _persist();
    AppLogger.d('AuditLog: ${event.type.name} account=$accountId');
  }

  /// Retrieve stored events with optional filters.
  ///
  /// [from] — inclusive start timestamp filter.
  /// [to] — inclusive end timestamp filter.
  /// [type] — optional event type filter.
  Future<List<AuditEvent>> getEvents({
    DateTime? from,
    DateTime? to,
    AuditEventType? type,
  }) async {
    await _ensureLoaded();

    return _cache.where((e) {
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      if (type != null && e.type != type) return false;
      return true;
    }).toList();
  }

  /// Export all (or filtered) events as a CSV string.
  ///
  /// Returns a UTF-8 CSV with header row.
  Future<String> exportCsv({DateTime? from, DateTime? to, AuditEventType? type}) async {
    final events = await getEvents(from: from, to: to, type: type);
    final buffer = StringBuffer();
    buffer.writeln('"event_type","timestamp","account_id","metadata"');
    for (final e in events) {
      buffer.writeln(e.toCsvRow());
    }
    return buffer.toString();
  }

  /// Delete events older than [days] days. Returns the number deleted.
  Future<int> clearOlderThan(int days) async {
    await _ensureLoaded();

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final before = _cache.length;
    _cache = _cache.where((e) => e.timestamp.isAfter(cutoff)).toList();
    final deleted = before - _cache.length;

    if (deleted > 0) await _persist();
    AppLogger.i('AuditLogService: cleared $deleted events older than $days days');
    return deleted;
  }

  /// Total number of stored events.
  Future<int> get eventCount async {
    await _ensureLoaded();
    return _cache.length;
  }

  /// Wipe all stored events (use with caution).
  Future<void> clearAll() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    AppLogger.w('AuditLogService: all events cleared');
  }
}
