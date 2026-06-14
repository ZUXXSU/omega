import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

/// Enterprise MDM Admin Policy Screen.
/// Reads from platform MDM channel (AppConfig on Android, MDM on iOS).
/// Shows current enforced policies and allows admin to review/clear.
class AdminPolicyScreen extends ConsumerWidget {
  const AdminPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Policy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
            tooltip: 'Reload policies',
          ),
        ],
      ),
      body: ListView(
        children: [
          _StatusBanner(),
          const SizedBox(height: 8),
          _PolicySection(
            title: 'Account Policies',
            policies: [
              _PolicyItem(
                key: 'addr',
                label: 'Preconfigured Email',
                description: 'Forces a specific email address',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'mail_server',
                label: 'IMAP Server',
                description: 'Locks IMAP server address',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'send_server',
                label: 'SMTP Server',
                description: 'Locks SMTP server address',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'mail_security',
                label: 'TLS Required',
                description: 'Forces TLS-only connections',
                value: null,
                enforced: false,
              ),
            ],
          ),
          _PolicySection(
            title: 'Feature Restrictions',
            policies: [
              _PolicyItem(
                key: 'show_emails',
                label: 'Show Classic Emails',
                description: 'Allow/block showing non-Omega emails',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'media_quality',
                label: 'Media Quality',
                description: 'Default quality for sent images/video',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'only_one_account',
                label: 'Single Account Mode',
                description: 'Prevents adding additional accounts',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'disable_backup',
                label: 'Disable Backup Export',
                description: 'Prevents users from exporting account backups',
                value: null,
                enforced: false,
              ),
            ],
          ),
          _PolicySection(
            title: 'Security Policies',
            policies: [
              _PolicyItem(
                key: 'require_biometric',
                label: 'Require Biometric Lock',
                description: 'Force biometric authentication on open',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'screen_security',
                label: 'Screen Security',
                description: 'Block screenshots and app-switcher preview',
                value: null,
                enforced: false,
              ),
              _PolicyItem(
                key: 'auto_delete_days',
                label: 'Message Auto-Delete',
                description: 'Enforce message retention policy (days)',
                value: null,
                enforced: false,
              ),
            ],
          ),
          _PolicySection(
            title: 'QR Provisioning',
            policies: [
              _PolicyItem(
                key: 'provisioning_url',
                label: 'Provisioning URL',
                description: 'Auto-configure account from URL on first launch',
                value: null,
                enforced: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _AuditLogSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: read from platform MDM channel
    const isManaged = false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isManaged
            ? OmegaColors.primary.withOpacity(0.08)
            : OmegaColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isManaged
              ? OmegaColors.primary.withOpacity(0.2)
              : OmegaColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isManaged ? Icons.verified_user_rounded : Icons.info_outline_rounded,
            color: isManaged ? OmegaColors.primary : OmegaColors.warning,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isManaged ? 'Device Managed' : 'Not Managed',
                  style: OmegaTextStyles.titleSmall.copyWith(
                    color: isManaged ? OmegaColors.primary : OmegaColors.warning,
                  ),
                ),
                Text(
                  isManaged
                      ? 'This device is managed by your organization\'s MDM.'
                      : 'No MDM configuration detected. Enterprise features are inactive.',
                  style: OmegaTextStyles.bodySmall.copyWith(
                    color: OmegaColors.textSecondary,
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

class _PolicyItem {
  final String key;
  final String label;
  final String description;
  final String? value;
  final bool enforced;

  const _PolicyItem({
    required this.key,
    required this.label,
    required this.description,
    this.value,
    required this.enforced,
  });
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<_PolicyItem> policies;

  const _PolicySection({required this.title, required this.policies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: OmegaTextStyles.labelSmall.copyWith(
              color: OmegaColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: policies
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        _PolicyTile(item: e.value),
                        if (e.key < policies.length - 1)
                          const Divider(height: 1),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final _PolicyItem item;

  const _PolicyTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: item.enforced
              ? OmegaColors.primary.withOpacity(0.1)
              : OmegaColors.inputFill,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          item.enforced ? Icons.lock_rounded : Icons.lock_open_rounded,
          color: item.enforced ? OmegaColors.primary : OmegaColors.textDisabled,
          size: 18,
        ),
      ),
      title: Text(item.label, style: OmegaTextStyles.bodyLarge),
      subtitle: Text(
        item.enforced ? (item.value ?? 'Enforced') : item.description,
        style: OmegaTextStyles.bodySmall.copyWith(
          color: item.enforced ? OmegaColors.primary : OmegaColors.textSecondary,
        ),
      ),
      trailing: item.enforced
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: OmegaColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ENFORCED',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            )
          : const Text(
              'NOT SET',
              style: TextStyle(color: OmegaColors.textDisabled, fontSize: 10, fontWeight: FontWeight.w500),
            ),
    );
  }
}

class _AuditLogSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'AUDIT LOG',
            style: OmegaTextStyles.labelSmall.copyWith(
              color: OmegaColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.article_outlined, color: OmegaColors.primary),
                title: const Text('Export Audit Log'),
                subtitle: const Text('Download policy and compliance events'),
                trailing: const Icon(Icons.download_outlined),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_rounded, color: OmegaColors.secondary),
                title: const Text('Compliance Status'),
                subtitle: const Text('View policy compliance report'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
