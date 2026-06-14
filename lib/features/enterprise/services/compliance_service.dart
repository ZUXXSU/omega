import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/delta_rpc_client.dart';
import '../../../core/utils/logger.dart';
import 'audit_log_service.dart';

/// A snapshot of an enforced policy for inclusion in compliance reports.
class PolicyEntry {
  final String key;
  final String label;
  final bool enforced;
  final String? value;

  const PolicyEntry({
    required this.key,
    required this.label,
    required this.enforced,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'enforced': enforced,
        if (value != null) 'value': value,
      };
}

/// Aggregate compliance report for a given account and date range.
class ComplianceReport {
  final DateTime generatedAt;
  final String accountEmail;
  final int accountId;
  final int totalMessages;
  final DateTime? rangeFrom;
  final DateTime? rangeTo;
  final List<PolicyEntry> policies;
  final List<AuditEvent> auditEvents;

  const ComplianceReport({
    required this.generatedAt,
    required this.accountEmail,
    required this.accountId,
    required this.totalMessages,
    this.rangeFrom,
    this.rangeTo,
    required this.policies,
    required this.auditEvents,
  });

  int get auditEventCount => auditEvents.length;

  String get dateRangeLabel {
    if (rangeFrom == null && rangeTo == null) return 'All time';
    final f = rangeFrom != null ? _fmtDate(rangeFrom!) : 'beginning';
    final t = rangeTo != null ? _fmtDate(rangeTo!) : 'now';
    return '$f – $t';
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'accountEmail': accountEmail,
        'accountId': accountId,
        'totalMessages': totalMessages,
        if (rangeFrom != null) 'rangeFrom': rangeFrom!.toIso8601String(),
        if (rangeTo != null) 'rangeTo': rangeTo!.toIso8601String(),
        'policies': policies.map((p) => p.toJson()).toList(),
        'auditEventCount': auditEventCount,
        'auditEvents': auditEvents.map((e) => e.toJson()).toList(),
      };
}

/// Compliance export service.
///
/// Generates [ComplianceReport] objects by reading account info from
/// [DeltaRpcClient] and audit events from [AuditLogService], then serialises
/// to CSV or JSON and saves to the Downloads folder.
class ComplianceService {
  ComplianceService._();

  static final ComplianceService instance = ComplianceService._();

  // ── Report generation ───────────────────────────────────────────────────

  /// Generate a compliance report for [accountId].
  ///
  /// [from] / [to] filter which audit events are included; message count
  /// is always the total persisted by DeltaChat for the account.
  Future<ComplianceReport> generateReport(
    int accountId, {
    DateTime? from,
    DateTime? to,
    DeltaRpcClient? rpcClient,
  }) async {
    final client = rpcClient ?? DeltaRpcClient();

    // Account info
    final accountInfo = await client.getAccountInfo(accountId);
    final email = (accountInfo['addr'] as String?) ?? 'unknown@unknown.com';

    // Total message count: sum across all chat IDs
    final chatIds = await client.getChatListIds(accountId: accountId);
    int totalMessages = 0;
    for (final chatId in chatIds) {
      final msgs = await client.getMessages(chatId: chatId, limit: 1);
      // We only fetched 1 to check existence; use a secondary approach:
      // DeltaRpcClient.getMessages doesn't expose a count directly, so we
      // fetch all and count. For production this would be a dedicated RPC call.
      final allMsgs = await client.getMessages(chatId: chatId, limit: 100000);
      totalMessages += allMsgs.length;
    }

    // Audit events
    final events = await AuditLogService.instance.getEvents(
      from: from,
      to: to,
    );

    // Policies — pulled from a static snapshot (real impl reads MDM channel)
    final policies = _buildPolicySummary();

    return ComplianceReport(
      generatedAt: DateTime.now(),
      accountEmail: email,
      accountId: accountId,
      totalMessages: totalMessages,
      rangeFrom: from,
      rangeTo: to,
      policies: policies,
      auditEvents: events,
    );
  }

  List<PolicyEntry> _buildPolicySummary() {
    // In production this reads from platform MDM channel / SharedPreferences.
    // For now returns a static skeleton that callers can extend.
    return const [
      PolicyEntry(
        key: 'only_one_account',
        label: 'Single Account Mode',
        enforced: false,
      ),
      PolicyEntry(
        key: 'disable_backup',
        label: 'Disable Backup Export',
        enforced: false,
      ),
      PolicyEntry(
        key: 'require_biometric',
        label: 'Require Biometric Lock',
        enforced: false,
      ),
      PolicyEntry(
        key: 'screen_security',
        label: 'Screen Security',
        enforced: false,
      ),
      PolicyEntry(
        key: 'auto_delete_days',
        label: 'Message Auto-Delete',
        enforced: false,
      ),
    ];
  }

  // ── Export ──────────────────────────────────────────────────────────────

  /// Serialise [report] to CSV and save to the Downloads folder.
  ///
  /// Returns the absolute path of the saved file.
  Future<String> exportAsCsv(ComplianceReport report) async {
    final csv = StringBuffer();
    csv.writeln('"Omega Compliance Report"');
    csv.writeln('"Generated","${report.generatedAt.toIso8601String()}"');
    csv.writeln('"Account","${report.accountEmail}"');
    csv.writeln('"Date Range","${report.dateRangeLabel}"');
    csv.writeln('"Total Messages","${report.totalMessages}"');
    csv.writeln('"Audit Events","${report.auditEventCount}"');
    csv.writeln('');

    csv.writeln('"POLICIES"');
    csv.writeln('"key","label","enforced","value"');
    for (final p in report.policies) {
      csv.writeln('"${p.key}","${p.label}","${p.enforced}","${p.value ?? ''}"');
    }
    csv.writeln('');

    csv.writeln('"AUDIT LOG"');
    csv.writeln('"event_type","timestamp","account_id","metadata"');
    for (final e in report.auditEvents) {
      csv.writeln(e.toCsvRow());
    }

    final path = await _saveFile(
      name: _fileName(report.accountEmail, 'csv'),
      content: csv.toString(),
    );
    AppLogger.i('ComplianceService: CSV exported to $path');
    return path;
  }

  /// Serialise [report] to JSON and save to the Downloads folder.
  ///
  /// Returns the absolute path of the saved file.
  Future<String> exportAsJson(ComplianceReport report) async {
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(report.toJson());

    final path = await _saveFile(
      name: _fileName(report.accountEmail, 'json'),
      content: content,
    );
    AppLogger.i('ComplianceService: JSON exported to $path');
    return path;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _fileName(String email, String ext) {
    final safe = email.replaceAll(RegExp(r'[^a-zA-Z0-9@._-]'), '_');
    final ts = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    return 'omega_compliance_${safe}_$ts.$ext';
  }

  Future<String> _saveFile({required String name, required String content}) async {
    Directory dir;
    try {
      // On iOS/Android this gives the app's Documents directory; on desktop
      // it gives the real Downloads folder.
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir = await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        // macOS / Linux / Windows
        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            (await getApplicationDocumentsDirectory()).path;
        dir = Directory('$home/Downloads');
        if (!dir.existsSync()) dir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$name');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}
