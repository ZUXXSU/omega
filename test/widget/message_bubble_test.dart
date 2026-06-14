// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omega/app/theme/app_theme.dart';
import 'package:omega/app/theme/colors.dart';
import 'package:omega/features/chat/presentation/widgets/message_bubble.dart';
import 'package:omega/shared/models/message.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps a [MessageBubble] inside a bare [MaterialApp] with a light theme.
/// We need a [Scaffold] + [MediaQuery] so the bubble's maxWidth constraint
/// resolves without throwing.
Future<void> _pumpBubble(
  WidgetTester tester,
  Message message, {
  bool showAvatar = false,
  bool showSenderName = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MessageBubble(
            message: message,
            showAvatar: showAvatar,
            showSenderName: showSenderName,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Creates a minimal [Message] for test purposes.
Message _makeMessage({
  int id = 1,
  MessageType type = MessageType.text,
  String? text,
  bool isOutgoing = false,
  MessageState state = MessageState.sent,
  String? fileName,
  int? fileBytes,
  int? durationMs,
}) {
  return Message(
    id: id,
    chatId: 1,
    fromContactId: isOutgoing ? 0 : 1,
    type: type,
    text: text,
    state: state,
    isOutgoing: isOutgoing,
    timestamp: DateTime(2024, 1, 1, 12, 0),
    fileName: fileName,
    fileBytes: fileBytes,
    durationMs: durationMs,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MessageBubble – outgoing text bubble', () {
    testWidgets('renders message text', (tester) async {
      final msg = _makeMessage(
        text: 'Hello, world!',
        isOutgoing: true,
      );
      await _pumpBubble(tester, msg);

      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('aligns outgoing bubble to the right side of the row',
        (tester) async {
      final msg = _makeMessage(text: 'Hi', isOutgoing: true);
      await _pumpBubble(tester, msg);

      // The outer Row for outgoing messages uses MainAxisAlignment.end.
      // We verify by checking the Row widget's alignment.
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('outgoing bubble background is OmegaColors.bubbleOutgoing',
        (tester) async {
      final msg = _makeMessage(text: 'Outgoing', isOutgoing: true);
      await _pumpBubble(tester, msg);

      // Find Container widgets and look for the one painted with bubbleOutgoing
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasOutgoingBg = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == OmegaColors.bubbleOutgoing;
        }
        return false;
      });
      expect(hasOutgoingBg, isTrue);
    });

    testWidgets('renders delivery status icon for outgoing message',
        (tester) async {
      final msg = _makeMessage(text: 'Hi', isOutgoing: true, state: MessageState.sent);
      await _pumpBubble(tester, msg);

      // Status icon is only shown for outgoing messages
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('MessageBubble – incoming text bubble', () {
    testWidgets('renders incoming message text', (tester) async {
      final msg = _makeMessage(text: 'Hey there', isOutgoing: false);
      await _pumpBubble(tester, msg);

      expect(find.text('Hey there'), findsOneWidget);
    });

    testWidgets('aligns incoming bubble to the left side of the row',
        (tester) async {
      final msg = _makeMessage(text: 'Hey', isOutgoing: false);
      await _pumpBubble(tester, msg);

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });

    testWidgets('does NOT render delivery status icon for incoming message',
        (tester) async {
      final msg = _makeMessage(text: 'Hey', isOutgoing: false);
      await _pumpBubble(tester, msg);

      // No status icons expected for incoming messages
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    });
  });

  group('MessageBubble – delivery status icons (MessageState)', () {
    testWidgets('pending state shows access_time icon', (tester) async {
      final msg = _makeMessage(
        text: 'Pending',
        isOutgoing: true,
        state: MessageState.pending,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('sent state shows check icon', (tester) async {
      final msg = _makeMessage(
        text: 'Sent',
        isOutgoing: true,
        state: MessageState.sent,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('delivered state shows done_all icon', (tester) async {
      final msg = _makeMessage(
        text: 'Delivered',
        isOutgoing: true,
        state: MessageState.delivered,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });

    testWidgets('read state shows done_all icon (in primary color)',
        (tester) async {
      final msg = _makeMessage(
        text: 'Read',
        isOutgoing: true,
        state: MessageState.read,
      );
      await _pumpBubble(tester, msg);

      // Both delivered and read use done_all; we verify the icon exists.
      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all_rounded));
      expect(icon.color, OmegaColors.messageRead);
    });

    testWidgets('failed state shows error_outline icon', (tester) async {
      final msg = _makeMessage(
        text: 'Failed',
        isOutgoing: true,
        state: MessageState.failed,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('MessageBubble – voice message', () {
    testWidgets('voice message renders play_circle_outline icon', (tester) async {
      final msg = _makeMessage(
        type: MessageType.voice,
        isOutgoing: false,
        durationMs: 5000,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('audio message renders play_circle_outline icon', (tester) async {
      final msg = _makeMessage(
        type: MessageType.audio,
        isOutgoing: true,
        durationMs: 12000,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('voice message shows duration when durationMs is set',
        (tester) async {
      final msg = _makeMessage(
        type: MessageType.voice,
        isOutgoing: false,
        durationMs: 7000, // 7 seconds
      );
      await _pumpBubble(tester, msg);

      // Duration label: 7s
      expect(find.text('7s'), findsOneWidget);
    });

    testWidgets('voice message shows "Voice" when durationMs is null',
        (tester) async {
      final msg = _makeMessage(
        type: MessageType.voice,
        isOutgoing: false,
        durationMs: null,
      );
      await _pumpBubble(tester, msg);

      expect(find.text('Voice'), findsOneWidget);
    });
  });

  group('MessageBubble – file message', () {
    testWidgets('file message renders insert_drive_file icon', (tester) async {
      final msg = _makeMessage(
        type: MessageType.file,
        isOutgoing: false,
        fileName: 'report.pdf',
        fileBytes: 204800,
      );
      await _pumpBubble(tester, msg);

      expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    });

    testWidgets('file message renders filename text', (tester) async {
      final msg = _makeMessage(
        type: MessageType.file,
        isOutgoing: false,
        fileName: 'document.docx',
      );
      await _pumpBubble(tester, msg);

      expect(find.text('document.docx'), findsOneWidget);
    });

    testWidgets('file message shows "File" when fileName is null', (tester) async {
      final msg = _makeMessage(
        type: MessageType.file,
        isOutgoing: false,
        fileName: null,
      );
      await _pumpBubble(tester, msg);

      expect(find.text('File'), findsOneWidget);
    });

    testWidgets('file message renders size in KB when fileBytes < 1 MB',
        (tester) async {
      final msg = _makeMessage(
        type: MessageType.file,
        isOutgoing: false,
        fileName: 'image.png',
        fileBytes: 51200, // 50 KB
      );
      await _pumpBubble(tester, msg);

      expect(find.text('50.0 KB'), findsOneWidget);
    });

    testWidgets('file message renders size in MB when fileBytes >= 1 MB',
        (tester) async {
      final msg = _makeMessage(
        type: MessageType.file,
        isOutgoing: false,
        fileName: 'video.mp4',
        fileBytes: 2097152, // 2 MB
      );
      await _pumpBubble(tester, msg);

      expect(find.text('2.0 MB'), findsOneWidget);
    });
  });

  group('MessageBubble – sender name display', () {
    testWidgets('shows sender name label when showSenderName is true',
        (tester) async {
      final msg = _makeMessage(text: 'Hi', isOutgoing: false);
      await _pumpBubble(tester, msg, showSenderName: true);

      expect(find.text('Sender'), findsOneWidget);
    });

    testWidgets('does not show sender name when showSenderName is false',
        (tester) async {
      final msg = _makeMessage(text: 'Hi', isOutgoing: false);
      await _pumpBubble(tester, msg, showSenderName: false);

      expect(find.text('Sender'), findsNothing);
    });
  });
}
