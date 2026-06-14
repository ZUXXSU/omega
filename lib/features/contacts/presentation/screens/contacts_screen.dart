import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../shared/models/contact.dart';
import '../../../../shared/widgets/omega_avatar.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Blocked'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _showSearch,
            tooltip: 'Search contacts',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _addContact,
            tooltip: 'Add contact',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContactsList(
            contacts: _mockContacts.where((c) => !c.isBlocked).toList(),
            searchQuery: _searchQuery,
          ),
          _ContactsList(
            contacts: _mockContacts.where((c) => c.isBlocked).toList(),
            searchQuery: _searchQuery,
            isBlocked: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Contact'),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _ContactSearchDelegate(_mockContacts),
    );
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (ctx) => const _AddContactDialog(),
    );
  }
}

class _ContactsList extends StatelessWidget {
  final List<Contact> contacts;
  final String searchQuery;
  final bool isBlocked;

  const _ContactsList({
    required this.contacts,
    required this.searchQuery,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? contacts
        : contacts.where((c) =>
            c.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c.email.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 64, color: OmegaColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              isBlocked ? 'No blocked contacts' : 'No contacts yet',
              style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) => _ContactTile(contact: filtered[i]),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;

  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: OmegaAvatar(
        name: contact.displayName,
        imageUrl: contact.profileImagePath,
        size: 48,
        isVerified: contact.isVerified,
        isOnline: contact.isOnline,
      ),
      title: Row(
        children: [
          if (contact.isVerified)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.verified_rounded, size: 14, color: OmegaColors.primary),
            ),
          Text(contact.displayName, style: OmegaTextStyles.titleSmall),
          if (contact.isBot)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.smart_toy_outlined, size: 14, color: OmegaColors.textSecondary),
            ),
        ],
      ),
      subtitle: Text(
        contact.statusMessage ?? contact.email,
        style: OmegaTextStyles.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: contact.isBlocked
          ? TextButton(
              onPressed: () {},
              child: const Text('Unblock'),
            )
          : null,
      onTap: () => context.go('/contacts/${contact.id}'),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'contact@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Scan QR Code'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ContactSearchDelegate extends SearchDelegate<Contact?> {
  final List<Contact> contacts;

  _ContactSearchDelegate(this.contacts);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = contacts.where((c) =>
        c.displayName.toLowerCase().contains(query.toLowerCase()) ||
        c.email.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) => ListTile(
        leading: OmegaAvatar(name: results[i].displayName, size: 40),
        title: Text(results[i].displayName),
        subtitle: Text(results[i].email),
        onTap: () => close(ctx, results[i]),
      ),
    );
  }
}

// Temp mock
final _mockContacts = [
  Contact(id: 1, email: 'alice@example.com', displayName: 'Alice Johnson', isVerified: true, isOnline: true, statusMessage: 'Available'),
  Contact(id: 2, email: 'bob@example.com', displayName: 'Bob Smith', isOnline: false),
  Contact(id: 3, email: 'carol@example.com', displayName: 'Carol White', isVerified: true),
  Contact(id: 4, email: 'dave@example.com', displayName: 'Dave Brown', isBlocked: true),
];
