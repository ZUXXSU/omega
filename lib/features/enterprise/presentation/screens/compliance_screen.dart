import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../services/audit_log_service.dart';
import '../../services/compliance_service.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final _accountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(deltaRpcClientProvider);
  final ids = await client.getAllAccountIds();
  final infos = <Map<String, dynamic>>[];
  for (final id in ids) {
    final info = await client.getAccountInfo(id);
    infos.add({...info, 'id': id});
  }
  return infos;
});

// ── Screen ──────────────────────────────────────────────────────────────────

/// Enterprise compliance export screen.
///
/// Lets the user select an account (multi-account mode), pick a date range,
/// generate a [ComplianceReport] preview, then export as CSV or JSON.
class ComplianceScreen extends ConsumerStatefulWidget {
  const ComplianceScreen({super.key});

  @override
  ConsumerState<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends ConsumerState<ComplianceScreen> {
  int? _selectedAccountId;
  DateTime? _from;
  DateTime? _to;
  ComplianceReport? _report;
  bool _generating = false;
  bool _exportingCsv = false;
  bool _exportingJson = false;
  String? _lastExportPath;
  String? _errorMessage;

  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(_accountsProvider);

    return Scaffold(
      backgroundColor: OmegaColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Compliance Export',
          style: OmegaTextStyles.titleMedium,
        ),
        backgroundColor: OmegaColors.surfaceLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(message: err.toString()),
        data: (accounts) => _buildBody(accounts),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> accounts) {
    // Auto-select the only account when there is exactly one
    if (accounts.length == 1 && _selectedAccountId == null) {
      _selectedAccountId = accounts.first['id'] as int;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(label: 'ACCOUNT'),
        const SizedBox(height: 8),
        _AccountSelector(
          accounts: accounts,
          selectedId: _selectedAccountId,
          onChanged: (id) => setState(() {
            _selectedAccountId = id;
            _report = null;
            _errorMessage = null;
          }),
        ),
        const SizedBox(height: 20),
        _SectionHeader(label: 'DATE RANGE'),
        const SizedBox(height: 8),
        _DateRangePicker(
          from: _from,
          to: _to,
          dateFormat: _dateFormat,
          onFromTapped: () => _pickDate(isFrom: true),
          onToTapped: () => _pickDate(isFrom: false),
          onClear: () => setState(() {
            _from = null;
            _to = null;
            _report = null;
          }),
        ),
        const SizedBox(height: 24),
        _GenerateButton(
          enabled: _selectedAccountId != null && !_generating,
          loading: _generating,
          onPressed: _generateReport,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: _errorMessage!),
        ],
        if (_report != null) ...[
          const SizedBox(height: 24),
          _ReportPreview(report: _report!),
          const SizedBox(height: 16),
          _ExportButtons(
            exportingCsv: _exportingCsv,
            exportingJson: _exportingJson,
            onCsv: _exportCsv,
            onJson: _exportJson,
          ),
        ],
        if (_lastExportPath != null) ...[
          const SizedBox(height: 12),
          _ExportSuccessBanner(path: _lastExportPath!),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_from ?? DateTime.now()) : (_to ?? DateTime.now());
    final first = isFrom ? DateTime(2020) : (_from ?? DateTime(2020));
    final last = isFrom ? (_to ?? DateTime.now()) : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : (initial.isBefore(first) ? first : initial),
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: OmegaColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      }
      _report = null;
    });
  }

  Future<void> _generateReport() async {
    if (_selectedAccountId == null) return;
    setState(() {
      _generating = true;
      _errorMessage = null;
      _report = null;
      _lastExportPath = null;
    });
    try {
      final client = ref.read(deltaRpcClientProvider);
      final report = await ComplianceService.instance.generateReport(
        _selectedAccountId!,
        from: _from,
        to: _to,
        rpcClient: client,
      );
      setState(() => _report = report);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to generate report: $e');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_report == null) return;
    setState(() {
      _exportingCsv = true;
      _lastExportPath = null;
    });
    try {
      final path = await ComplianceService.instance.exportAsCsv(_report!);
      await AuditLogService.instance.log(
        AuditEventType.backupExported,
        accountId: _selectedAccountId,
        metadata: {'format': 'csv', 'path': path},
      );
      setState(() => _lastExportPath = path);
    } catch (e) {
      setState(() => _errorMessage = 'CSV export failed: $e');
    } finally {
      setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportJson() async {
    if (_report == null) return;
    setState(() {
      _exportingJson = true;
      _lastExportPath = null;
    });
    try {
      final path = await ComplianceService.instance.exportAsJson(_report!);
      await AuditLogService.instance.log(
        AuditEventType.backupExported,
        accountId: _selectedAccountId,
        metadata: {'format': 'json', 'path': path},
      );
      setState(() => _lastExportPath = path);
    } catch (e) {
      setState(() => _errorMessage = 'JSON export failed: $e');
    } finally {
      setState(() => _exportingJson = false);
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: OmegaTextStyles.labelSmall.copyWith(
          color: OmegaColors.textSecondary,
          letterSpacing: 1.2,
        ),
      );
}

class _AccountSelector extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text(
        'No accounts configured.',
        style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textSecondary),
      );
    }
    if (accounts.length == 1) {
      final a = accounts.first;
      return _Card(
        child: ListTile(
          leading: const Icon(Icons.account_circle_rounded, color: OmegaColors.primary),
          title: Text(
            (a['display_name'] as String?) ?? (a['addr'] as String?) ?? 'Account',
            style: OmegaTextStyles.bodyLarge,
          ),
          subtitle: Text(
            (a['addr'] as String?) ?? '',
            style: OmegaTextStyles.bodySmall,
          ),
          trailing: const Icon(Icons.check_circle_rounded, color: OmegaColors.success),
        ),
      );
    }
    return _Card(
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<int>(
            value: selectedId,
            isExpanded: true,
            hint: Text(
              'Select account',
              style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textSecondary),
            ),
            items: accounts.map((a) {
              final id = a['id'] as int;
              final name = (a['display_name'] as String?) ?? (a['addr'] as String?) ?? 'Account $id';
              final email = (a['addr'] as String?) ?? '';
              return DropdownMenuItem<int>(
                value: id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: OmegaTextStyles.bodyLarge),
                    if (email.isNotEmpty)
                      Text(email, style: OmegaTextStyles.bodySmall),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final DateFormat dateFormat;
  final VoidCallback onFromTapped;
  final VoidCallback onToTapped;
  final VoidCallback onClear;

  const _DateRangePicker({
    required this.from,
    required this.to,
    required this.dateFormat,
    required this.onFromTapped,
    required this.onToTapped,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From',
                    value: from != null ? dateFormat.format(from!) : null,
                    placeholder: 'All time',
                    onTap: onFromTapped,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    value: to != null ? dateFormat.format(to!) : null,
                    placeholder: 'Now',
                    onTap: onToTapped,
                  ),
                ),
              ],
            ),
            if (from != null || to != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear range',
                  style: OmegaTextStyles.labelMedium.copyWith(color: OmegaColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: OmegaColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OmegaColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: OmegaTextStyles.labelSmall.copyWith(color: OmegaColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? placeholder,
              style: OmegaTextStyles.bodyMedium.copyWith(
                color: value != null ? OmegaColors.textPrimary : OmegaColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _GenerateButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: OmegaColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OmegaColors.textDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text('Generate Report', style: OmegaTextStyles.labelLarge),
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  final ComplianceReport report;
  const _ReportPreview({required this.report});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy – HH:mm');
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_rounded, color: OmegaColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Report Preview', style: OmegaTextStyles.titleSmall),
              ],
            ),
            const SizedBox(height: 14),
            _Divider(),
            const SizedBox(height: 12),
            _InfoRow(label: 'Account', value: report.accountEmail),
            _InfoRow(label: 'Date Range', value: report.dateRangeLabel),
            _InfoRow(label: 'Total Messages', value: report.totalMessages.toString()),
            _InfoRow(label: 'Audit Events', value: report.auditEventCount.toString()),
            _InfoRow(label: 'Generated', value: fmt.format(report.generatedAt)),
            const SizedBox(height: 12),
            _Divider(),
            const SizedBox(height: 12),
            Text('Policies', style: OmegaTextStyles.titleSmall),
            const SizedBox(height: 8),
            ...report.policies.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      p.enforced ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 16,
                      color: p.enforced ? OmegaColors.primary : OmegaColors.textDisabled,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.label, style: OmegaTextStyles.bodySmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.enforced
                            ? OmegaColors.primary.withOpacity(0.12)
                            : OmegaColors.inputFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.enforced ? 'ENFORCED' : 'NOT SET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.enforced ? OmegaColors.primary : OmegaColors.textDisabled,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(value, style: OmegaTextStyles.bodyMedium),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(color: OmegaColors.divider, height: 1);
}

class _ExportButtons extends StatelessWidget {
  final bool exportingCsv;
  final bool exportingJson;
  final VoidCallback onCsv;
  final VoidCallback onJson;

  const _ExportButtons({
    required this.exportingCsv,
    required this.exportingJson,
    required this.onCsv,
    required this.onJson,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: exportingCsv ? null : onCsv,
            icon: exportingCsv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: OmegaColors.primary,
              side: const BorderSide(color: OmegaColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: exportingJson ? null : onJson,
            icon: exportingJson
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.data_object_rounded, size: 18),
            label: const Text('Export JSON'),
            style: OutlinedButton.styleFrom(
              foregroundColor: OmegaColors.secondary,
              side: const BorderSide(color: OmegaColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportSuccessBanner extends StatelessWidget {
  final String path;
  const _ExportSuccessBanner({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OmegaColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OmegaColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: OmegaColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export saved',
                  style: OmegaTextStyles.labelMedium.copyWith(color: OmegaColors.success),
                ),
                Text(
                  path,
                  style: OmegaTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OmegaColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OmegaColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: OmegaColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: OmegaColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}
