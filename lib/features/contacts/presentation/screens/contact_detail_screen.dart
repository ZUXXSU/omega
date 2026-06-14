import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../shared/widgets/omega_avatar.dart';

class ContactDetailScreen extends ConsumerWidget {
  final int contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: wire to contact provider
    const name = 'Alice Johnson';
    const email = 'alice@example.com';
    const isVerified = true;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: OmegaColors.primary.withOpacity(0.08),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 60),
                      OmegaAvatar(
                        name: name,
                        size: 96,
                        isVerified: isVerified,
                      ),
                      SizedBox(height: 12),
                      Text(name, style: OmegaTextStyles.titleLarge),
                      SizedBox(height: 4),
                      Text(email, style: OmegaTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
                tooltip: 'Edit',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActionRow(contactId: contactId),
                  const SizedBox(height: 24),
                  const _InfoSection(),
                  const SizedBox(height: 16),
                  const _SharedMediaSection(),
                  const SizedBox(height: 16),
                  const _DangerZone(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final int contactId;
  const _ActionRow({required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message',
          onTap: () => context.go('/chats/$contactId'),
        ),
        _ActionButton(
          icon: Icons.call_outlined,
          label: 'Call',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.videocam_outlined,
          label: 'Video',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.search_rounded,
          label: 'Search',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: OmegaColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: OmegaColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: OmegaTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('alice@example.com'),
            subtitle: const Text('Email'),
            trailing: const Icon(Icons.copy_rounded, size: 18, color: OmegaColors.textSecondary),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Verified contact'),
            subtitle: const Text('End-to-end encryption active'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Available'),
            subtitle: const Text('Status message'),
          ),
        ],
      ),
    );
  }
}

class _SharedMediaSection extends StatelessWidget {
  const _SharedMediaSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.perm_media_outlined),
        title: const Text('Shared Media'),
        subtitle: const Text('Photos, videos, files'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.volume_off_outlined),
            title: const Text('Mute Notifications'),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: OmegaColors.error),
            title: const Text('Block Contact', style: TextStyle(color: OmegaColors.error)),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: OmegaColors.error),
            title: const Text('Delete Contact', style: TextStyle(color: OmegaColors.error)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
