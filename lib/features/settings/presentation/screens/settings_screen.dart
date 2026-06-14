import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../shared/widgets/omega_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _ProfileTile(),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Preferences',
            items: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: Colors.red,
                title: 'Notifications',
                subtitle: 'Sounds, badges, alerts',
                onTap: () => context.go(RouteConstants.notificationSettings),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: Colors.blue,
                title: 'Privacy & Security',
                subtitle: 'Read receipts, blocked contacts',
                onTap: () => context.go(RouteConstants.privacySettings),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: Colors.purple,
                title: 'Appearance',
                subtitle: 'Theme, font size, wallpapers',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                iconColor: Colors.green,
                title: 'Profile',
                subtitle: 'Name, photo, status',
                onTap: () => context.go(RouteConstants.profileSettings),
              ),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: Colors.orange,
                title: 'Email Account',
                subtitle: 'IMAP/SMTP configuration',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.backup_rounded,
                iconColor: Colors.teal,
                title: 'Backup & Restore',
                subtitle: 'Export and import your data',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Enterprise',
            items: [
              _SettingsTile(
                icon: Icons.business_outlined,
                iconColor: Colors.indigo,
                title: 'Admin Policy',
                subtitle: 'Managed configuration',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.qr_code_rounded,
                iconColor: Colors.brown,
                title: 'QR Code Invite',
                subtitle: 'Share your contact QR',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Advanced',
            items: [
              _SettingsTile(
                icon: Icons.tune_rounded,
                iconColor: Colors.grey,
                title: 'Advanced Settings',
                subtitle: 'Developer and debug options',
                onTap: () => context.go(RouteConstants.advancedSettings),
              ),
              _SettingsTile(
                icon: Icons.network_check_rounded,
                iconColor: Colors.cyan,
                title: 'Connectivity Test',
                subtitle: 'Check server connection',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.bug_report_outlined,
                iconColor: Colors.deepOrange,
                title: 'Logs & Diagnostics',
                subtitle: 'Send logs to support',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Help',
            items: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                iconColor: Colors.lightBlue,
                title: 'FAQ',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.blueGrey,
                title: 'About Omega',
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Omega',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Omega. All rights reserved.',
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const OmegaAvatar(name: 'You', size: 56),
      title: const Text('Your Name', style: OmegaTextStyles.titleMedium),
      subtitle: const Text('you@example.com', style: OmegaTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(RouteConstants.profileSettings),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

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
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor = OmegaColors.primary,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: OmegaTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: OmegaTextStyles.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: OmegaColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
