import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'deep_link_handler.dart';

/// Singleton service that wires the [app_links] package to [DeepLinkHandler].
///
/// Call [AppLinksService.instance.initialize] once after the app has mounted
/// (i.e. after the [WidgetRef] and [BuildContext] from the root widget are
/// available).
///
/// Usage in your root Consumer/ConsumerWidget:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     AppLinksService.instance.initialize(context, ref);
///   });
/// }
/// ```
class AppLinksService {
  AppLinksService._();

  static final AppLinksService instance = AppLinksService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  /// Starts listening for incoming deep links and processes the initial URI
  /// if the app was cold-started from one.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops unless
  /// [dispose] was called in between.
  Future<void> initialize(BuildContext context, WidgetRef ref) async {
    if (_initialized) return;
    _initialized = true;

    AppLogger.i('AppLinksService: initializing');

    // Handle initial URI (app launched via deep link while not running).
    await _processInitialUri(context, ref);

    // Subscribe to subsequent incoming URIs while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _onUri(uri, context, ref),
      onError: (Object err, StackTrace st) {
        AppLogger.e('AppLinksService: stream error', err, st);
      },
    );
  }

  /// Call this when the app is permanently torn down (e.g. in a
  /// top-level [ProviderScope] dispose or in a long-lived widget's dispose).
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
    AppLogger.i('AppLinksService: disposed');
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _processInitialUri(BuildContext context, WidgetRef ref) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.i('AppLinksService: initial URI = $initialUri');
        await _onUri(initialUri, context, ref);
      } else {
        AppLogger.d('AppLinksService: no initial URI');
      }
    } catch (e, st) {
      AppLogger.e('AppLinksService: error reading initial URI', e, st);
    }
  }

  Future<void> _onUri(Uri uri, BuildContext context, WidgetRef ref) async {
    AppLogger.i('AppLinksService: incoming URI = $uri');
    if (!context.mounted) {
      AppLogger.w('AppLinksService: context unmounted, dropping URI $uri');
      return;
    }
    await DeepLinkHandler.handleUri(uri, context, ref);
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Exposes [AppLinksService.instance] via Riverpod so it can be read in any
/// ConsumerWidget without a singleton import.
final appLinksServiceProvider = Provider<AppLinksService>(
  (_) => AppLinksService.instance,
);
