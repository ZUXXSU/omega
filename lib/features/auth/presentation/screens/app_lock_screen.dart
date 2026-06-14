import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/platform/biometric_service.dart';

/// Full-screen lock screen shown when the app resumes and biometric lock is
/// enabled in settings.
///
/// - Displays the Omega logo and "Unlock Omega" heading.
/// - Auto-triggers biometric authentication on first render.
/// - On failure shows a retry button and a "Use passcode" fallback.
/// - The hardware/gesture back button is completely suppressed.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  bool _authenticating = false;
  String? _errorMessage;
  bool _showPasscodeOption = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAuth());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Auth logic
  // -------------------------------------------------------------------------

  Future<void> _triggerAuth() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    final service = ref.read(biometricServiceProvider);
    final result = await service.authenticate(
      reason: 'Unlock Omega to continue',
      stickyAuth: true,
    );

    if (!mounted) return;

    if (result.success) {
      _onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _errorMessage = result.error ?? 'Authentication failed. Try again.';
        _showPasscodeOption = true;
      });
    }
  }

  Future<void> _triggerPasscodeAuth() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    final service = ref.read(biometricServiceProvider);
    // biometricOnly: false allows the system to fall back to PIN/pattern.
    final result = await service.authenticate(
      reason: 'Unlock Omega with your device passcode',
      stickyAuth: true,
      sensitiveTransaction: true,
    );

    if (!mounted) return;

    if (result.success) {
      _onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _errorMessage = result.error ?? 'Passcode authentication failed.';
      });
    }
  }

  void _onUnlocked() {
    if (!mounted) return;
    context.go(RouteConstants.chatList);
  }

  // -------------------------------------------------------------------------
  // Biometric icon helper
  // -------------------------------------------------------------------------

  Future<IconData> _resolveIcon() async {
    final types = await ref.read(biometricTypesProvider.future);
    if (types.contains(BiometricType.face)) {
      return Icons.face_unlock_outlined;
    }
    if (types.contains(BiometricType.iris)) {
      return Icons.remove_red_eye_outlined;
    }
    return Icons.fingerprint;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? OmegaColors.backgroundDark : OmegaColors.backgroundLight;
    final textPrimary =
        isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary;
    final textSecondary =
        isDark ? OmegaColors.textSecondaryDark : OmegaColors.textSecondary;

    // Back button is completely suppressed — user MUST authenticate.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // No-op: lock screen cannot be dismissed.
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ----------------------------------------------------------
                    // Logo
                    // ----------------------------------------------------------
                    _OmegaLockLogo(isDark: isDark),
                    const SizedBox(height: 32),

                    // ----------------------------------------------------------
                    // Title
                    // ----------------------------------------------------------
                    Text(
                      'Unlock Omega',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Authenticate to continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ----------------------------------------------------------
                    // Biometric button
                    // ----------------------------------------------------------
                    FutureBuilder<IconData>(
                      future: _resolveIcon(),
                      builder: (context, snap) {
                        final icon = snap.data ?? Icons.fingerprint;
                        return _BiometricButton(
                          icon: icon,
                          authenticating: _authenticating,
                          onTap: _triggerAuth,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ----------------------------------------------------------
                    // Error message
                    // ----------------------------------------------------------
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _errorMessage != null
                          ? Padding(
                              key: ValueKey(_errorMessage),
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: OmegaColors.error,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ----------------------------------------------------------
                    // Retry button (visible after first failure)
                    // ----------------------------------------------------------
                    if (_errorMessage != null && !_authenticating) ...[
                      FilledButton.icon(
                        onPressed: _triggerAuth,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                        style: FilledButton.styleFrom(
                          backgroundColor: OmegaColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ----------------------------------------------------------
                    // Passcode fallback
                    // ----------------------------------------------------------
                    if (_showPasscodeOption && !_authenticating)
                      TextButton(
                        onPressed: _triggerPasscodeAuth,
                        child: Text(
                          'Use passcode',
                          style: TextStyle(
                            color: OmegaColors.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _OmegaLockLogo extends StatelessWidget {
  const _OmegaLockLogo({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: OmegaColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OmegaColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Ω',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({
    required this.icon,
    required this.authenticating,
    required this.onTap,
  });

  final IconData icon;
  final bool authenticating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: authenticating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: authenticating
              ? OmegaColors.primary.withValues(alpha: 0.1)
              : OmegaColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: authenticating
                ? OmegaColors.primary.withValues(alpha: 0.3)
                : OmegaColors.primary,
            width: 2,
          ),
        ),
        child: authenticating
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      OmegaColors.primary,
                    ),
                  ),
                ),
              )
            : Icon(
                icon,
                size: 40,
                color: OmegaColors.primary,
              ),
      ),
    );
  }
}
