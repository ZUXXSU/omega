import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

/// Shown at the top of a chat when a contact hasn't been accepted yet.
/// DeltaChat's core UX: messages from unknown senders go to "contact requests".
class ContactRequestBanner extends StatelessWidget {
  final String senderName;
  final String senderEmail;
  final VoidCallback onAccept;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const ContactRequestBanner({
    super.key,
    required this.senderName,
    required this.senderEmail,
    required this.onAccept,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: OmegaColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OmegaColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.person_add_outlined, color: OmegaColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Request',
                        style: OmegaTextStyles.labelMedium.copyWith(
                          color: OmegaColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$senderName · $senderEmail',
                        style: OmegaTextStyles.bodySmall.copyWith(
                          color: OmegaColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: _BannerButton(
                  label: 'Accept',
                  icon: Icons.check_rounded,
                  color: OmegaColors.success,
                  onTap: onAccept,
                ),
              ),
              Container(width: 0.5, height: 44, color: OmegaColors.divider),
              Expanded(
                child: _BannerButton(
                  label: 'Block',
                  icon: Icons.block_rounded,
                  color: OmegaColors.error,
                  onTap: onBlock,
                ),
              ),
              Container(width: 0.5, height: 44, color: OmegaColors.divider),
              Expanded(
                child: _BannerButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: OmegaColors.textSecondary,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BannerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: OmegaTextStyles.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encryption info banner ─────────────────────────────────────────────────

/// Shown once per chat when E2E encryption is active.
class EncryptionActiveBanner extends StatefulWidget {
  const EncryptionActiveBanner({super.key});

  @override
  State<EncryptionActiveBanner> createState() => _EncryptionActiveBannerState();
}

class _EncryptionActiveBannerState extends State<EncryptionActiveBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: OmegaColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OmegaColors.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: OmegaColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages are end-to-end encrypted',
              style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.success),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: const Icon(Icons.close, size: 16, color: OmegaColors.success),
          ),
        ],
      ),
    );
  }
}
