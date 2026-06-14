import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/widgets/omega_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_app_bar.dart';

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
    // TODO: dispatch send message action via provider
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
    // TODO: wire to real messages provider
    final messages = _mockMessages;

    if (messages.isEmpty) {
      return const _EmptyChatState();
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final prevMsg = i < messages.length - 1 ? messages[i + 1] : null;
        final showAvatar = !msg.isOutgoing &&
            (prevMsg == null || prevMsg.fromContactId != msg.fromContactId);

        return MessageBubble(
          message: msg,
          showAvatar: showAvatar,
        );
      },
    );
  }
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

// Temp mock
final _mockMessages = [
  Message(
    id: 1,
    chatId: 1,
    fromContactId: 0,
    type: MessageType.text,
    state: MessageState.read,
    text: 'Hey! Are you coming to the meeting tomorrow?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    isOutgoing: true,
  ),
  Message(
    id: 2,
    chatId: 1,
    fromContactId: 1,
    type: MessageType.text,
    state: MessageState.delivered,
    text: 'Yes, definitely! What time does it start?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    isOutgoing: false,
  ),
  Message(
    id: 3,
    chatId: 1,
    fromContactId: 0,
    type: MessageType.text,
    state: MessageState.read,
    text: '10am. I\'ll send the agenda shortly.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    isOutgoing: true,
  ),
  Message(
    id: 4,
    chatId: 1,
    fromContactId: 1,
    type: MessageType.text,
    state: MessageState.delivered,
    text: 'Perfect, see you tomorrow! 🎉',
    timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    isOutgoing: false,
  ),
];
