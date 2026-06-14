import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../shared/models/chat.dart';
import '../../../../shared/widgets/omega_avatar.dart';
import '../../presentation/providers/chat_list_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omega'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(RouteConstants.globalSearch),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showMenu(context),
            tooltip: 'Menu',
          ),
        ],
      ),
      body: const _ChatListBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(RouteConstants.contacts),
        tooltip: 'New Chat',
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _ChatListMenu(),
    );
  }
}

class _ChatListBody extends ConsumerWidget {
  const _ChatListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: OmegaColors.error),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: OmegaColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(chatListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
      child: ListView(
        children: [
          if (state.archivedChats.isNotEmpty)
            _ArchivedBanner(count: state.archivedChats.length),
          if (state.chats.isEmpty)
            const _EmptyChatList()
          else
            ...state.chats.map((chat) => _ChatTile(chat: chat)),
        ],
      ),
    );
  }
}

class _EmptyChatList extends StatelessWidget {
  const _EmptyChatList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 72, color: OmegaColors.textDisabled),
          const SizedBox(height: 16),
          Text('No chats yet', style: OmegaTextStyles.titleMedium.copyWith(color: OmegaColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Start a conversation by tapping +', style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textDisabled)),
        ],
      ),
    );
  }
}

class _ArchivedBanner extends StatelessWidget {
  final int count;
  const _ArchivedBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: OmegaColors.inputFill,
        child: Icon(Icons.archive_outlined, color: OmegaColors.textSecondary),
      ),
      title: Text('Archived', style: OmegaTextStyles.titleSmall),
      subtitle: Text('$count chats', style: OmegaTextStyles.caption),
      trailing: const Icon(Icons.chevron_right_rounded, color: OmegaColors.textSecondary),
      onTap: () {},
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: OmegaAvatar(
        name: chat.name,
        imageUrl: chat.profileImagePath,
        size: 52,
        isGroup: chat.type == ChatType.group,
        isVerified: chat.isVerified,
      ),
      title: Row(
        children: [
          if (chat.isVerified)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.verified_rounded, size: 14, color: OmegaColors.primary),
            ),
          Expanded(
            child: Text(
              chat.name,
              style: OmegaTextStyles.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessageTime != null)
            Text(
              timeago.format(chat.lastMessageTime!, locale: 'en_short'),
              style: OmegaTextStyles.caption.copyWith(
                color: chat.unreadCount > 0 ? OmegaColors.primary : OmegaColors.textSecondary,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chat.isMuted)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.volume_off_rounded, size: 12, color: OmegaColors.textSecondary),
            ),
          Expanded(
            child: Text(
              chat.lastMessage ?? '',
              style: OmegaTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: chat.isMuted ? OmegaColors.textSecondary : OmegaColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      onTap: () => context.go('/chats/${chat.id}'),
      onLongPress: () => _showChatOptions(context, chat),
    );
  }

  void _showChatOptions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ChatOptions(chat: chat),
    );
  }
}

class _ChatOptions extends ConsumerWidget {
  final Chat chat;
  const _ChatOptions({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatListProvider.notifier);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(chat.visibility == ChatVisibility.pinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(chat.visibility == ChatVisibility.pinned ? 'Unpin' : 'Pin'),
            onTap: () {
              Navigator.pop(context);
              chat.visibility == ChatVisibility.pinned
                  ? notifier.unpinChat(chat.id)
                  : notifier.pinChat(chat.id);
            },
          ),
          ListTile(
            leading: Icon(chat.isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined),
            title: Text(chat.isMuted ? 'Unmute' : 'Mute'),
            onTap: () {
              Navigator.pop(context);
              chat.isMuted
                  ? notifier.unmuteChat(chat.id)
                  : notifier.muteChat(chat.id, 0); // 0 = forever
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive'),
            onTap: () {
              Navigator.pop(context);
              notifier.archiveChat(chat.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.mark_chat_read_outlined),
            title: const Text('Mark as read'),
            onTap: () {
              Navigator.pop(context);
              notifier.markRead(chat.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: OmegaColors.error),
            title: const Text('Delete', style: TextStyle(color: OmegaColors.error)),
            onTap: () {
              Navigator.pop(context);
              notifier.deleteChat(chat.id);
            },
          ),
        ],
      ),
    );
  }
}

class _ChatListMenu extends StatelessWidget {
  const _ChatListMenu();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('New Group'),
            onTap: () {
              Navigator.pop(context);
              context.go('/chats/group/create');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: const Text('My QR Code'),
            onTap: () {
              Navigator.pop(context);
              context.go('/qr-display');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteConstants.settings);
            },
          ),
        ],
      ),
    );
  }
}

