import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Duration in seconds; 0 = off.
enum EphemeralDuration {
  off(0, 'Off', null),
  oneMinute(60, '1 minute', Duration(minutes: 1)),
  fiveMinutes(300, '5 minutes', Duration(minutes: 5)),
  thirtyMinutes(1800, '30 minutes', Duration(minutes: 30)),
  oneHour(3600, '1 hour', Duration(hours: 1)),
  oneDay(86400, '1 day', Duration(days: 1)),
  oneWeek(604800, '1 week', Duration(days: 7)),
  fourWeeks(2419200, '4 weeks', Duration(days: 28));

  const EphemeralDuration(this.seconds, this.label, this.duration);

  final int seconds;
  final String label;
  final Duration? duration;

  String get shortLabel {
    return switch (this) {
      EphemeralDuration.off => 'Off',
      EphemeralDuration.oneMinute => '1m',
      EphemeralDuration.fiveMinutes => '5m',
      EphemeralDuration.thirtyMinutes => '30m',
      EphemeralDuration.oneHour => '1h',
      EphemeralDuration.oneDay => '1d',
      EphemeralDuration.oneWeek => '1w',
      EphemeralDuration.fourWeeks => '4w',
    };
  }

  static EphemeralDuration fromSeconds(int secs) {
    for (final v in values) {
      if (v.seconds == secs) return v;
    }
    return EphemeralDuration.off;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

@immutable
class DisappearingMessagesState {
  final EphemeralDuration current;
  final bool isSaving;
  final String? error;

  const DisappearingMessagesState({
    this.current = EphemeralDuration.off,
    this.isSaving = false,
    this.error,
  });

  DisappearingMessagesState copyWith({
    EphemeralDuration? current,
    bool? isSaving,
    String? error,
  }) =>
      DisappearingMessagesState(
        current: current ?? this.current,
        isSaving: isSaving ?? this.isSaving,
        error: error,
      );
}

class DisappearingMessagesNotifier
    extends StateNotifier<DisappearingMessagesState> {
  final DeltaRpcClient _rpc;
  final int _chatId;

  DisappearingMessagesNotifier(this._rpc, this._chatId)
      : super(const DisappearingMessagesState()) {
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      final info = await _rpc.getChatInfo(_chatId);
      final secs = (info['ephemeral_timer'] as num?)?.toInt() ?? 0;
      state = state.copyWith(current: EphemeralDuration.fromSeconds(secs));
    } catch (_) {
      // keep default (off) if not available
    }
  }

  Future<void> setDuration(EphemeralDuration d) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _rpc.setConfig(_chatId, 'ephemeral_timer', d.seconds);
      state = state.copyWith(current: d, isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
}

final disappearingMessagesProvider = StateNotifierProvider.family<
    DisappearingMessagesNotifier, DisappearingMessagesState, int>(
  (ref, chatId) => DisappearingMessagesNotifier(
    ref.read(deltaRpcClientProvider),
    chatId,
  ),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class DisappearingMessagesScreen extends ConsumerWidget {
  final int chatId;

  const DisappearingMessagesScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(disappearingMessagesProvider(chatId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? OmegaColors.backgroundDark : OmegaColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Disappearing Messages',
          style: OmegaTextStyles.titleMedium.copyWith(
            color: isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
          ),
        ),
      ),
      body: state.isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _InfoBanner(isDark: isDark),
                const SizedBox(height: 8),
                _PreviewCard(current: state.current, isDark: isDark),
                const SizedBox(height: 8),
                _TimerOptionsList(
                  chatId: chatId,
                  selected: state.current,
                  isDark: isDark,
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.error!,
                      style: OmegaTextStyles.bodySmall
                          .copyWith(color: OmegaColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final bool isDark;

  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OmegaColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OmegaColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: OmegaColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'When enabled, new messages in this chat will automatically '
              'disappear after the selected time. This affects all participants.',
              style: OmegaTextStyles.bodySmall.copyWith(
                color: isDark
                    ? OmegaColors.textSecondaryDark
                    : OmegaColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown Preview Card ────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final EphemeralDuration current;
  final bool isDark;

  const _PreviewCard({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? OmegaColors.cardDark : OmegaColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _FlameAnimationWidget(active: current != EphemeralDuration.off),
          const SizedBox(height: 12),
          Text(
            current == EphemeralDuration.off
                ? 'Disappearing messages off'
                : 'Messages disappear after',
            style: OmegaTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? OmegaColors.textSecondaryDark
                  : OmegaColors.textSecondary,
            ),
          ),
          if (current != EphemeralDuration.off) ...[
            const SizedBox(height: 6),
            Text(
              current.label,
              style: OmegaTextStyles.titleLarge.copyWith(
                color: OmegaColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _CountdownPreview(duration: current),
          ],
        ],
      ),
    );
  }
}

// ── Animated Flame ────────────────────────────────────────────────────────────

class _FlameAnimationWidget extends StatefulWidget {
  final bool active;

  const _FlameAnimationWidget({required this.active});

  @override
  State<_FlameAnimationWidget> createState() => _FlameAnimationWidgetState();
}

class _FlameAnimationWidgetState extends State<_FlameAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_FlameAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const Icon(
        Icons.timer_off_outlined,
        size: 52,
        color: OmegaColors.textDisabled,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: const Icon(
            Icons.local_fire_department_rounded,
            size: 52,
            color: OmegaColors.warning,
          ),
        ),
      ),
    );
  }
}

// ── Countdown Preview Bar ─────────────────────────────────────────────────────

class _CountdownPreview extends StatefulWidget {
  final EphemeralDuration duration;

