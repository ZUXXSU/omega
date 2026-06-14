import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, int> reactions;
  final bool isOutgoing;
  final void Function(String emoji) onReact;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.isOutgoing,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.entries.map((entry) {
        return _ReactionChip(
          emoji: entry.key,
          count: entry.value,
          isOutgoing: isOutgoing,
          onTap: () => onReact(entry.key),
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isOutgoing;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isOutgoing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isOutgoing
              ? Colors.white.withOpacity(0.2)
              : OmegaColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutgoing
                ? Colors.white.withOpacity(0.3)
                : OmegaColors.primary.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: OmegaTextStyles.labelSmall.copyWith(
                  color: isOutgoing ? Colors.white70 : OmegaColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick react row (shown above context menu) ─────────────────────────────

class QuickReactRow extends StatelessWidget {
  final void Function(String emoji) onReact;
  final VoidCallback onMore;

  const QuickReactRow({super.key, required this.onReact, required this.onMore});

  static const _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._quickEmojis.map((e) => _EmojiButton(emoji: e, onTap: () => onReact(e))),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onMore,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.add_reaction_outlined, size: 22, color: OmegaColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
