import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../screens/disappearing_messages_screen.dart';

/// A compact badge widget displaying the active ephemeral/disappearing-message
/// timer for a chat.  Intended for use inside a [ChatAppBar].
///
/// - Shows a flame icon + formatted time remaining label.
/// - When [duration] is [EphemeralDuration.off], renders nothing.
/// - For timers <= 5 minutes the flame pulses to signal urgency.
/// - Tapping the badge opens [DisappearingMessagesScreen] for [chatId].
class EphemeralTimerBadge extends StatefulWidget {
  final int chatId;
  final EphemeralDuration duration;

  const EphemeralTimerBadge({
    super.key,
    required this.chatId,
    required this.duration,
  });

  @override
  State<EphemeralTimerBadge> createState() => _EphemeralTimerBadgeState();
}

class _EphemeralTimerBadgeState extends State<EphemeralTimerBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<Color?> _colorAnim;

  // For short timers we show a live countdown that ticks every second.
  Timer? _countdownTimer;
  Duration? _remaining;

  bool get _isShortTimer =>
      widget.duration != EphemeralDuration.off &&
      widget.duration.seconds <= 300; // <= 5 minutes

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnim = ColorTween(
      begin: OmegaColors.warning.withOpacity(0.7),
      end: OmegaColors.warning,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _startAnimationIfNeeded();
    _startCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(EphemeralTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _stopAnimation();
      _stopCountdown();
      _startAnimationIfNeeded();
      _startCountdownIfNeeded();
    }
  }

  void _startAnimationIfNeeded() {
    if (widget.duration != EphemeralDuration.off && _isShortTimer) {
      _pulseController.repeat(reverse: true);
    } else if (widget.duration != EphemeralDuration.off) {
      // Gentle single pulse then stop for longer timers.
      _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    }
  }

  void _stopAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _startCountdownIfNeeded() {
    if (_isShortTimer && widget.duration.duration != null) {
      _remaining = widget.duration.duration;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          final r = _remaining;
          if (r != null && r.inSeconds > 0) {
            _remaining = r - const Duration(seconds: 1);
          }
        });
      });
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remaining = null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopCountdown();
    super.dispose();
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  String get _displayLabel {
    if (widget.duration == EphemeralDuration.off) return '';

    // For short timers, show live countdown if available.
    if (_isShortTimer && _remaining != null) {
      return _formatDuration(_remaining!);
    }

    return widget.duration.shortLabel;
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '0s';
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    if (d.inMinutes >= 1) {
      final m = d.inMinutes;
      final s = d.inSeconds.remainder(60);
      return s > 0 ? '${m}m${s}s' : '${m}m';
    }
    return '${d.inSeconds}s';
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DisappearingMessagesScreen(chatId: widget.chatId),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.duration == EphemeralDuration.off) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openSettings(context),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isShortTimer ? _scaleAnim.value : 1.0,
            child: _Badge(
              label: _displayLabel,
              iconColor: _isShortTimer
                  ? (_colorAnim.value ?? OmegaColors.warning)
                  : OmegaColors.warning,
              isDark: isDark,
              isUrgent: _isShortTimer,
            ),
          );
        },
      ),
    );
  }
}

// ── Badge visual ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color iconColor;
  final bool isDark;
  final bool isUrgent;

  const _Badge({
    required this.label,
    required this.iconColor,
    required this.isDark,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isUrgent
        ? OmegaColors.warning.withOpacity(0.15)
        : OmegaColors.primary.withOpacity(0.1);

    final borderColor = isUrgent
        ? OmegaColors.warning.withOpacity(0.4)
        : OmegaColors.primary.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: OmegaTextStyles.labelSmall.copyWith(
              color: isUrgent
                  ? OmegaColors.warning
                  : (isDark
                      ? OmegaColors.textPrimaryDark
                      : OmegaColors.textPrimary),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standalone app-bar action variant ────────────────────────────────────────

/// Wraps [EphemeralTimerBadge] as an [IconButton]-style widget that fits
/// directly into an [AppBar.actions] list when space is tight.
class EphemeralTimerAction extends StatelessWidget {
  final int chatId;
  final EphemeralDuration duration;

  const EphemeralTimerAction({
    super.key,
    required this.chatId,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    if (duration == EphemeralDuration.off) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: EphemeralTimerBadge(chatId: chatId, duration: duration),
    );
  }
}
