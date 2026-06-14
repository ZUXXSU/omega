import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'biometric_service.g.dart';

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

/// Encapsulates the outcome of a biometric authentication attempt.
class BiometricResult {
  const BiometricResult({
    required this.success,
    this.error,
  });

  /// Whether authentication succeeded.
  final bool success;

  /// Human-readable error message when [success] is false; null on success.
  final String? error;

  @override
  String toString() =>
      'BiometricResult(success: $success, error: $error)';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Wraps the `local_auth` package with a clean interface used by the app lock
/// screen and settings flows.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns true if the device supports at least one enrolled biometric.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException catch (e, st) {
      AppLogger.e('BiometricService.isAvailable error', e, st);
      return false;
    }
  }

  /// Returns the list of biometric types available on this device (e.g.
  /// [BiometricType.fingerprint], [BiometricType.face]).
  Future<List<BiometricType>> getBiometricTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e, st) {
      AppLogger.e('BiometricService.getBiometricTypes error', e, st);
      return [];
    }
  }

  /// Attempts biometric authentication.
  ///
  /// [reason] is the localised string shown inside the system prompt.
  /// [stickyAuth] keeps the prompt alive if the user switches apps mid-auth.
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to unlock Omega',
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          useErrorDialogs: true,
          biometricOnly: false, // allow device PIN / pattern as fallback
        ),
      );
      return BiometricResult(success: authenticated);
    } on PlatformException catch (e, st) {
      AppLogger.e('BiometricService.authenticate error', e, st);
      return BiometricResult(
        success: false,
        error: _mapErrorCode(e.code),
      );
    } catch (e, st) {
      AppLogger.e('BiometricService.authenticate unexpected error', e, st);
      return BiometricResult(
        success: false,
        error: 'Authentication failed. Please try again.',
      );
    }
  }

  /// Cancels any in-progress authentication prompt.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException catch (e, st) {
      AppLogger.e('BiometricService.cancel error', e, st);
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _mapErrorCode(String code) {
    return switch (code) {
      'NotAvailable' => 'Biometric authentication is not available.',
      'NotEnrolled' => 'No biometrics enrolled. Please set up in device settings.',
      'LockedOut' =>
        'Too many failed attempts. Try again later.',
      'PermanentlyLockedOut' =>
        'Biometrics permanently locked. Use device PIN/pattern.',
      'PasscodeNotSet' =>
        'No device lock is set up. Enable a screen lock first.',
      _ => 'Authentication failed ($code).',
    };
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Provides a long-lived [BiometricService] instance.
@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}

/// Convenience async provider: resolves to true if biometrics are available.
@riverpod
Future<bool> biometricAvailable(BiometricAvailableRef ref) {
  return ref.watch(biometricServiceProvider).isAvailable();
}

/// Resolves to the list of enrolled biometric types.
@riverpod
Future<List<BiometricType>> biometricTypes(BiometricTypesRef ref) {
  return ref.watch(biometricServiceProvider).getBiometricTypes();
}
