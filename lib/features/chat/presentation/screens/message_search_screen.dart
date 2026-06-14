import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/message.dart';

class MessageSearchScreen extends ConsumerStatefulWidget {
  final int chatId;
  final String chatName;

  const MessageSearchScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  ConsumerState<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends ConsumerState<MessageSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<_SearchResult> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    _search(q);
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      // In production: use rpc.searchMessages(chatId, query)
      // Dev mode: filter in-memory messages
      final rpc = ref.read(deltaRpcClientProvider);
      final raw = await rpc.getMessages(chatId: widget.chatId, limit: 200);
      final q = query.toLowerCase();
      final matched = raw.where((m) =>
          (m['text'] as String? ?? '').toLowerCase().contains(q)).toList();
      if (mounted) {
        setState(() {
          _results = matched.map((m) => _SearchResult(
            messageId: (m['id'] as num?)?.toInt() ?? 0,
            text: m['text'] as String? ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch((m['ts'] as int? ?? 0) * 1000),
            isOutgoing: m['is_outgoing'] as bool? ?? false,
            query: query,
          )).toList();
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
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search in ${widget.chatName}',
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
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _build(),
    );
  }

  Widget _build() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, size: 64, color: OmegaColors.textDisabled),
            const SizedBox(height: 12),
            Text('Type to search messages', style: OmegaTextStyles.bodyLarge.copyWith(color: OmegaColors.textSecondary)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: OmegaColors.textDisabled),
            const SizedBox(height: 12),
            Text('No messages found', style: OmegaTextStyles.bodyLarge.copyWith(color: OmegaColors.textSecondary)),
            const SizedBox(height: 4),
            Text('"${_controller.text}"', style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textDisabled)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _SearchResultTile(result: _results[i]),
    );
  }
}

class _SearchResult {
  final int messageId;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final String query;

  const _SearchResult({
    required this.messageId,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    required this.query,
  });
}

class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final q = result.query.toLowerCase();
    final text = result.text;
    final idx = text.toLowerCase().indexOf(q);
    final before = idx > 0 ? text.substring(0, idx) : '';
    final match = idx >= 0 ? text.substring(idx, idx + q.length) : text;
    final after = idx >= 0 && idx + q.length < text.length
        ? text.substring(idx + q.length)
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: OmegaColors.primary.withOpacity(0.1),
        child: Icon(
          result.isOutgoing ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: OmegaColors.primary,
          size: 18,
        ),
      ),
      title: RichText(
        text: TextSpan(
          style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textPrimary),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: match,
              style: const TextStyle(
                backgroundColor: Color(0x33FFD600),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        timeago.format(result.timestamp),
        style: OmegaTextStyles.caption,
      ),
      onTap: () => Navigator.pop(context, result.messageId),
    );
  }
}
