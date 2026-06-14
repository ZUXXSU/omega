import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/colors.dart';
import '../app/theme/text_styles.dart';
import '../features/chat_list/presentation/providers/chat_list_provider.dart';

class ShellScaffold extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const ShellScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => _onTap(index, context),
        backgroundColor: isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: totalUnread > 0,
              label: Text(
                totalUnread > 99 ? '99+' : '$totalUnread',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: totalUnread > 0,
              label: Text(
                totalUnread > 99 ? '99+' : '$totalUnread',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_rounded),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'My QR',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(int index, BuildContext context) {
    if (shell.currentIndex == index) {
      // Pop to root of current branch on double-tap
      shell.goBranch(index, initialLocation: true);
    } else {
      shell.goBranch(index);
    }
  }
}
