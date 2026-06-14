import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/widgets/omega_avatar.dart';

// ── Data models ───────────────────────────────────────────────────────────────

@immutable
class StarredMessage {
  final Message message;
  final String chatName;
  final bool isChatGroup;
  final String senderName;

  const StarredMessage({
    required this.message,
    required this.chatName,
    required this.isChatGroup,
    required this.senderName,
  });
}

@immutable
class StarredMessagesState {
  final Map<String, List<StarredMessage>> groupedByChat;
  final bool isLoading;
  final String? error;

  const StarredMessagesState({
    this.groupedByChat = const {},
    this.isLoading = false,
    this.error,
  });

  StarredMessagesState copyWith({
    Map<String, List<StarredMessage>>? groupedByChat,
    bool? isLoading,
    String? error,
  }) =>
      StarredMessagesState(
        groupedByChat: groupedByChat ?? this.groupedByChat,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get isEmpty => groupedByChat.values.every((list) => list.isEmpty);
}

// ── Provider ──────────────────────────────────────────────────────────────────

class StarredMessagesNotifier extends StateNotifier<StarredMessagesState> {
  final DeltaRpcClient _rpc;

  StarredMessagesNotifier(this._rpc)
      : super(const StarredMessagesState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final chatIds = await _rpc.getChatListIds();
      final grouped = <String, List<StarredMessage>>{};

      await Future.wait(chatIds.map((chatId) async {
        final chatInfo = await _rpc.getChatInfo(chatId);
        final chatName = chatInfo['name'] as String? ?? 'Unknown';
        final isGroup = (chatInfo['type'] as int? ?? 100) == 120;
        final messages =
            await _rpc.getMessages(chatId: chatId, limit: 50);

        // Dev seed: treat every message with id % 3 == 0 as starred.
        // In production this would be filtered by a starred flag.
        final starred = messages
            .where((m) => ((m['id'] as num?)?.toInt() ?? 0) % 3 == 0)
            .toList();

        if (starred.isNotEmpty) {
          final contactIds =
              List<int>.from(chatInfo['contact_ids'] as List? ?? []);

          final mappedMessages = await Future.wait(starred.map((m) async {
            final fromId =
                (m['from'] as num?)?.toInt() ?? 0;
            String senderName = 'You';
            if (fromId != 0 && contactIds.contains(fromId)) {
              final contact = await _rpc.getContactInfo(fromId);
              senderName = contact['display_name'] as String? ??
                  contact['addr'] as String? ??
                  'Unknown';
            }

            final msg = Message(
              id: (m['id'] as num?)?.toInt() ?? 0,
              chatId: chatId,
              fromContactId: fromId,
              type: _mapType(m['type'] as int? ?? 10),
              state: _mapState(m['state'] as int? ?? 0),
              text: m['text'] as String?,
              filePath: m['file'] as String?,
              fileMimeType: m['mime'] as String?,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  ((m['ts'] as num?)?.toInt() ?? 0) * 1000),
              isOutgoing: m['is_outgoing'] as bool? ?? false,
              isForwarded: m['is_forwarded'] as bool? ?? false,
            );

            return StarredMessage(
              message: msg,
              chatName: chatName,
              isChatGroup: isGroup,
              senderName: senderName,
            );
          }));

          grouped[chatName] = mappedMessages;
        }
      }));

      state = state.copyWith(groupedByChat: grouped, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _load();
  }

  Future<void> unstarMessage(int messageId, String chatName) async {
    final updated = Map<String, List<StarredMessage>>.from(state.groupedByChat);
    final list = List<StarredMessage>.from(updated[chatName] ?? []);
    list.removeWhere((m) => m.message.id == messageId);
    if (list.isEmpty) {
      updated.remove(chatName);
    } else {
      updated[chatName] = list;
    }
    state = state.copyWith(groupedByChat: updated);
  }

  MessageType _mapType(int t) => switch (t) {
        20 => MessageType.image,
        21 => MessageType.video,
        40 => MessageType.audio,
        41 => MessageType.voice,
        60 => MessageType.file,
        _ => MessageType.text,
      };

  MessageState _mapState(int s) => switch (s) {
        1 => MessageState.sent,
        2 => MessageState.delivered,
        3 => MessageState.read,
        4 => MessageState.failed,
        _ => MessageState.pending,
      };
}

final starredMessagesProvider =
    StateNotifierProvider<StarredMessagesNotifier, StarredMessagesState>(
  (ref) => StarredMessagesNotifier(ref.read(deltaRpcClientProvider)),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class StarredMessagesScreen extends ConsumerWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(starredMessagesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? OmegaColors.backgroundDark : OmegaColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Starred Messages',
          style: OmegaTextStyles.titleMedium.copyWith(
            color: isDark
                ? OmegaColors.textPrimaryDark
                : OmegaColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(starredMessagesProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, ref, state, isDark),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      StarredMessagesState state, bool isDark) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.isEmpty) {
      return _ErrorState(error: state.error!, isDark: isDark,
          onRetry: () => ref.read(starredMessagesProvider.notifier).refresh());
    }

    if (state.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    final chatNames = state.groupedByChat.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => ref.read(starredMessagesProvider.notifier).refresh(),
      color: OmegaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: chatNames.length,
        itemBuilder: (context, i) {
          final chatName = chatNames[i];
          final messages = state.groupedByChat[chatName]!;
          return _ChatGroup(
            chatName: chatName,
            messages: messages,
            isDark: isDark,
            onUnstar: (msgId) => ref
                .read(starredMessagesProvider.notifier)
                .unstarMessage(msgId, chatName),
            onNavigate: (msg) =>
                _navigateToMessage(context, msg),
          );
        },
      ),
    );
  }

  void _navigateToMessage(BuildContext context, StarredMessage sm) {
    // Navigation to the original chat+message.
    // Uses Navigator.pushNamed or go_router — kept generic to avoid
    // introducing a dependency on the router from this widget.
    Navigator.of(context).pop({'chatId': sm.message.chatId, 'messageId': sm.message.id});
  }
}

