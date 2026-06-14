import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class DaySeparator extends StatelessWidget {
  final DateTime date;

  const DaySeparator({super.key, required this.date});

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('MMMM d').format(date);
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: OmegaColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _label,
              style: OmegaTextStyles.labelSmall.copyWith(
                color: OmegaColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── System info message (join/leave/key-change etc) ────────────────────────

class SystemInfoMessage extends StatelessWidget {
  final String text;

  const SystemInfoMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: OmegaColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: OmegaTextStyles.bodySmall.copyWith(
              color: OmegaColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
