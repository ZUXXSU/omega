import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> typingNames;
  final bool isGroup;

  const TypingIndicator({
    super.key,
    required this.typingNames,
    this.isGroup = false,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _dotCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 200)),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _label {
    if (widget.typingNames.isEmpty) return '';
    if (widget.typingNames.length == 1) {
      return widget.isGroup ? '${widget.typingNames[0]} is typing' : 'typing';
    }
    if (widget.typingNames.length == 2) {
      return '${widget.typingNames[0]} and ${widget.typingNames[1]} are typing';
    }
    return '${widget.typingNames[0]} and ${widget.typingNames.length - 1} others are typing';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingNames.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? OmegaColors.bubbleIncomingDark
                  : OmegaColors.bubbleIncoming,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._animations.map(
                  (anim) => AnimatedBuilder(
                    animation: anim,
                    builder: (_, __) => Opacity(
                      opacity: anim.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: OmegaColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: OmegaTextStyles.caption.copyWith(
              color: OmegaColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
