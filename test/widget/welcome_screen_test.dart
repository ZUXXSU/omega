// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omega/app/theme/app_theme.dart';
import 'package:omega/app/theme/colors.dart';
import 'package:omega/core/constants/route_constants.dart';
import 'package:omega/features/auth/presentation/screens/welcome_screen.dart';
import 'package:omega/shared/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal router that wraps [WelcomeScreen] so GoRouter navigation works
/// in tests. Navigation targets are captured via [_NavigationSpy].
class _NavigationSpy {
  String? lastLocation;
}

GoRouter _buildRouter(_NavigationSpy spy) {
  return GoRouter(
    initialLocation: RouteConstants.welcome,
    routes: [
      GoRoute(
        path: RouteConstants.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (_, __) {
          spy.lastLocation = RouteConstants.onboarding;
          return const Scaffold(body: Text('Onboarding'));
        },
      ),
      GoRoute(
        path: RouteConstants.accountSetup,
        builder: (_, __) {
          spy.lastLocation = RouteConstants.accountSetup;
          return const Scaffold(body: Text('Account Setup'));
        },
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) {
          spy.lastLocation = RouteConstants.login;
          return const Scaffold(body: Text('Login'));
        },
      ),
    ],
  );
}

Widget _buildTestApp(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() async {
    // Provide an empty SharedPreferences so StorageService.isOnboardingComplete
    // is deterministic (false by default).
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  group('WelcomeScreen – rendering', () {
    testWidgets('renders app title "Omega"', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.text('Omega'), findsOneWidget);
    });

    testWidgets('renders tagline text', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.text('Secure. Private. Enterprise.'), findsOneWidget);
    });

    testWidgets('renders logo icon', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('renders "Create Account" button', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders "Sign In" button', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders "Enterprise / MDM Setup" text button', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      expect(find.text('Enterprise / MDM Setup'), findsOneWidget);
    });

    testWidgets('scaffold background is OmegaColors.primary', (tester) async {
      final spy = _NavigationSpy();
      await tester.pumpWidget(_buildTestApp(_buildRouter(spy)));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, OmegaColors.primary);
    });
  });

  group('WelcomeScreen – navigation: Create Account button', () {
    testWidgets(
        'navigates to onboarding when onboarding is NOT complete',
        (tester) async {
      // isOnboardingComplete == false (empty prefs)
      final spy = _NavigationSpy();
      final router = _buildRouter(spy);
      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Onboarding'), findsOneWidget);
    });

    testWidgets(
        'navigates to account setup when onboarding IS complete',
        (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await StorageService.initialize();

      final spy = _NavigationSpy();
      final router = _buildRouter(spy);
      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account Setup'), findsOneWidget);
    });
  });

  group('WelcomeScreen – navigation: Sign In button', () {
    testWidgets('navigates to login screen', (tester) async {
      final spy = _NavigationSpy();
      final router = _buildRouter(spy);
      await tester.pumpWidget(_buildTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });
  });
}
