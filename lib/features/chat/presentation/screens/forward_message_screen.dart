import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/widgets/omega_avatar.dart';

// ── State & Provider ──────────────────────────────────────────────────────────

@immutable
class ForwardMessagesState {
  final List<Chat> chats;
  final List<int> selectedChatIds;
  final bool isLoading;
  final bool isSending;
  final String searchQuery;
  final String? error;
  final bool sendComplete;

  const ForwardMessagesState({
    this.chats = const [],
    this.selectedChatIds = const [],
    this.isLoading = false,
    this.isSending = false,
    this.searchQuery = '',
    this.error,
    this.sendComplete = false,
  });

  ForwardMessagesState copyWith({
    List<Chat>? chats,
    List<int>? selectedChatIds,
    bool? isLoading,
    bool? isSending,
    String? searchQuery,
    String? error,
    bool? sendComplete,
  }) =>
      ForwardMessagesState(
        chats: chats ?? this.chats,
        selectedChatIds: selectedChatIds ?? this.selectedChatIds,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        searchQuery: searchQuery ?? this.searchQuery,
        error: error,
        sendComplete: sendComplete ?? this.sendComplete,
      );

  List<Chat> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    final q = searchQuery.toLowerCase();
    return chats
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }
}

class ForwardMessageNotifier extends StateNotifier<ForwardMessagesState> {
  final DeltaRpcClient _rpc;
  final String _messageText;

  ForwardMessageNotifier(this._rpc, this._messageText)
      : super(const ForwardMessagesState(isLoading: true)) {
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final ids = await _rpc.getChatListIds();
      final infos = await Future.wait(ids.map(_rpc.getChatInfo));
      final chats = infos.map(_mapChat).toList();
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, error: null);
  }

  void toggleSelection(int chatId) {
    final current = List<int>.from(state.selectedChatIds);
    if (current.contains(chatId)) {
      current.remove(chatId);
    } else {
      current.add(chatId);
    }
    state = state.copyWith(selectedChatIds: current);
  }

  Future<void> sendForward() async {
    if (state.selectedChatIds.isEmpty) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      await Future.wait(
        state.selectedChatIds.map(
          (chatId) => _rpc.sendTextMessage(
            chatId: chatId,
            text: _messageText,
          ),
        ),
      );
      state = state.copyWith(isSending: false, sendComplete: true);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Chat _mapChat(Map<String, dynamic> d) {
    final ts = d['last_message_time'] as int?;
    return Chat(
      id: (d['id'] as num?)?.toInt() ?? 0,
      name: d['name'] as String? ?? '',
      type: switch (d['type'] as int? ?? 100) {
        120 => ChatType.group,
        160 => ChatType.broadcast,
        _ => ChatType.single,
      },
      lastMessage: d['last_message'] as String?,
      lastMessageTime: ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
          : null,
      isVerified: d['is_verified'] as bool? ?? false,
      memberIds:
          List<int>.from(d['contact_ids'] as List? ?? []),
    );
  }
}

