import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

/// Shown when an MDM admin policy enforces single-account mode and the user
/// attempts to add a second account.
///
/// There is no way to bypass this screen — the back button is disabled for
/// this flow and no navigation path exists to the account-add screen.
class SingleAccountLockScreen extends StatelessWidget {
  /// Optional IT support contact URL provided by the MDM policy.
  /// Falls back to a generic mailto link when null.
  final String? itSupportUrl;

  const SingleAccountLockScreen({
    super.key,
    this.itSupportUrl,
  });

  static const _defaultSupportUrl = 'mailto:it-support@yourorganization.com'
      '?subject=Omega%20-%20Single%20Account%20Policy%20Inquiry';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable the system back gesture / button — no bypass is allowed.
      canPop: false,
      child: Scaffold(
        backgroundColor: OmegaColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _LockIcon(),
                const SizedBox(height: 32),
                Text(
                  'Managed by your organization',
                  style: OmegaTextStyles.titleLarge.copyWith(
                    color: OmegaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your administrator has restricted this device to one account. '
                  'You cannot add additional accounts while this policy is active.',
                  style: OmegaTextStyles.bodyMedium.copyWith(
                    color: OmegaColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _PolicyBadge(),
                const Spacer(flex: 2),
                _ContactSupportButton(
                  url: itSupportUrl ?? _defaultSupportUrl,
                ),
                const SizedBox(height: 16),
                Text(
                  'This restriction is enforced by your organization\'s\n'
                  'Mobile Device Management (MDM) policy.',
                  style: OmegaTextStyles.caption.copyWith(
                    color: OmegaColors.textDisabled,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LockIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: OmegaColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: OmegaColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 36,
            color: OmegaColors.primary,
          ),
        ),
      ),
    );
  }
}

class _PolicyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: OmegaColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OmegaColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: OmegaColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Policy: single_account = enforced',
            style: OmegaTextStyles.labelSmall.copyWith(
              color: OmegaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportButton extends StatelessWidget {
  final String url;
  const _ContactSupportButton({required this.url});

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _launch,
        icon: const Icon(Icons.support_agent_rounded, size: 20),
        label: Text(
          'Contact IT Support',
          style: OmegaTextStyles.labelLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: OmegaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
