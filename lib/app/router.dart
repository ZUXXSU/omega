import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/account_setup_screen.dart';
import '../features/chat_list/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/contacts/presentation/screens/contacts_screen.dart';
import '../features/contacts/presentation/screens/contact_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../features/settings/presentation/screens/advanced_settings_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/media/presentation/screens/media_viewer_screen.dart';
import '../core/constants/route_constants.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: RouteConstants.welcome,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteConstants.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.accountSetup,
        builder: (context, state) => const AccountSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: RouteConstants.chatList,
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: RouteConstants.chat,
                builder: (context, state) {
                  final chatId = int.parse(state.pathParameters['chatId']!);
                  return ChatScreen(chatId: chatId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.contacts,
            builder: (context, state) => const ContactsScreen(),
            routes: [
              GoRoute(
                path: RouteConstants.contactDetail,
                builder: (context, state) {
                  final contactId = int.parse(state.pathParameters['contactId']!);
                  return ContactDetailScreen(contactId: contactId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacySettingsScreen(),
              ),
              GoRoute(
                path: 'advanced',
                builder: (context, state) => const AdvancedSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.mediaViewer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MediaViewerScreen(
            mediaPath: extra['path'] as String,
            mediaType: extra['type'] as String,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
}
