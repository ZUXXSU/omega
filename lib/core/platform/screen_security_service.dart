import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

part 'screen_security_service.g.dart';

/// Controls system-level screenshot / app-switcher blur protection.
///
/// Android: bridges to `FlutterWindowManager.addFlags(FLAG_SECURE)` via
/// the `omega/screen_security` MethodChannel.
///
/// iOS: bridges to `UIApplication.keyWindow?.makeSecure()` (a UIWindow
/// subclass that blocks screenshots and shows a blurred app-switcher card)
/// via the same channel.
///
/// Desktop: all calls are no-ops.
class ScreenSecurityService {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  static const _channel = MethodChannel('omega/screen_security');

  bool _enabled = false;

  bool get isEnabled => _enabled;

  /// Enables FLAG_SECURE (Android) / secure UIWindow (iOS).
  Future<void> enable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('enable');
      _enabled = true;
      AppLogger.d('ScreenSecurityService: enabled');
    } on PlatformException catch (e, st) {
      AppLogger.e('ScreenSecurityService.enable failed', e, st);
    }
  }

  /// Disables FLAG_SECURE / restores normal UIWindow.
  Future<void> disable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('disable');
      _enabled = false;
      AppLogger.d('ScreenSecurityService: disabled');
    } on PlatformException catch (e, st) {
      AppLogger.e('ScreenSecurityService.disable failed', e, st);
    }
  }

  /// Queries the native side for the current secure state.
  Future<bool> queryEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      _enabled = result ?? false;
      return _enabled;
    } on PlatformException catch (e, st) {
      AppLogger.e('ScreenSecurityService.queryEnabled failed', e, st);
      return false;
    }
  }

  /// Syncs enabled/disabled state to match [enabled].
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await enable();
    } else {
      await disable();
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Exposes the singleton [ScreenSecurityService].
@riverpod
ScreenSecurityService screenSecurityService(ScreenSecurityServiceRef ref) {
  return ScreenSecurityService.instance;
}

/// Auto-syncs screen security with the [settingsProvider] whenever the
/// [AppSettings.screenSecurity] flag changes.
///
/// Consume this provider in your app root widget to activate auto-sync:
/// ```dart
/// ref.watch(screenSecuritySyncProvider);
/// ```
@riverpod
Future<void> screenSecuritySync(ScreenSecuritySyncRef ref) async {
  final settings = ref.watch(settingsProvider);
  final service = ref.watch(screenSecurityServiceProvider);
  await service.setEnabled(settings.screenSecurity);
}
