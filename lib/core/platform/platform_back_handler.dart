import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handles Android hardware back button with minimize-on-first-press behavior.
///
/// - First back press on root screen: shows "Press again to exit" snackbar,
///   minimizes app via [SystemNavigator.pop] with `animated: true`.
/// - Second back press within 2 seconds: fully exits the app.
/// - On chat screens: back navigates to chat list instead of exiting.
/// - iOS / desktop: widget passes through transparently (no-op).
class OmegaBackHandler extends StatefulWidget {
  const OmegaBackHandler({
    super.key,
    required this.child,
    this.isChatScreen = false,
    this.onBackToList,
  });

  /// The widget tree to wrap.
  final Widget child;

  /// When [true] the back button pops the current route (back to chat list)
  /// instead of the minimize / exit flow.
  final bool isChatScreen;

  /// Optional callback invoked when back is pressed on a chat screen.
  /// If null, [Navigator.maybePop] is used.
  final VoidCallback? onBackToList;

  @override
  State<OmegaBackHandler> createState() => _OmegaBackHandlerState();
}

class _OmegaBackHandlerState extends State<OmegaBackHandler> {
  DateTime? _lastBackPressTime;
  static const _exitThreshold = Duration(seconds: 2);
  static const _toastMessage = 'Press back again to exit';

  // Tracks the current snackbar so we can close it on re-press.
  ScaffoldMessengerState? _messengerState;

  bool get _isAndroid => Platform.isAndroid;

  Future<bool> _onWillPop() async {
    if (!_isAndroid) return true;

    // Chat screens: just pop back to list.
    if (widget.isChatScreen) {
      if (widget.onBackToList != null) {
        widget.onBackToList!();
        return false;
      }
      return true; // Let navigator handle the pop.
    }

    final now = DateTime.now();
    final last = _lastBackPressTime;

    if (last != null && now.difference(last) < _exitThreshold) {
      // Second press within threshold — exit for real.
      _messengerState?.hideCurrentSnackBar();
      await SystemNavigator.pop();
      return false;
    }

    // First press — show toast and minimize.
    _lastBackPressTime = now;

    if (mounted) {
      _messengerState = ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(_toastMessage),
            duration: _exitThreshold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }

    // Minimize the app (send to background) instead of closing.
    await SystemNavigator.pop(animated: true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid) return widget.child;

    // Flutter 3.12+ uses PopScope; fall back to WillPopScope for older trees.
    // We use PopScope when available (Dart SDK >= 3.0 / Flutter >= 3.16).
    return PopScope(
      // canPop: false means we intercept every pop and handle it ourselves.
      canPop: widget.isChatScreen && widget.onBackToList == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Navigation already happened.
        await _onWillPop();
      },
      child: widget.child,
    );
  }
}

/// Convenience extension to check whether the current platform needs back
/// button handling at all.
extension BackHandlerPlatform on BuildContext {
  bool get needsBackHandler => Platform.isAndroid;
}
