import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/utils/logger.dart';
import 'notification_service.dart';

/// Unique task names registered with WorkManager.
const _kPeriodicSyncTaskName = 'omega.background_sync';
const _kPeriodicSyncTaskTag = 'omega_periodic_sync';

/// Isolate port name used by the background isolate to signal completion.
const _kSyncPortName = 'omega_sync_port';

/// The periodic interval for background sync (minimum allowed by WorkManager).
const _kSyncPeriodicity = Duration(minutes: 15);

// ── Background entry-point ────────────────────────────────────────────────────
//
// WorkManager requires a top-level (or static) function annotated with
// @pragma('vm:entry-point') as the callback dispatcher. It runs in a
// separate Dart isolate, so it must not access any BuildContext or global
// Flutter state.

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppLogger.i('BackgroundSync: task started — $taskName');

    try {
      switch (taskName) {
        case _kPeriodicSyncTaskName:
          await _runSyncTask(inputData ?? {});
          break;
        default:
          AppLogger.w('BackgroundSync: unknown task "$taskName"');
      }
    } catch (e, st) {
      AppLogger.e('BackgroundSync: task failed', error: e, stackTrace: st);
      // Return false to tell WorkManager to retry the task.
      return false;
    }

    AppLogger.i('BackgroundSync: task finished — $taskName');
    return true;
  });
}

/// Core sync logic executed inside the background isolate.
Future<void> _runSyncTask(Map<String, dynamic> inputData) async {
  // Initialise a minimal local-notification instance for the background
  // isolate (no Firebase — just local notifications).
  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await localNotifications.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  // In production, spawn / connect to the deltachat-rpc-server process here
  // and call `get_fresh_msgs` or subscribe to events over stdio / WebSocket.
  // For now we use the simulated client to demonstrate the pattern.
  final newMessages = await _fetchNewMessages();

  if (newMessages.isEmpty) {
    AppLogger.d('BackgroundSync: no new messages');
    return;
  }

  AppLogger.i('BackgroundSync: ${newMessages.length} new message(s)');

  for (final msg in newMessages) {
    await _showNotificationForMessage(localNotifications, msg);
  }

  // Signal the foreground isolate (if alive) via an isolate port.
  _notifyForeground(newMessages.length);
}

/// Stubbed RPC fetch — replace with real DeltaRpcClient.getMessages() call.
/// Returns a list of new message maps: {chatId, chatName, senderName, text}.
Future<List<Map<String, dynamic>>> _fetchNewMessages() async {
  // Production implementation:
  //   final client = DeltaRpcClient();
  //   await client.start();
  //   final accountIds = await client.getAllAccountIds();
  //   final results = <Map<String,dynamic>>[];
  //   for (final accountId in accountIds) {
  //     final freshMsgIds = await client.getFreshMsgs(accountId);
  //     for (final msgId in freshMsgIds) {
  //       final msg = await client.getMessage(accountId, msgId);
  //       results.add(msg);
  //     }
  //   }
  //   await client.stop();
  //   return results;
  return [];
}

Future<void> _showNotificationForMessage(
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic> msg,
) async {
  final chatId = (msg['chatId'] as int?) ?? 0;
  final chatName = (msg['chatName'] as String?) ?? 'New message';
  final senderName = (msg['senderName'] as String?) ?? '';
  final text = (msg['text'] as String?) ?? '';

  const chatChannelId = 'omega_chats';
  const chatChannelName = 'Chat Messages';

  await plugin.show(
    chatId,
    chatName,
    senderName.isNotEmpty ? '$senderName: $text' : text,
    NotificationDetails(
      android: AndroidNotificationDetails(
        chatChannelId,
        chatChannelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(text),
        groupKey: 'omega_chat_group',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'chat',
      ),
    ),
    payload: chatId.toString(),
  );
}

/// Sends a signal to the foreground isolate so it can refresh the UI.
void _notifyForeground(int count) {
  final sendPort = IsolateNameServer.lookupPortByName(_kSyncPortName);
  sendPort?.send({'type': 'new_messages', 'count': count});
}

