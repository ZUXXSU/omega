import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/widgets/omega_avatar.dart';

enum _SearchTab { all, chats, contacts, messages }

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;

  _SearchTab _tab = _SearchTab.all;
  bool _loading = false;
  List<_ChatResult> _chats = [];
  List<_ContactResult> _contacts = [];
  List<_MessageResult> _messages = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        setState(() => _tab = _SearchTab.values[_tabController.index]);
      });
    _focusNode.requestFocus();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.length < 2) {
      setState(() { _chats = []; _contacts = []; _messages = []; });
      return;
    }
    _search(q);
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final rpc = ref.read(deltaRpcClientProvider);
    final q = query.toLowerCase();

    try {
      // Chats
      final chatIds = await rpc.getChatListIds(query: query);
      final chatData = await Future.wait(chatIds.map((id) => rpc.getChatInfo(id)));
      final chats = chatData.map((d) => _ChatResult(
        id: (d['id'] as num?)?.toInt() ?? 0,
        name: d['name'] as String? ?? '',
        lastMessage: d['last_message'] as String?,
        unread: (d['unread'] as num?)?.toInt() ?? 0,
        isGroup: (d['type'] as int? ?? 100) == 120,
      )).toList();

      // Contacts
      final contactIds = await rpc.getContacts(query: query);
      final contactData = await Future.wait(contactIds.map((id) => rpc.getContactInfo(id)));
      final contacts = contactData.map((d) => _ContactResult(
        id: (d['id'] as num?)?.toInt() ?? 0,
        name: d['display_name'] as String? ?? '',
        email: d['addr'] as String? ?? '',
        isVerified: d['is_verified'] as bool? ?? false,
      )).toList();

      // Messages (search in all recent chats)
      final allMsgResults = <_MessageResult>[];
      for (final chatId in chatIds.take(5)) {
        final msgs = await rpc.getMessages(chatId: chatId, limit: 100);
        for (final m in msgs) {
          final text = m['text'] as String? ?? '';
          if (text.toLowerCase().contains(q)) {
            final chat = chatData.firstWhere(
              (c) => (c['id'] as num?)?.toInt() == chatId,
              orElse: () => {},
            );
            allMsgResults.add(_MessageResult(
              messageId: (m['id'] as num?)?.toInt() ?? 0,
              chatId: chatId,
              chatName: chat['name'] as String? ?? 'Chat',
              text: text,
              timestamp: DateTime.fromMillisecondsSinceEpoch((m['ts'] as int? ?? 0) * 1000),
              isOutgoing: m['is_outgoing'] as bool? ?? false,
              query: query,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _chats = chats;
          _contacts = contacts;
          _messages = allMsgResults;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search Omega…',
            hintStyle: OmegaTextStyles.bodyLarge.copyWith(color: OmegaColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          style: OmegaTextStyles.bodyLarge,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () {
              _controller.clear();
              setState(() { _chats = []; _contacts = []; _messages = []; });
            }),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_chats.length + _contacts.length + _messages.length})'),
            Tab(text: 'Chats (${_chats.length})'),
            Tab(text: 'Contacts (${_contacts.length})'),
            Tab(text: 'Messages (${_messages.length})'),
          ],
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _controller.text.length < 2
              ? _SearchHints()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _AllResults(chats: _chats, contacts: _contacts, messages: _messages, query: _controller.text),
                    _ChatResults(chats: _chats),
                    _ContactResults(contacts: _contacts),
                    _MessageResults(messages: _messages),
                  ],
                ),
    );
  }
}

// ── Result models ──────────────────────────────────────────────────────────

class _ChatResult {
  final int id;
  final String name;
  final String? lastMessage;
  final int unread;
  final bool isGroup;
  const _ChatResult({required this.id, required this.name, this.lastMessage, required this.unread, required this.isGroup});
}

class _ContactResult {
  final int id;
  final String name;
  final String email;
  final bool isVerified;
  const _ContactResult({required this.id, required this.name, required this.email, required this.isVerified});
}

class _MessageResult {
  final int messageId;
  final int chatId;
  final String chatName;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final String query;
  const _MessageResult({required this.messageId, required this.chatId, required this.chatName, required this.text, required this.timestamp, required this.isOutgoing, required this.query});
}

// ── Hint screen ────────────────────────────────────────────────────────────

