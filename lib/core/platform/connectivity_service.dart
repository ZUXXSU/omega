import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/theme/colors.dart';
import '../../core/utils/logger.dart';

part 'connectivity_service.g.dart';

// ---------------------------------------------------------------------------
// Connectivity service
// ---------------------------------------------------------------------------

/// Wraps [Connectivity] from `connectivity_plus` and exposes the current
/// result as a broadcast stream and Riverpod provider.
class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final _connectivity = Connectivity();
  late final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  Stream<List<ConnectivityResult>> get stream => _controller.stream;

  List<ConnectivityResult> _current = const [ConnectivityResult.none];

  List<ConnectivityResult> get current => _current;

  bool get isOnline =>
      _current.any((r) => r != ConnectivityResult.none);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  void _init() {
    _sub = _connectivity.onConnectivityChanged.listen(
      (results) {
        _current = results;
        _controller.add(results);
        AppLogger.d('ConnectivityService: ${results.map((r) => r.name).join(', ')}');
      },
      onError: (Object e, StackTrace st) {
        AppLogger.e('ConnectivityService stream error', e, st);
      },
    );

    // Populate initial state.
    _connectivity.checkConnectivity().then((results) {
      _current = results;
      _controller.add(results);
    }).catchError((Object e) {
      AppLogger.e('ConnectivityService initial check failed', e);
    });
  }

  Future<List<ConnectivityResult>> check() async {
    try {
      _current = await _connectivity.checkConnectivity();
      return _current;
    } catch (e, st) {
      AppLogger.e('ConnectivityService.check failed', e, st);
      return const [ConnectivityResult.none];
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Provides the singleton [ConnectivityService] instance.
@riverpod
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
}

/// StreamProvider that emits [List<ConnectivityResult>] on every change.
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(
  ConnectivityStreamRef ref,
) {
  return ref.watch(connectivityServiceProvider).stream;
}

/// Synchronous convenience provider: true when the device has connectivity.
@riverpod
bool isOnline(IsOnlineRef ref) {
  final asyncValue = ref.watch(connectivityStreamProvider);
  return asyncValue.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => ref.watch(connectivityServiceProvider).isOnline,
    error: (_, __) => false,
  );
}

// ---------------------------------------------------------------------------
// OmegaConnectivityBanner
// ---------------------------------------------------------------------------

/// Animated banner that slides down from the top of the screen:
/// - Yellow "No internet connection" when offline.
/// - Green "Back online" when connectivity is restored, auto-dismisses after
///   2 seconds.
///
/// Usage: wrap your scaffold body or stack it at the top of [MaterialApp]:
/// ```dart
/// Stack(
///   children: [
///     child,
///     const OmegaConnectivityBanner(),
///   ],
/// )
/// ```
class OmegaConnectivityBanner extends ConsumerStatefulWidget {
  const OmegaConnectivityBanner({super.key});

  @override
  ConsumerState<OmegaConnectivityBanner> createState() =>
      _OmegaConnectivityBannerState();
}

class _OmegaConnectivityBannerState
    extends ConsumerState<OmegaConnectivityBanner>
    with SingleTickerProviderStateMixin {
  // Animation controller for slide-in / slide-out.
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  bool _isOnline = true;
  bool _showingBackOnline = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Read initial state without listening (listener is set up by watch below).
    final service = ref.read(connectivityServiceProvider);
    _isOnline = service.isOnline;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(bool online) {
    if (online == _isOnline) return;
    final wasOffline = !_isOnline;
    _isOnline = online;

    if (!online) {
      // Went offline — show yellow banner indefinitely.
      _dismissTimer?.cancel();
      _showingBackOnline = false;
      _controller.forward();
    } else if (wasOffline) {
      // Came back online — show green banner then auto-dismiss.
      _dismissTimer?.cancel();
      setState(() => _showingBackOnline = true);
      _controller.forward();
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) setState(() => _showingBackOnline = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch online state and react to changes.
    ref.listen<bool>(isOnlineProvider, (prev, next) {
      _handleConnectivityChange(next);
    });

    final isOnline = ref.watch(isOnlineProvider);

    // Nothing to show when online and not in "back online" animation.
    if (isOnline && !_showingBackOnline) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showingBackOnline
              ? _ConnectivityBannerContent(
                  key: const ValueKey('online'),
                  message: 'Back online',
                  icon: Icons.wifi,
                  backgroundColor: OmegaColors.success,
                  topPadding: topPadding,
                )
              : _ConnectivityBannerContent(
                  key: const ValueKey('offline'),
                  message: 'No internet connection',
                  icon: Icons.wifi_off,
                  backgroundColor: OmegaColors.warning,
                  topPadding: topPadding,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal banner content
// ---------------------------------------------------------------------------

class _ConnectivityBannerContent extends StatelessWidget {
  const _ConnectivityBannerContent({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.topPadding,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 10,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience wrapper widget
// ---------------------------------------------------------------------------

/// Wraps any [child] widget in a [Stack] with [OmegaConnectivityBanner]
/// overlaid at the top. Drop this around your root navigator or scaffold body.
class OmegaConnectivityWrapper extends StatelessWidget {
  const OmegaConnectivityWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const OmegaConnectivityBanner(),
      ],
    );
  }
}