  const _CountdownPreview({required this.duration});

  @override
  State<_CountdownPreview> createState() => _CountdownPreviewState();
}

class _CountdownPreviewState extends State<_CountdownPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration.seconds <= 300
          ? const Duration(seconds: 5)
          : const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didUpdateWidget(_CountdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration.seconds <= 300
          ? const Duration(seconds: 5)
          : const Duration(seconds: 8);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Preview countdown',
          style: OmegaTextStyles.labelSmall.copyWith(
            color: OmegaColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final remaining = 1.0 - _controller.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: remaining,
                backgroundColor: OmegaColors.divider,
                color: remaining > 0.4
                    ? OmegaColors.success
                    : remaining > 0.15
                        ? OmegaColors.warning
                        : OmegaColors.error,
                minHeight: 6,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Timer Options List ────────────────────────────────────────────────────────

class _TimerOptionsList extends ConsumerWidget {
  final int chatId;
  final EphemeralDuration selected;
  final bool isDark;

  const _TimerOptionsList({
    required this.chatId,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? OmegaColors.cardDark : OmegaColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Select timer',
              style: OmegaTextStyles.labelMedium.copyWith(
                color: isDark
                    ? OmegaColors.textSecondaryDark
                    : OmegaColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...EphemeralDuration.values.map((d) {
            final isLast = d == EphemeralDuration.values.last;
            return _TimerOption(
              duration: d,
              isSelected: d == selected,
              isDark: isDark,
              showDivider: !isLast,
              onTap: () {
                ref
                    .read(disappearingMessagesProvider(chatId).notifier)
                    .setDuration(d);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final EphemeralDuration duration;
  final bool isSelected;
  final bool isDark;
  final bool showDivider;
  final VoidCallback onTap;

  const _TimerOption({
    required this.duration,
    required this.isSelected,
    required this.isDark,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary;
    final dividerColor = isDark ? OmegaColors.dividerDark : OmegaColors.divider;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _DurationIcon(duration: duration, isSelected: isSelected),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duration.label,
                        style: OmegaTextStyles.bodyLarge.copyWith(
                          color: textColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (duration != EphemeralDuration.off)
                        Text(
                          _subtitleFor(duration),
                          style: OmegaTextStyles.caption.copyWith(
                            color: isDark
                                ? OmegaColors.textSecondaryDark
                                : OmegaColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: OmegaColors.primary,
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: OmegaColors.textDisabled,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: dividerColor,
          ),
      ],
    );
  }

  String _subtitleFor(EphemeralDuration d) {
    return switch (d) {
      EphemeralDuration.oneMinute => 'Very short — great for sensitive info',
      EphemeralDuration.fiveMinutes => 'Short — disappears quickly',
      EphemeralDuration.thirtyMinutes => 'Half an hour',
      EphemeralDuration.oneHour => 'Gone within the hour',
      EphemeralDuration.oneDay => 'Disappears by tomorrow',
      EphemeralDuration.oneWeek => 'A week of history',
      EphemeralDuration.fourWeeks => 'About one month',
      _ => '',
    };
  }
}

class _DurationIcon extends StatelessWidget {
  final EphemeralDuration duration;
  final bool isSelected;

  const _DurationIcon({required this.duration, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? OmegaColors.primary : OmegaColors.textSecondary;

    if (duration == EphemeralDuration.off) {
      return Icon(Icons.timer_off_outlined, color: color, size: 22);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.local_fire_department_rounded,
            color: isSelected
                ? OmegaColors.primary.withOpacity(0.15)
                : OmegaColors.textDisabled.withOpacity(0.3),
            size: 30),
        Text(
          duration.shortLabel,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }
}