class _SearchHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, size: 72, color: OmegaColors.textDisabled),
          const SizedBox(height: 16),
          Text('Search chats, contacts and messages',
              style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Type at least 2 characters',
              style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textDisabled)),
        ],
      ),
    );
  }
}

// ── All results ─────────────────────────────────────────────────────────────

class _AllResults extends StatelessWidget {
  final List<_ChatResult> chats;
  final List<_ContactResult> contacts;
  final List<_MessageResult> messages;
  final String query;

  const _AllResults({required this.chats, required this.contacts, required this.messages, required this.query});

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty && contacts.isEmpty && messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: OmegaColors.textDisabled),
            const SizedBox(height: 12),
            Text('No results for "$query"',
                style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView(
      children: [
        if (chats.isNotEmpty) ...[
          _SectionHeader('Chats'),
          ..._ChatResults(chats: chats.take(3).toList()).buildTiles(context),
        ],
        if (contacts.isNotEmpty) ...[
          _SectionHeader('Contacts'),
          ..._ContactResults(contacts: contacts.take(3).toList()).buildTiles(context),
        ],
        if (messages.isNotEmpty) ...[
          _SectionHeader('Messages'),
          ..._MessageResults(messages: messages.take(5).toList()).buildTiles(context),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: OmegaTextStyles.labelSmall.copyWith(
          color: OmegaColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Chat results ───────────────────────────────────────────────────────────

class _ChatResults extends StatelessWidget {
  final List<_ChatResult> chats;
  const _ChatResults({required this.chats});

  List<Widget> buildTiles(BuildContext context) => chats.map((c) => ListTile(
    leading: OmegaAvatar(name: c.name, size: 44, isGroup: c.isGroup),
    title: Text(c.name, style: OmegaTextStyles.titleSmall),
    subtitle: c.lastMessage != null ? Text(c.lastMessage!, style: OmegaTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
    trailing: c.unread > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: OmegaColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 11)),
          )
        : null,
    onTap: () => context.go('/chats/${c.id}'),
  )).toList();

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: buildTiles(context),
  );
}

// ── Contact results ────────────────────────────────────────────────────────

class _ContactResults extends StatelessWidget {
  final List<_ContactResult> contacts;
  const _ContactResults({required this.contacts});

  List<Widget> buildTiles(BuildContext context) => contacts.map((c) => ListTile(
    leading: OmegaAvatar(name: c.name, size: 44, isVerified: c.isVerified),
    title: Row(children: [
      if (c.isVerified) const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.verified_rounded, size: 14, color: OmegaColors.primary),
      ),
      Text(c.name, style: OmegaTextStyles.titleSmall),
    ]),
    subtitle: Text(c.email, style: OmegaTextStyles.bodySmall),
    onTap: () => context.go('/contacts/${c.id}'),
  )).toList();

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: buildTiles(context),
  );
}

// ── Message results ────────────────────────────────────────────────────────

class _MessageResults extends StatelessWidget {
  final List<_MessageResult> messages;
  const _MessageResults({required this.messages});

  List<Widget> buildTiles(BuildContext context) => messages.map((m) {
    final q = m.query.toLowerCase();
    final idx = m.text.toLowerCase().indexOf(q);
    final before = idx > 0 ? m.text.substring(0, idx) : '';
    final match  = idx >= 0 ? m.text.substring(idx, idx + q.length) : m.text;
    final after  = idx >= 0 && idx + q.length < m.text.length ? m.text.substring(idx + q.length) : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: OmegaColors.primary.withOpacity(0.1),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: OmegaColors.primary, size: 18),
      ),
      title: Text(m.chatName, style: OmegaTextStyles.labelMedium.copyWith(color: OmegaColors.textSecondary)),
      subtitle: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textPrimary),
          children: [
            TextSpan(text: before),
            TextSpan(text: match, style: const TextStyle(backgroundColor: Color(0x33FFD600), fontWeight: FontWeight.w600)),
            TextSpan(text: after),
          ],
        ),
      ),
      trailing: Text(timeago.format(m.timestamp, locale: 'en_short'), style: OmegaTextStyles.caption),
      onTap: () => context.go('/chats/${m.chatId}'),
    );
  }).toList();

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: buildTiles(context),
  );
}
