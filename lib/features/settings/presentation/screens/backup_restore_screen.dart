import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../core/utils/logger.dart';

// ── Backup frequency enum ─────────────────────────────────────────────────────

enum BackupFrequency { daily, weekly, never }

extension BackupFrequencyLabel on BackupFrequency {
  String get label => switch (this) {
        BackupFrequency.daily => 'Daily',
        BackupFrequency.weekly => 'Weekly',
        BackupFrequency.never => 'Off',
      };
}

// ── Riverpod provider for backup state ───────────────────────────────────────

class BackupState {
  final DateTime? lastBackupDate;
  final bool autoBackupEnabled;
  final BackupFrequency frequency;

  const BackupState({
    this.lastBackupDate,
    this.autoBackupEnabled = false,
    this.frequency = BackupFrequency.weekly,
  });

  BackupState copyWith({
    DateTime? lastBackupDate,
    bool? autoBackupEnabled,
    BackupFrequency? frequency,
  }) =>
      BackupState(
        lastBackupDate: lastBackupDate ?? this.lastBackupDate,
        autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
        frequency: frequency ?? this.frequency,
      );
}

class BackupNotifier extends StateNotifier<BackupState> {
  BackupNotifier() : super(const BackupState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupMs = prefs.getInt('last_backup_timestamp');
    final autoEnabled = prefs.getBool('auto_backup_enabled') ?? false;
    final freqIndex = prefs.getInt('backup_frequency') ?? BackupFrequency.weekly.index;
    state = BackupState(
      lastBackupDate: lastBackupMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupMs)
          : null,
      autoBackupEnabled: autoEnabled,
      frequency: BackupFrequency.values[freqIndex],
    );
  }

  Future<void> recordBackup() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_backup_timestamp', now.millisecondsSinceEpoch);
    state = state.copyWith(lastBackupDate: now);
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> setFrequency(BackupFrequency freq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backup_frequency', freq.index);
    state = state.copyWith(frequency: freq);
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>(
  (_) => BackupNotifier(),
);

// ── Main screen ───────────────────────────────────────────────────────────────

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  // Backup export progress: 0.0–1.0, null = idle
  double? _exportProgress;
  String? _exportedFilePath;

  // Restore import progress: 0.0–1.0, null = idle
  double? _importProgress;
  String? _importedFileName;
  bool _restoreComplete = false;

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _onExportBackup() async {
    setState(() {
      _exportProgress = 0.0;
      _exportedFilePath = null;
    });

    try {
      final rpc = ref.read(deltaRpcClientProvider);

      // Simulate RPC backup export with progress ticks
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        // In production: await rpc.exportBackup(...) with progress callback
        await rpc.setConfig(1, '_backup_export_tick', i); // simulated call
        if (!mounted) return;
        setState(() => _exportProgress = i / 10.0);
      }

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${dir.path}/omega_backup_$timestamp.tar';

      // Simulate writing a placeholder file
      final file = File(filePath);
      await file.writeAsString(
        'OMEGA_BACKUP_V1\ntimestamp:$timestamp\naccount:1',
      );

      await ref.read(backupProvider.notifier).recordBackup();

      if (!mounted) return;
      setState(() {
        _exportProgress = null;
        _exportedFilePath = filePath;
      });

      _showSuccessSnack('Backup saved to Documents folder');
    } catch (e, st) {
      AppLogger.e('Backup export failed', e, st);
      if (!mounted) return;
      setState(() => _exportProgress = null);
      _showErrorSnack('Export failed: $e');
    }
  }

  void _onTransferToDevice() {
    context.go('/qr-display', extra: {'title': 'Backup Transfer QR'});
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> _onImportBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tar', 'bak'],
      dialogTitle: 'Select Omega Backup File',
    );

    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;

    setState(() {
      _importProgress = 0.0;
      _importedFileName = fileName;
      _restoreComplete = false;
    });

    await _runImport(filePath);
  }

  Future<void> _runImport(String filePath) async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);

      // Simulate RPC restore with progress ticks
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        // In production: await rpc.importBackup(filePath, progress: (p) => ...)
        await rpc.setConfig(1, '_backup_import_tick', i); // simulated call
        if (!mounted) return;
        setState(() => _importProgress = i / 10.0);
      }

      if (!mounted) return;
      setState(() {
        _importProgress = null;
        _restoreComplete = true;
      });

      _showSuccessSnack('Backup restored successfully');
    } catch (e, st) {
      AppLogger.e('Backup import failed', e, st);
      if (!mounted) return;
      setState(() {
        _importProgress = null;
        _restoreComplete = false;
      });
      _showErrorSnack('Import failed: $e');
    }
  }

  void _onReceiveFromDevice() {
    context.go('${RouteConstants.qrScanner}?mode=backup');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: OmegaColors.success,
      ),
    );
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: OmegaColors.error,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Last backup info banner
          _LastBackupBanner(lastBackupDate: backupState.lastBackupDate, isDark: isDark),
          const SizedBox(height: 20),

          // ── BACKUP section ─────────────────────────────────────────────────
          _SectionHeader(label: 'BACKUP'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            children: [
              // Export button
              _ActionTile(
                icon: Icons.upload_rounded,
                iconColor: OmegaColors.primary,
                title: 'Export Backup',
                subtitle: 'Save a .tar backup to your device',
                isDark: isDark,
                onTap: _exportProgress != null ? null : _onExportBackup,
                trailing: _exportProgress != null
                    ? _ProgressIndicatorWidget(progress: _exportProgress!)
                    : _exportedFilePath != null
                        ? const Icon(Icons.check_circle_rounded, color: OmegaColors.success)
                        : null,
              ),
              if (_exportedFilePath != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                  child: Text(
                    'Saved: $_exportedFilePath',
                    style: OmegaTextStyles.caption.copyWith(
                      color: OmegaColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              _divider(isDark),

              // Transfer via QR
              _ActionTile(
                icon: Icons.qr_code_rounded,
                iconColor: OmegaColors.secondary,
                title: 'Transfer to Another Device',
                subtitle: 'Show QR code to send backup wirelessly',
                isDark: isDark,
                onTap: _onTransferToDevice,
              ),
              _divider(isDark),

              // Auto-backup toggle
              _AutoBackupToggle(
                enabled: backupState.autoBackupEnabled,
                isDark: isDark,
                onChanged: (val) =>
                    ref.read(backupProvider.notifier).setAutoBackup(val),
              ),

              // Frequency picker (visible when auto-backup is on)
              if (backupState.autoBackupEnabled) ...[
                _divider(isDark),
                _FrequencyPicker(
                  frequency: backupState.frequency,
                  isDark: isDark,
                  onChanged: (freq) =>
                      ref.read(backupProvider.notifier).setFrequency(freq),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // ── RESTORE section ────────────────────────────────────────────────
          _SectionHeader(label: 'RESTORE'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            children: [
              // Import file
              _ActionTile(
                icon: Icons.folder_open_rounded,
                iconColor: Colors.orange,
                title: 'Import Backup File',
                subtitle: 'Select a .tar backup file from storage',
                isDark: isDark,
                onTap: _importProgress != null ? null : _onImportBackupFile,
                trailing: _importProgress != null
                    ? _ProgressIndicatorWidget(progress: _importProgress!)
                    : _restoreComplete
                        ? const Icon(Icons.check_circle_rounded, color: OmegaColors.success)
                        : null,
              ),
              if (_importProgress != null && _importedFileName != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                  child: Text(
                    'Restoring: $_importedFileName',
                    style: OmegaTextStyles.caption.copyWith(
                      color: OmegaColors.textSecondary,
                    ),
                  ),
                ),
              ],
              _divider(isDark),

              // Receive from device
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: Colors.purple,
                title: 'Receive from Other Device',
                subtitle: 'Scan QR code to receive backup wirelessly',
                isDark: isDark,
                onTap: _onReceiveFromDevice,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Warning card
          _WarningCard(isDark: isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 56,
        color: isDark ? OmegaColors.dividerDark : OmegaColors.divider,
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LastBackupBanner extends StatelessWidget {
  final DateTime? lastBackupDate;
  final bool isDark;

  const _LastBackupBanner({required this.lastBackupDate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasBackup = lastBackupDate != null;
    final bgColor = hasBackup
        ? OmegaColors.success.withOpacity(0.1)
        : OmegaColors.warning.withOpacity(0.1);
    final iconColor = hasBackup ? OmegaColors.success : OmegaColors.warning;
    final icon = hasBackup ? Icons.verified_rounded : Icons.warning_amber_rounded;
    final title = hasBackup ? 'Last Backup' : 'No Backup Found';
    final subtitle = hasBackup
        ? DateFormat('MMM d, yyyy • h:mm a').format(lastBackupDate!)
        : 'Create a backup to protect your messages.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OmegaTextStyles.labelLarge.copyWith(
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: OmegaTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? OmegaColors.textSecondaryDark
                        : OmegaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: OmegaTextStyles.labelSmall.copyWith(
          color: OmegaColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SectionCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? OmegaColors.dividerDark : OmegaColors.divider,
          width: 0.5,
        ),
      ),
      color: isDark ? OmegaColors.cardDark : OmegaColors.cardLight,
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: OmegaTextStyles.bodyLarge.copyWith(
          color: onTap == null
              ? (isDark ? OmegaColors.textDisabledDark : OmegaColors.textDisabled)
              : (isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: OmegaTextStyles.bodySmall.copyWith(
          color: isDark ? OmegaColors.textSecondaryDark : OmegaColors.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? OmegaColors.textDisabledDark : OmegaColors.textDisabled,
            size: 20,
          ),
      onTap: onTap,
    );
  }
}

class _ProgressIndicatorWidget extends StatelessWidget {
  final double progress;

  const _ProgressIndicatorWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: OmegaColors.primary,
            backgroundColor: OmegaColors.primary.withOpacity(0.15),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: OmegaTextStyles.labelSmall.copyWith(
              fontSize: 9,
              color: OmegaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoBackupToggle extends StatelessWidget {
  final bool enabled;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _AutoBackupToggle({
    required this.enabled,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.autorenew_rounded, color: Colors.teal, size: 22),
      ),
      title: Text(
        'Auto-Backup',
        style: OmegaTextStyles.bodyLarge.copyWith(
          color: isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Automatically back up your data',
        style: OmegaTextStyles.bodySmall.copyWith(
          color: isDark ? OmegaColors.textSecondaryDark : OmegaColors.textSecondary,
        ),
      ),
      value: enabled,
      activeColor: OmegaColors.primary,
      onChanged: onChanged,
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  final BackupFrequency frequency;
  final bool isDark;
  final ValueChanged<BackupFrequency> onChanged;

  const _FrequencyPicker({
    required this.frequency,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Frequency',
            style: OmegaTextStyles.labelMedium.copyWith(
              color: isDark ? OmegaColors.textSecondaryDark : OmegaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: BackupFrequency.values.map((freq) {
              final selected = frequency == freq;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(freq.label),
                  selected: selected,
                  selectedColor: OmegaColors.primary,
                  labelStyle: OmegaTextStyles.labelMedium.copyWith(
                    color: selected
                        ? Colors.white
                        : (isDark
                            ? OmegaColors.textPrimaryDark
                            : OmegaColors.textPrimary),
                  ),
                  onSelected: (_) => onChanged(freq),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final bool isDark;

  const _WarningCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OmegaColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OmegaColors.info.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: OmegaColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Restoring a backup will replace all current messages and settings. '
              'Ensure you have a recent export before restoring.',
              style: OmegaTextStyles.bodySmall.copyWith(
                color: isDark ? OmegaColors.textSecondaryDark : OmegaColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
