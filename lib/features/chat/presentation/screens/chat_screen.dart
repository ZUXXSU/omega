import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/day_separator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await ref.read(chatMessagesProvider(widget.chatId).notifier).sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(chatId: widget.chatId),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _MessageList(
                  chatId: widget.chatId,
                  scrollController: _scrollController,
                ),
                const Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: TypingIndicator(typingNames: []),
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: OmegaColors.surfaceLight,
                      foregroundColor: OmegaColors.primary,
                      elevation: 2,
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
              ],
            ),
          ),
          ChatInputBar(
            controller: _inputController,
            focusNode: _focusNode,
            chatId: widget.chatId,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  final int chatId;
  final ScrollController scrollController;

  const _MessageList({required this.chatId, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatMessagesProvider(chatId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}', style: const TextStyle(color: OmegaColors.error)));
    }
    if (state.messages.isEmpty) {
      return const _EmptyChatState();
    }

    final messages = state.messages;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification && scrollController.position.extentAfter < 200) {
          ref.read(chatMessagesProvider(chatId).notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 48),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final msg = messages[i];
          final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;

          final showDaySep = nextMsg == null ||
              !_sameDay(msg.timestamp, nextMsg.timestamp);
          final showAvatar = !msg.isOutgoing &&
              (nextMsg == null || nextMsg.fromContactId != msg.fromContactId);

          if (msg.isInfo) {
            return SystemInfoMessage(text: msg.text ?? '');
          }

          return Column(
            children: [
              if (showDaySep) DaySeparator(date: msg.timestamp),
              MessageBubble(message: msg, showAvatar: showAvatar),
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: OmegaColors.textDisabled),
          const SizedBox(height: 16),
          Text('No messages yet', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Send the first message',
            style: OmegaTextStyles.bodyMedium.copyWith(color: OmegaColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