// ── BackgroundSyncService ─────────────────────────────────────────────────────

/// Manages the WorkManager-based periodic background sync for Omega.
///
/// Call [initialize] once at app startup (before runApp or in main()).
/// Call [registerPeriodicSync] after the user logs in.
/// Call [cancelSync] when the user logs out or disables background sync.
class BackgroundSyncService {
  BackgroundSyncService._();

  static final BackgroundSyncService instance = BackgroundSyncService._();

  bool _initialized = false;

  // Optional receive port for the foreground isolate to listen on.
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _portSubscription;

  /// Initialise WorkManager. Must be called once before any other methods.
  ///
  /// [isInDebugMode] enables WorkManager debug logging on Android.
  Future<void> initialize({bool isInDebugMode = false}) async {
    if (_initialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: isInDebugMode,
    );

    _initialized = true;
    AppLogger.i('BackgroundSyncService: initialized');
  }

  /// Register the periodic sync task with WorkManager.
  ///
  /// WorkManager will run [callbackDispatcher] every [_kSyncPeriodicity].
  /// On iOS the exact timing is determined by the OS; on Android it respects
  /// the 15-minute minimum.
  ///
  /// [onNewMessages] is an optional callback invoked in the *foreground*
  /// isolate when the background task reports new messages.
  Future<void> registerPeriodicSync({
    void Function(int count)? onNewMessages,
  }) async {
    _ensureInitialized();

    // Register foreground receive port so background can signal us.
    if (onNewMessages != null) {
      _receivePort?.close();
      _receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping(_kSyncPortName);
      IsolateNameServer.registerPortWithName(
        _receivePort!.sendPort,
        _kSyncPortName,
      );

      _portSubscription?.cancel();
      _portSubscription = _receivePort!.listen((message) {
        if (message is Map && message['type'] == 'new_messages') {
          final count = (message['count'] as int?) ?? 0;
          onNewMessages(count);
        }
      });
    }

    await Workmanager().registerPeriodicTask(
      _kPeriodicSyncTaskTag,
      _kPeriodicSyncTaskName,
      frequency: _kSyncPeriodicity,
      // Require network access — no point syncing without connectivity.
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      // BackoffPolicy: exponential retry on failure.
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
      // existingWorkPolicy: replace any previously registered task.
      existingWorkPolicy: ExistingWorkPolicy.replace,
      inputData: const <String, dynamic>{
        'version': 1,
      },
    );

    AppLogger.i(
      'BackgroundSyncService: periodic sync registered '
      '(every ${_kSyncPeriodicity.inMinutes} min)',
    );
  }

  /// Cancel the periodic sync task and clean up the isolate port.
  Future<void> cancelSync() async {
    _ensureInitialized();

    await Workmanager().cancelByTag(_kPeriodicSyncTaskTag);

    _portSubscription?.cancel();
    _portSubscription = null;
    _receivePort?.close();
    _receivePort = null;
    IsolateNameServer.removePortNameMapping(_kSyncPortName);

    AppLogger.i('BackgroundSyncService: periodic sync cancelled');
  }

  /// Cancel all WorkManager tasks registered by Omega.
  Future<void> cancelAll() async {
    _ensureInitialized();
    await Workmanager().cancelAll();
    AppLogger.i('BackgroundSyncService: all tasks cancelled');
  }

  /// Manually trigger a one-off sync (e.g. on foreground resume).
  ///
  /// Uses a one-time WorkManager task so it runs even if the app goes to
  /// the background before the task finishes.
  Future<void> triggerImmediateSync() async {
    _ensureInitialized();

    await Workmanager().registerOneOffTask(
      '${_kPeriodicSyncTaskTag}_oneoff_${DateTime.now().millisecondsSinceEpoch}',
      _kPeriodicSyncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: const <String, dynamic>{'version': 1, 'oneOff': true},
    );

    AppLogger.i('BackgroundSyncService: one-off sync triggered');
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'BackgroundSyncService.initialize() must be called before use.',
      );
    }
  }
}