// ── Chat group section ────────────────────────────────────────────────────────

class _ChatGroup extends StatelessWidget {
  final String chatName;
  final List<StarredMessage> messages;
  final bool isDark;
  final ValueChanged<int> onUnstar;
  final ValueChanged<StarredMessage> onNavigate;

  const _ChatGroup({
    required this.chatName,
    required this.messages,
    required this.isDark,
    required this.onUnstar,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupHeader(chatName: chatName, count: messages.length, isDark: isDark),
        ...messages.map((sm) => _StarredMessageTile(
              starred: sm,
              isDark: isDark,
              onUnstar: () => onUnstar(sm.message.id),
              onTap: () => onNavigate(sm),
            )),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String chatName;
  final int count;
  final bool isDark;

  const _GroupHeader({
    required this.chatName,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          OmegaAvatar(name: chatName, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chatName,
              style: OmegaTextStyles.labelLarge.copyWith(
                color: OmegaColors.primary,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: OmegaColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: OmegaTextStyles.labelSmall
                  .copyWith(color: OmegaColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual message tile ───────────────────────────────────────────────────

class _StarredMessageTile extends StatelessWidget {
  final StarredMessage starred;
  final bool isDark;
  final VoidCallback onUnstar;
  final VoidCallback onTap;

  const _StarredMessageTile({
    required this.starred,
    required this.isDark,
    required this.onUnstar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final msg = starred.message;
    final cardColor = isDark ? OmegaColors.cardDark : OmegaColors.cardLight;
    final subtitleColor = isDark
        ? OmegaColors.textSecondaryDark
        : OmegaColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MessageTypeIcon(type: msg.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      starred.senderName,
                      style: OmegaTextStyles.labelMedium.copyWith(
                        color: isDark
                            ? OmegaColors.textPrimaryDark
                            : OmegaColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTimestamp(msg.timestamp),
                    style: OmegaTextStyles.caption
                        .copyWith(color: subtitleColor),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onUnstar,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: OmegaColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _MessagePreview(message: msg, isDark: isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 12, color: subtitleColor),
                  const SizedBox(width: 4),
                  Text(
                    starred.chatName,
                    style: OmegaTextStyles.caption
                        .copyWith(color: subtitleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Go to message',
                          style: OmegaTextStyles.caption.copyWith(
                            color: OmegaColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: OmegaColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inDays == 0) {
      return DateFormat.jm().format(ts);
    } else if (diff.inDays < 7) {
      return DateFormat.EEEE().format(ts);
    } else {
      return DateFormat.MMMd().format(ts);
    }
  }
}

class _MessageTypeIcon extends StatelessWidget {
  final MessageType type;

  const _MessageTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      MessageType.image => (Icons.image_outlined, OmegaColors.info),
      MessageType.video => (Icons.videocam_outlined, OmegaColors.info),
      MessageType.audio || MessageType.voice =>
        (Icons.mic_outlined, OmegaColors.secondary),
      MessageType.file => (Icons.attach_file_rounded, OmegaColors.textSecondary),
      _ => (Icons.chat_bubble_outline_rounded, OmegaColors.primary),
    };

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  final Message message;
  final bool isDark;

  const _MessagePreview({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? OmegaColors.textPrimaryDark
        : OmegaColors.textPrimary;

    final previewText = _getPreviewText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? OmegaColors.inputFillDark
            : OmegaColors.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        previewText,
        style: OmegaTextStyles.bodySmall.copyWith(color: textColor),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getPreviewText() {
    if (message.text != null && message.text!.isNotEmpty) {
      return message.text!;
    }
    return switch (message.type) {
      MessageType.image => '📷 Photo',
      MessageType.video => '🎥 Video',
      MessageType.audio => '🎵 Audio',
      MessageType.voice => '🎤 Voice message',
      MessageType.file =>
        '📎 ${message.fileName ?? 'File'}',
      MessageType.gif => '🎞 GIF',
      MessageType.location => '📍 Location',
      _ => '(no text)',
    };
  }
}

// ── Empty & Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: OmegaColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 40,
                color: OmegaColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No starred messages',
              style: OmegaTextStyles.titleMedium.copyWith(
                color: isDark
                    ? OmegaColors.textPrimaryDark
                    : OmegaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Long-press any message and choose "Star" to save it here.',
              style: OmegaTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? OmegaColors.textSecondaryDark
                    : OmegaColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: OmegaColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load starred messages',
              style: OmegaTextStyles.titleSmall.copyWith(
                color: isDark
                    ? OmegaColors.textPrimaryDark
                    : OmegaColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: OmegaTextStyles.bodySmall
                  .copyWith(color: OmegaColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OmegaColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