/// Provider family keyed by the message text being forwarded.
final forwardMessageProvider = StateNotifierProvider.family<
    ForwardMessageNotifier, ForwardMessagesState, String>(
  (ref, messageText) => ForwardMessageNotifier(
    ref.read(deltaRpcClientProvider),
    messageText,
  ),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class ForwardMessageScreen extends ConsumerStatefulWidget {
  /// The text content of the message to forward.
  final String messageText;

  /// Optional message preview shown at the top of the screen.
  final String? previewText;

  const ForwardMessageScreen({
    super.key,
    required this.messageText,
    this.previewText,
  });

  @override
  ConsumerState<ForwardMessageScreen> createState() =>
      _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends ConsumerState<ForwardMessageScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(forwardMessageProvider(widget.messageText));

    // Pop when forwarding is complete
    ref.listen(forwardMessageProvider(widget.messageText), (prev, next) {
      if (next.sendComplete && !(prev?.sendComplete ?? false)) {
        _showSuccessAndPop(context, next.selectedChatIds.length);
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? OmegaColors.backgroundDark : OmegaColors.backgroundLight,
      appBar: _buildAppBar(context, isDark, state),
      body: Column(
        children: [
          if (widget.previewText != null)
            _MessagePreviewBanner(
              text: widget.previewText!,
              isDark: isDark,
            ),
          _SearchBar(
            controller: _searchController,
            isDark: isDark,
            onChanged: (q) => ref
                .read(forwardMessageProvider(widget.messageText).notifier)
                .setSearch(q),
          ),
          Expanded(
            child: _buildBody(state, isDark),
          ),
          if (state.selectedChatIds.isNotEmpty)
            _SelectedChipsBar(
              selected: state.selectedChatIds,
              chats: state.chats,
              isDark: isDark,
              onRemove: (id) => ref
                  .read(forwardMessageProvider(widget.messageText).notifier)
                  .toggleSelection(id),
            ),
        ],
      ),
      floatingActionButton: state.selectedChatIds.isNotEmpty
          ? _ForwardFab(
              count: state.selectedChatIds.length,
              isSending: state.isSending,
              onPressed: () => ref
                  .read(forwardMessageProvider(widget.messageText).notifier)
                  .sendForward(),
            )
          : null,
    );
  }

  AppBar _buildAppBar(
      BuildContext context, bool isDark, ForwardMessagesState state) {
    return AppBar(
      backgroundColor:
          isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Forward to',
            style: OmegaTextStyles.titleMedium.copyWith(
              color: isDark
                  ? OmegaColors.textPrimaryDark
                  : OmegaColors.textPrimary,
            ),
          ),
          if (state.selectedChatIds.isNotEmpty)
            Text(
              '${state.selectedChatIds.length} selected',
              style: OmegaTextStyles.caption.copyWith(
                color: OmegaColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ForwardMessagesState state, bool isDark) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: OmegaColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load chats',
                style: OmegaTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? OmegaColors.textPrimaryDark
                      : OmegaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: OmegaTextStyles.bodySmall
                    .copyWith(color: OmegaColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final chats = state.filteredChats;
    if (chats.isEmpty) {
      return Center(
        child: Text(
          'No chats found',
          style: OmegaTextStyles.bodyMedium.copyWith(
            color: isDark
                ? OmegaColors.textSecondaryDark
                : OmegaColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: isDark ? OmegaColors.dividerDark : OmegaColors.divider,
      ),
      itemBuilder: (context, i) {
        final chat = chats[i];
        final isSelected = state.selectedChatIds.contains(chat.id);
        return _ChatForwardTile(
          chat: chat,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => ref
              .read(forwardMessageProvider(widget.messageText).notifier)
              .toggleSelection(chat.id),
        );
      },
    );
  }

  void _showSuccessAndPop(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Forwarded to $count ${count == 1 ? 'chat' : 'chats'}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: OmegaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.of(context).pop();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MessagePreviewBanner extends StatelessWidget {
  final String text;
  final bool isDark;

  const _MessagePreviewBanner({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? OmegaColors.inputFillDark
            : OmegaColors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: OmegaColors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forward_rounded,
                  size: 14, color: OmegaColors.primary),
              const SizedBox(width: 4),
              Text(
                'Forwarding',
                style: OmegaTextStyles.labelSmall
                    .copyWith(color: OmegaColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: OmegaTextStyles.bodySmall.copyWith(
              color: isDark
                  ? OmegaColors.textSecondaryDark
                  : OmegaColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: OmegaTextStyles.bodyMedium.copyWith(
          color: isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: OmegaTextStyles.bodyMedium
              .copyWith(color: OmegaColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded,
              color: OmegaColors.textSecondary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: OmegaColors.textSecondary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor:
              isDark ? OmegaColors.inputFillDark : OmegaColors.inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: OmegaColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ChatForwardTile extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ChatForwardTile({
    required this.chat,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          OmegaAvatar(
            name: chat.name,
            size: 48,
            isGroup: chat.type == ChatType.group,
            isVerified: chat.isVerified,
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: OmegaColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.name,
        style: OmegaTextStyles.titleSmall.copyWith(
          color: isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!,
              style: OmegaTextStyles.bodySmall.copyWith(
                color: isDark
                    ? OmegaColors.textSecondaryDark
                    : OmegaColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          : null,
      trailing: chat.type == ChatType.group
          ? _MemberCount(count: chat.memberIds.length, isDark: isDark)
          : null,
      selected: isSelected,
      selectedTileColor: OmegaColors.primary.withOpacity(0.06),
      onTap: onTap,
    );
  }
}

class _MemberCount extends StatelessWidget {
  final int count;
  final bool isDark;

  const _MemberCount({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.group_outlined,
          size: 13,
          color: isDark
              ? OmegaColors.textSecondaryDark
              : OmegaColors.textSecondary,
        ),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: OmegaTextStyles.caption.copyWith(
            color: isDark
                ? OmegaColors.textSecondaryDark
                : OmegaColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SelectedChipsBar extends StatelessWidget {
  final List<int> selected;
  final List<Chat> chats;
  final bool isDark;
  final ValueChanged<int> onRemove;

  const _SelectedChipsBar({
    required this.selected,
    required this.chats,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selectedChats =
        chats.where((c) => selected.contains(c.id)).toList();

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? OmegaColors.dividerDark : OmegaColors.divider,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: selectedChats.length,
        itemBuilder: (context, i) {
          final chat = selectedChats[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onRemove(chat.id),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      OmegaAvatar(name: chat.name, size: 38),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: OmegaColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForwardFab extends StatelessWidget {
  final int count;
  final bool isSending;
  final VoidCallback onPressed;

  const _ForwardFab({
    required this.count,
    required this.isSending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isSending ? null : onPressed,
      backgroundColor: OmegaColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: isSending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.forward_rounded),
      label: Text(
        isSending
            ? 'Sending...'
            : 'Send to $count ${count == 1 ? 'chat' : 'chats'}',
        style: OmegaTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }
}
