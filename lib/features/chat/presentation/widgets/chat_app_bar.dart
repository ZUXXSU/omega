import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../shared/widgets/omega_avatar.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int chatId;

  const ChatAppBar({super.key, required this.chatId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: wire to chat provider
    const chatName = 'Alice Johnson';
    const subtitle = 'Last seen 5 min ago';
    const isGroup = false;
    const isVerified = true;

    return AppBar(
      titleSpacing: 0,
      leading: BackButton(onPressed: () => context.pop()),
      title: InkWell(
        onTap: () {},
        child: Row(
          children: [
            const OmegaAvatar(
              name: chatName,
              size: 38,
              isVerified: isVerified,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.verified_rounded, size: 14, color: OmegaColors.primary),
                        ),
                      Text(
                        chatName,
                        style: OmegaTextStyles.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: OmegaTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {},
          tooltip: 'Video call',
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {},
          tooltip: 'Voice call',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showChatMenu(context),
          tooltip: 'More',
        ),
      ],
    );
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text('Search in Chat'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_rounded),
              title: const Text('Chat Wallpaper'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('Mute Notifications'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Disappearing Messages'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: OmegaColors.error),
              title: const Text('Block Contact', style: TextStyle(color: OmegaColors.error)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
