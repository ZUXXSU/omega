import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';
import '../network/delta_rpc_client.dart';
import '../utils/logger.dart';

// Private color constants — avoids pulling in the full app theme from core layer.
const Color _kPrimary = Color(0xFF2B5BE8);
const Color _kSecondary = Color(0xFF00C896);
const Color _kError = Color(0xFFEF4444);

/// Handles all Omega deep-link URI schemes and routes them to the appropriate
/// screen or action.
///
/// Supported schemes:
///   openpgp4fpr:<fingerprint>          – verify contact
///   dcaccount:<url>                    – add chatmail account
///   dclogin:<email>?p=<pw>&h=<host>   – login with credentials
///   https://i.delta.chat/<token>       – chatmail instant account
///   mailto:<email>                     – start new chat
///   DCBACKUP:<data>                    – restore from backup payload
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Main entry point. Call from [AppLinksService] or any platform channel.
  static Future<void> handleUri(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppLogger.i('DeepLinkHandler.handleUri: $uri');

    final scheme = uri.scheme.toLowerCase();

    try {
      switch (scheme) {
        case 'openpgp4fpr':
          await _handleOpenPgp4Fpr(uri, context, ref);

        case 'dcaccount':
          await _handleDcAccount(uri, context, ref);

        case 'dclogin':
          await _handleDcLogin(uri, context, ref);

        case 'dcbackup':
          await _handleDcBackup(uri, context, ref);

        case 'mailto':
          await _handleMailto(uri, context, ref);

        case 'https':
        case 'http':
          await _handleHttps(uri, context, ref);

        default:
          AppLogger.w('DeepLinkHandler: unrecognised scheme "$scheme"');
          _showUnknownLinkSnack(context, uri.toString());
      }
    } catch (e, st) {
      AppLogger.e('DeepLinkHandler error for $uri', e, st);
      if (context.mounted) {
        _showErrorSnack(context, 'Could not open link: $e');
      }
    }
  }

  // ── openpgp4fpr:<fingerprint> ─────────────────────────────────────────────

  /// Initiates a contact verification flow using the PGP fingerprint embedded
  /// in the URI path (the entire opaque part after the scheme).
  static Future<void> _handleOpenPgp4Fpr(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // openpgp4fpr URIs are not hierarchical: uri.path is the fingerprint.
    final fingerprint = uri.path.isNotEmpty ? uri.path : uri.toString().substring('openpgp4fpr:'.length);

    AppLogger.d('OpenPGP4FPR verify: fingerprint=$fingerprint');

    final rpc = ref.read(deltaRpcClientProvider);
    final qrResult = await rpc.checkQr(qr: 'OPENPGP4FPR:$fingerprint');
    final type = qrResult['type'] as String? ?? '';
    final contactId = (qrResult['id'] as num?)?.toInt();

    if (!context.mounted) return;

    if (type == 'qr_ask_verifycontact' && contactId != null) {
      final confirmed = await _showVerifyContactDialog(
        context,
        qrResult['text'] as String? ?? 'Verify Contact',
      );
      if (confirmed == true && context.mounted) {
        context.go('/contacts/$contactId');
      }
    } else {
      _showErrorSnack(context, 'Contact verification failed.');
    }
  }

  // ── dcaccount:<url> ───────────────────────────────────────────────────────

  /// Adds a chatmail provider account from a DC account URL.
  static Future<void> _handleDcAccount(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // The DC account URL is typically the full original URI as a string,
    // or the host + path encodes a chatmail endpoint.
    final accountUrl = uri.toString(); // e.g. dcaccount:https://example.chatmail.org
    AppLogger.d('DC account URL: $accountUrl');

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Chatmail Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline_rounded, size: 48, color: _kPrimary),
            const SizedBox(height: 12),
            Text(
              'Set up an account on:\n${uri.host.isNotEmpty ? uri.host : accountUrl}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.go(RouteConstants.accountSetup);
    }
  }

  // ── dclogin:<email>?p=<password>&h=<host> ────────────────────────────────

  /// Logs in with credentials provided in the URI query parameters.
  static Future<void> _handleDcLogin(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // dclogin:user@host.com?p=password&h=mailhost.com
    final email = uri.path;
    final password = uri.queryParameters['p'];
    final host = uri.queryParameters['h'];

    AppLogger.d('DC login: email=$email host=$host');

    if (email.isEmpty || password == null) {
      if (context.mounted) _showErrorSnack(context, 'Invalid login link.');
      return;
    }

    final rpc = ref.read(deltaRpcClientProvider);
    final accountId = await rpc.addAccount();
    await rpc.configureAccount(
      accountId: accountId,
      addr: email,
      password: password,
      mailServer: host,
    );

    if (!context.mounted) return;
    context.go(RouteConstants.chatList);
  }

  // ── https://i.delta.chat/<account_token> ─────────────────────────────────

  /// Creates an instant chatmail account from a token URL.
  static Future<void> _handleHttps(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final host = uri.host.toLowerCase();

    if (host == 'i.delta.chat') {
      final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      AppLogger.d('Chatmail instant account token: $token');

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Create Instant Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              const Text(
                'Set up a ready-to-use chatmail account instantly.',
                textAlign: TextAlign.center,
              ),
              if (token.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Token: $token',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        final rpc = ref.read(deltaRpcClientProvider);
        final qrResult = await rpc.checkQr(qr: uri.toString());
        if (qrResult['state'] == 200 && context.mounted) {
          context.go(RouteConstants.accountSetup);
        }
      }
    } else {
      // Generic HTTPS: not an Omega-specific URL
      AppLogger.w('DeepLinkHandler: non-Omega HTTPS URL $uri ignored');
      if (context.mounted) _showUnknownLinkSnack(context, uri.toString());
    }
  }

  // ── mailto:<email> ────────────────────────────────────────────────────────

  /// Opens a new chat with the given email address.
  static Future<void> _handleMailto(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final email = uri.path; // mailto:alice@example.com → path is alice@example.com
    AppLogger.d('Mailto: email=$email');

    if (email.isEmpty) {
      if (context.mounted) _showErrorSnack(context, 'Invalid mailto link.');
      return;
    }

    final rpc = ref.read(deltaRpcClientProvider);
    final contactId = await rpc.createContact(addr: email);
    final chatId = await rpc.createChatByContactId(contactId);

    if (!context.mounted) return;
    context.go('/chats/$chatId');
  }

  // ── DCBACKUP:<data> ───────────────────────────────────────────────────────

  /// Restores from a backup payload encoded directly in the URI.
  static Future<void> _handleDcBackup(
    Uri uri,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // The backup data follows the scheme.  For wireless transfer it is the
    // same QR payload that the sending device generated.
    final backupData = uri.toString().substring('dcbackup:'.length);
    AppLogger.d('DCBACKUP payload length: ${backupData.length}');

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restore_rounded, size: 48, color: _kPrimary),
            SizedBox(height: 12),
            Text(
              'A backup transfer was detected. '
              'This will replace all current data. Continue?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Simulate backup restore via QR payload
      final rpc = ref.read(deltaRpcClientProvider);
      final qrResult = await rpc.checkQr(qr: 'DCBACKUP:$backupData');
      if (qrResult['state'] == 200 && context.mounted) {
        context.go(RouteConstants.backupRestore);
      }
    }
  }

  // ── Dialogs & helpers ──────────────────────────────────────────────────────

  static Future<bool?> _showVerifyContactDialog(
    BuildContext context,
    String contactText,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add & Verify Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, size: 48, color: _kPrimary),
            const SizedBox(height: 12),
            Text(contactText, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'This contact will be verified via end-to-end encryption.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify & Add')),
        ],
      ),
    );
  }

  static void _showErrorSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _kError,
      ),
    );
  }

  static void _showUnknownLinkSnack(BuildContext context, String url) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unknown link: $url')),
    );
  }
}
