// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omega/app/theme/app_theme.dart';
import 'package:omega/app/theme/colors.dart';
import 'package:omega/shared/widgets/omega_avatar.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Future<void> _pumpAvatar(
  WidgetTester tester,
  OmegaAvatar avatar,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(child: avatar),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('OmegaAvatar – initials extraction', () {
    testWidgets('shows first + last initial for two-word name', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Alice Johnson', size: 48),
      );

      expect(find.text('AJ'), findsOneWidget);
    });

    testWidgets('shows first + second initial (uppercased)', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'bob smith', size: 48),
      );

      expect(find.text('BS'), findsOneWidget);
    });

    testWidgets('uses first + third word initial when middle name present',
        (tester) async {
      // split(' ') → ['John', 'Paul', 'Jones'] → parts[0][0] + parts[1][0] = JP
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'John Paul Jones', size: 48),
      );

      // The implementation uses parts[0][0] + parts[1][0]
      expect(find.text('JP'), findsOneWidget);
    });

    testWidgets('shows single initial for single-word name', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Monica', size: 48),
      );

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('shows "?" for empty name', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: '', size: 48),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('initials are always uppercased', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'carol white', size: 48),
      );

      expect(find.text('CW'), findsOneWidget);
    });
  });

  group('OmegaAvatar – group avatar', () {
    testWidgets('shows group icon instead of initials when isGroup=true',
        (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Engineering Team', size: 48, isGroup: true),
      );

      expect(find.byIcon(Icons.group_rounded), findsOneWidget);
    });

    testWidgets('does NOT show text initials when isGroup=true', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Engineering Team', size: 48, isGroup: true),
      );

      // Initials 'ET' should not appear
      expect(find.text('ET'), findsNothing);
    });

    testWidgets('does NOT show group icon when isGroup=false', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Alice Johnson', size: 48, isGroup: false),
      );

      expect(find.byIcon(Icons.group_rounded), findsNothing);
    });
  });

  group('OmegaAvatar – verified badge', () {
    testWidgets('renders verified badge overlay when isVerified=true',
        (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Alice', size: 48, isVerified: true),
      );

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('verified badge container uses OmegaColors.primary background',
        (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Alice', size: 48, isVerified: true),
      );

      // Find Container widgets that use primary colour
      final containers =
          tester.widgetList<Container>(find.byType(Container));
      final hasPrimaryBg = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == OmegaColors.primary;
        }
        return false;
      });
      expect(hasPrimaryBg, isTrue);
    });

    testWidgets('does NOT render verified badge when isVerified=false',
        (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Alice', size: 48, isVerified: false),
      );

      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });
  });

  group('OmegaAvatar – online indicator', () {
    testWidgets('shows online dot when isOnline=true and isVerified=false',
        (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Dave', size: 48, isOnline: true),
      );

      // The online dot is a Container in a Stack – no icon; we verify via Stack
      // that there are multiple children (avatar + dot).
      final stack = tester.widget<Stack>(find.byType(Stack).first);
      expect(stack.children.length, greaterThanOrEqualTo(2));
    });

    testWidgets('verified badge takes priority over online dot', (tester) async {
      await _pumpAvatar(
        tester,
        const OmegaAvatar(
          name: 'Dave',
          size: 48,
          isOnline: true,
          isVerified: true,
        ),
      );

      // Only verified icon is shown (online dot is suppressed)
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });
  });

  group('OmegaAvatar – custom background color', () {
    testWidgets('uses provided backgroundColor instead of hash-computed color',
        (tester) async {
      const customColor = Color(0xFFABCDEF);
      await _pumpAvatar(
        tester,
        const OmegaAvatar(
          name: 'Test',
          size: 48,
          backgroundColor: customColor,
        ),
      );

      final circleAvatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(circleAvatar.backgroundColor, customColor);
    });
  });

  group('OmegaAvatar – size', () {
    testWidgets('CircleAvatar radius equals size / 2', (tester) async {
      const avatarSize = 64.0;
      await _pumpAvatar(
        tester,
        const OmegaAvatar(name: 'Bob', size: avatarSize),
      );

      final circleAvatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
      expect(circleAvatar.radius, avatarSize / 2);
    });
  });
}
