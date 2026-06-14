import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/account_setup_screen.dart';
import '../features/auth/presentation/screens/app_lock_screen.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../shared/services/storage_service.dart';
import '../features/chat_list/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/chat/presentation/screens/message_search_screen.dart';
import '../features/chat/presentation/screens/starred_messages_screen.dart';
import '../features/chat/presentation/screens/group/group_create_screen.dart';
import '../features/contacts/presentation/screens/contacts_screen.dart';
import '../features/contacts/presentation/screens/contact_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../features/settings/presentation/screens/advanced_settings_screen.dart';
import '../features/settings/presentation/screens/backup_restore_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/media/presentation/screens/media_viewer_screen.dart';
import '../features/qr/presentation/screens/qr_scanner_screen.dart';
import '../features/qr/presentation/screens/qr_display_screen.dart';
import '../features/search/presentation/screens/global_search_screen.dart';
import '../features/enterprise/presentation/screens/compliance_screen.dart';
import '../features/enterprise/presentation/screens/provisioning_screen.dart';
import '../core/constants/route_constants.dart';
import 'shell_scaffold.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authProvider);
  final settings  = ref.watch(settingsProvider);

  return GoRouter(
    initialLocation: RouteConstants.welcome,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isOnAuth = path == RouteConstants.welcome ||
          path == RouteConstants.onboarding ||
          path == RouteConstants.login ||
          path == RouteConstants.accountSetup ||
          path == RouteConstants.provisioning;

      // Provisioning takes priority
      if (path == RouteConstants.provisioning) return null;

      // Not yet checked auth — stay on welcome
      if (authState.status == AuthStatus.unknown) {
        return isOnAuth ? null : RouteConstants.welcome;
      }

      // Unauthenticated → send to welcome
      if (authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        return isOnAuth ? null : RouteConstants.welcome;
      }

      // Authenticated but on auth screen → send to chats
      if (authState.status == AuthStatus.authenticated && isOnAuth) {
        return RouteConstants.chatList;
      }

      // Biometric lock — if enabled and not on lock screen, redirect
      if (settings.biometricLock &&
          path != RouteConstants.appLock &&
          !isOnAuth) {
        // Only redirect once per session — StorageService tracks unlock state
        if (!StorageService.getBool('session_unlocked')) {
          return RouteConstants.appLock;
        }
      }

      return null;
    },
    routes: [
      // ── Unauthenticated ────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.accountSetup,
        builder: (_, __) => const AccountSetupScreen(),
      ),

      // ── Authenticated shell with bottom nav ────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell),
        branches: [
          // Branch 0 — Chats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.chatList,
                builder: (_, __) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':chatId',
                    builder: (_, state) => ChatScreen(
                      chatId: int.parse(state.pathParameters['chatId']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'search',
                        builder: (_, state) => MessageSearchScreen(
                          chatId: int.parse(state.pathParameters['chatId']!),
                          chatName: state.uri.queryParameters['name'] ?? 'Chat',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'group/create',
                    builder: (_, __) => const GroupCreateScreen(),
                  ),
                  GoRoute(
                    path: 'starred',
                    builder: (_, __) => const StarredMessagesScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1 — Contacts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.contacts,
                builder: (_, __) => const ContactsScreen(),
                routes: [
                  GoRoute(
                    path: ':contactId',
                    builder: (_, state) => ContactDetailScreen(
                      contactId: int.parse(state.pathParameters['contactId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2 — QR
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/qr',
                builder: (_, __) => const QrDisplayScreen(),
              ),
            ],
          ),
          // Branch 3 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.settings,
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(path: 'profile', builder: (_, __) => const ProfileSettingsScreen()),
                  GoRoute(path: 'notifications', builder: (_, __) => const NotificationSettingsScreen()),
                  GoRoute(path: 'privacy', builder: (_, __) => const PrivacySettingsScreen()),
                  GoRoute(path: 'advanced', builder: (_, __) => const AdvancedSettingsScreen()),
                  GoRoute(path: 'backup', builder: (_, __) => const BackupRestoreScreen()),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen overlays (no bottom nav) ──────────────────────────
      GoRoute(
        path: RouteConstants.qrScanner,
        builder: (_, state) {
          final mode = state.uri.queryParameters['mode'];
          return QrScannerScreen(
            mode: switch (mode) {
              'group'   => QrScanMode.groupInvite,
              'account' => QrScanMode.accountLogin,
              'backup'  => QrScanMode.backup,
              _         => QrScanMode.contact,
            },
          );
        },
      ),
      GoRoute(
        path: '/qr-display',
        builder: (_, state) => QrDisplayScreen(
          chatId: state.uri.queryParameters['chatId'] != null
              ? int.tryParse(state.uri.queryParameters['chatId']!)
              : null,
        ),
      ),
      GoRoute(
        path: RouteConstants.mediaViewer,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MediaViewerScreen(
            mediaPath: extra['path'] as String,
            mediaType: extra['type'] as String,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: RouteConstants.appLock,
        builder: (_, __) => const AppLockScreen(),
      ),
      GoRoute(
        path: RouteConstants.compliance,
        builder: (_, __) => const ComplianceScreen(),
      ),
      GoRoute(
        path: RouteConstants.provisioning,
        builder: (_, state) => ProvisioningScreen(
          provisioningUrl: state.uri.queryParameters['url'] ?? '',
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
}
