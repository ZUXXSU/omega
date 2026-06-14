import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../core/network/delta_rpc_client.dart';
import '../../../../../shared/models/contact.dart';
import '../../../../../shared/widgets/omega_avatar.dart';
import '../../../presentation/providers/chat_list_provider.dart' show chatListProvider;

class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _selectedContacts = <int>{};
  bool _verified = false;
  bool _creating = false;

  // Temp mock contacts
  final _allContacts = [
    Contact(id: 1, email: 'alice@example.com', displayName: 'Alice Johnson', isVerified: true),
    Contact(id: 2, email: 'bob@example.com', displayName: 'Bob Smith'),
    Contact(id: 3, email: 'carol@example.com', displayName: 'Carol White', isVerified: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final chatId = await rpc.createGroupChat(
        name: _nameController.text.trim(),
        verified: _verified,
      );
      for (final contactId in _selectedContacts) {
        await rpc.addContactToChat(chatId, contactId);
      }
      await ref.read(chatListProvider.notifier).refresh();
      if (mounted) {
        context.go('/chats/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: OmegaColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(
            contacts: _allContacts,
            selected: _selectedContacts,
            onToggle: (id) => setState(() {
              _selectedContacts.contains(id)
                  ? _selectedContacts.remove(id)
                  : _selectedContacts.add(id);
            }),
          ),
          _SettingsTab(
            nameController: _nameController,
            verified: _verified,
            onVerifiedToggle: () => setState(() => _verified = !_verified),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final List<Contact> contacts;
  final Set<int> selected;
  final void Function(int) onToggle;

  const _MembersTab({
    required this.contacts,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selected.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contacts.where((c) => selected.contains(c.id)).length,
              itemBuilder: (ctx, i) {
                final contact = contacts.where((c) => selected.contains(c.id)).toList()[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          OmegaAvatar(name: contact.displayName, size: 44),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: GestureDetector(
                              onTap: () => onToggle(contact.id),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(
                                  color: OmegaColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.displayName.split(' ').first,
                        style: OmegaTextStyles.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (selected.isNotEmpty) const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (ctx, i) {
              final contact = contacts[i];
              final isSelected = selected.contains(contact.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => onToggle(contact.id),
                secondary: OmegaAvatar(
                  name: contact.displayName,
                  size: 44,
                  isVerified: contact.isVerified,
                ),
                title: Text(contact.displayName, style: OmegaTextStyles.titleSmall),
                subtitle: Text(contact.email, style: OmegaTextStyles.bodySmall),
                activeColor: OmegaColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final TextEditingController nameController;
  final bool verified;
  final VoidCallback onVerifiedToggle;

  const _SettingsTab({
    required this.nameController,
    required this.verified,
    required this.onVerifiedToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: OmegaColors.inputFill,
                    child: const Icon(Icons.group_rounded, size: 36, color: OmegaColors.textSecondary),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        color: OmegaColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g. Engineering Team',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Verified Group'),
            subtitle: const Text('Only verified members can join. Provides stronger encryption guarantees.'),
            value: verified,
            onChanged: (_) => onVerifiedToggle(),
          ),
          if (verified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OmegaColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OmegaColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: OmegaColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New members must be added via QR scan. Messages are end-to-end encrypted between verified members only.',
                      style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
