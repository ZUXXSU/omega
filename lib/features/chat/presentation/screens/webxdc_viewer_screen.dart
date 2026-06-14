import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

/// Metadata for a WebXDC mini-app loaded from a .xdc archive.
class WebxdcAppInfo {
  const WebxdcAppInfo({
    required this.name,
    required this.summary,
    required this.xdcFilePath,
    this.iconPath,
    this.selfAddr = '',
    this.selfName = '',
    this.chatId,
    this.messageId,
  });

  final String name;
  final String summary;
  final String xdcFilePath;
  final String? iconPath;
  final String selfAddr;
  final String selfName;
  final int? chatId;
  final int? messageId;
}

/// Result of a webxdc.sendUpdate() call from JS.
class WebxdcUpdate {
  const WebxdcUpdate({
    required this.payload,
    this.info,
    this.summary,
    this.document,
  });

  final dynamic payload;
  final String? info;
  final String? summary;
  final String? document;

  factory WebxdcUpdate.fromJson(Map<String, dynamic> json) {
    return WebxdcUpdate(
      payload: json['payload'],
      info: json['info'] as String?,
      summary: json['summary'] as String?,
      document: json['document'] as String?,
    );
  }
}

/// WebXDC mini-app viewer screen.
///
/// Loads a .xdc archive (ZIP) into a WebViewWidget, injecting the
/// `window.webxdc` JavaScript bridge so the mini-app can send and
/// receive updates through the Omega/DeltaChat channel.
class WebxdcViewerScreen extends StatefulWidget {
  const WebxdcViewerScreen({
    super.key,
    required this.appInfo,
    this.onUpdateSent,
  });

  /// Metadata and path to the .xdc file.
  final WebxdcAppInfo appInfo;

  /// Called whenever the mini-app fires webxdc.sendUpdate().
  final void Function(WebxdcUpdate update)? onUpdateSent;

  @override
  State<WebxdcViewerScreen> createState() => _WebxdcViewerScreenState();
}

class _WebxdcViewerScreenState extends State<WebxdcViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // Queued updates coming in from the outside (e.g. newly received messages)
  // that will be forwarded to the JS listener.
  final List<Map<String, dynamic>> _pendingIncomingUpdates = [];
  int _lastSerialSent = 0;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  // ── WebView initialisation ──────────────────────────────────────────────

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _injectWebxdcBridge();
          },
          onWebResourceError: (err) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load mini-app: ${err.description}';
            });
          },
          onNavigationRequest: (request) {
            // Intercept webxdc:// scheme used by the JS bridge channel.
            if (request.url.startsWith('webxdc://')) {
              _handleWebxdcScheme(request.url);
              return NavigationDecision.prevent;
            }
            // Block all external navigation — mini-apps are sandboxed.
            if (!request.url.startsWith('file://') &&
                !request.url.startsWith('about:')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'WebxdcBridge',
        onMessageReceived: _onBridgeMessage,
      );

    _loadXdcContent();
  }

  // ── XDC archive loading ─────────────────────────────────────────────────

  Future<void> _loadXdcContent() async {
    try {
      // The .xdc file is a ZIP archive. For a production implementation,
      // extract it to a temp directory and load index.html from there.
      // Here we load the archive path directly — the WebView platform
      // implementation must support loadFile for local content.
      final file = File(widget.appInfo.xdcFilePath);
      if (!file.existsSync()) {
        // Fallback: render a minimal stub for development / missing archives.
        await _loadStubContent();
        return;
      }
      await _controller.loadFile(widget.appInfo.xdcFilePath);
    } catch (e) {
      // If the archive cannot be loaded directly (e.g. it needs extraction),
      // fall back to a stub page so the bridge is still functional.
      await _loadStubContent();
    }
  }

  Future<void> _loadStubContent() async {
    final html = _buildStubHtml();
    await _controller.loadHtmlString(html, baseUrl: 'file:///webxdc/');
  }

  String _buildStubHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>${_escape(widget.appInfo.name)}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f7fa;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      color: #0d0d1a;
    }
    .card {
      background: white;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 360px;
      width: 100%;
      text-align: center;
      box-shadow: 0 2px 16px rgba(0,0,0,0.08);
    }
    .icon { font-size: 56px; margin-bottom: 16px; }
    h1 { font-size: 20px; font-weight: 600; margin-bottom: 8px; }
    p { font-size: 14px; color: #6b7280; line-height: 1.5; }
    .badge {
      display: inline-flex; align-items: center; gap: 6px;
      background: #f0f2f5; border-radius: 99px;
      padding: 4px 12px; font-size: 12px; color: #6b7280;
      margin-top: 20px;
    }
    .dot { width: 6px; height: 6px; border-radius: 50%; background: #10b981; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">&#128640;</div>
    <h1>${_escape(widget.appInfo.name)}</h1>
    <p>${_escape(widget.appInfo.summary)}</p>
    <div class="badge"><span class="dot"></span>WebXDC Mini App</div>
  </div>
</body>
</html>''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // ── JS Bridge injection ─────────────────────────────────────────────────

  /// Injects the `window.webxdc` object that conforms to the WebXDC spec.
  /// https://webxdc.org/docs/spec.html
  Future<void> _injectWebxdcBridge() async {
    final selfAddr = _escape(widget.appInfo.selfAddr);
    final selfName = _escape(widget.appInfo.selfName);

    const bridge = r'''
(function() {
  if (window.__webxdcInjected) return;
  window.__webxdcInjected = true;

  var _updateListener = null;
  var _lastSerial = 0;

  window.webxdc = Object.freeze({
    // ── Info ──────────────────────────────────────────────────────────
    selfAddr: '__SELF_ADDR__',
    selfName: '__SELF_NAME__',

    // ── Send an update to all participants ────────────────────────────
    sendUpdate: function(update, descr) {
      var payload = {
        type: 'sendUpdate',
        update: update,
        descr: descr || ''
      };
      WebxdcBridge.postMessage(JSON.stringify(payload));
      return Promise.resolve();
    },

    // ── Register a listener for incoming updates ───────────────────────
    setUpdateListener: function(cb, serial) {
      _updateListener = cb;
      _lastSerial = serial || 0;
      // Notify Flutter that we are ready to receive updates.
      WebxdcBridge.postMessage(JSON.stringify({
        type: 'ready',
        serial: _lastSerial
      }));
      return Promise.resolve();
    },

    // ── Internal: called by Flutter to deliver an update to the app ───
    __deliverUpdate: function(statusUpdate) {
      if (_updateListener) {
        try {
          _updateListener(statusUpdate);
        } catch(e) {
          console.error('webxdc updateListener error:', e);
        }
      }
    }
  });

  // Expose the delivery function so Flutter can call it.
  window.__deliverWebxdcUpdate = function(json) {
    window.webxdc.__deliverUpdate(JSON.parse(json));
  };

  console.log('webxdc bridge injected for __SELF_ADDR__');
})();
''';

    final script = bridge
        .replaceAll('__SELF_ADDR__', selfAddr)
        .replaceAll('__SELF_NAME__', selfName);

    await _controller.runJavaScript(script);

    // Flush any updates that arrived before the listener was registered.
    _flushPendingUpdates();
  }

  // ── Message handling from JS ────────────────────────────────────────────

  void _onBridgeMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'sendUpdate':
          final updateData = data['update'] as Map<String, dynamic>? ?? {};
          final update = WebxdcUpdate.fromJson(updateData);
          widget.onUpdateSent?.call(update);
          break;

        case 'ready':
          _lastSerialSent = (data['serial'] as int?) ?? 0;
          _flushPendingUpdates();
          break;

        default:
          debugPrint('WebxdcBridge: unknown message type "$type"');
      }
    } catch (e) {
      debugPrint('WebxdcBridge: failed to parse message: $e');
    }
  }

  // Intercept webxdc:// URL scheme (alternative bridge mechanism).
  void _handleWebxdcScheme(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host == 'send-update') {
        final jsonStr = uri.queryParameters['data'] ?? '{}';
        final updateData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final update = WebxdcUpdate.fromJson(updateData);
        widget.onUpdateSent?.call(update);
      }
    } catch (e) {
      debugPrint('WebxdcViewerScreen: bad webxdc:// URL: $e');
    }
  }

  // ── Delivering updates into the mini-app ───────────────────────────────

  /// Enqueue an incoming update (e.g. from a remote participant) to forward
  /// to the mini-app's JS listener.
  void deliverUpdate(Map<String, dynamic> statusUpdate) {
    _pendingIncomingUpdates.add(statusUpdate);
    _flushPendingUpdates();
  }

  void _flushPendingUpdates() {
    if (_pendingIncomingUpdates.isEmpty) return;
    for (final update in List.of(_pendingIncomingUpdates)) {
      _deliverUpdateToJs(update);
    }
    _pendingIncomingUpdates.clear();
  }

  Future<void> _deliverUpdateToJs(Map<String, dynamic> update) async {
    final json = jsonEncode(update);
    final escaped = json.replaceAll("'", r"\'");
    await _controller.runJavaScript(
      "window.__deliverWebxdcUpdate && window.__deliverWebxdcUpdate('$escaped');",
    );
  }

  // ── Share / open-in-browser ─────────────────────────────────────────────

  Future<void> _shareApp() async {
    await Share.share(
      'Check out "${widget.appInfo.name}" mini-app on Omega!',
      subject: widget.appInfo.name,
    );
  }

  Future<void> _openInBrowser() async {
    // Mini-apps are local only; offer to open the XDC file path for dev use.
    final uri = Uri.file(widget.appInfo.xdcFilePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open in external browser.')),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? OmegaColors.backgroundDark : OmegaColors.backgroundLight,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(child: _buildWebViewArea()),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      title: Text(
        widget.appInfo.name,
        style: OmegaTextStyles.titleMedium.copyWith(
          color:
              isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color:
                isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
            size: 22,
          ),
          onPressed: _shareApp,
          tooltip: 'Share mini-app',
        ),
        IconButton(
          icon: Icon(
            Icons.open_in_browser_outlined,
            color:
                isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary,
            size: 22,
          ),
          onPressed: _openInBrowser,
          tooltip: 'Open in browser',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // App icon
          _buildAppIcon(),
          const SizedBox(width: 12),
          // Name + summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appInfo.name,
                  style: OmegaTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? OmegaColors.textPrimaryDark
                        : OmegaColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.appInfo.summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.appInfo.summary,
                    style: OmegaTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? OmegaColors.textSecondaryDark
                          : OmegaColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    const size = 44.0;
    if (widget.appInfo.iconPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(widget.appInfo.iconPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon(size),
        ),
      );
    }
    return _defaultIcon(size);
  }

  Widget _defaultIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: OmegaColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.widgets_outlined,
        color: OmegaColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildWebViewArea() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: OmegaColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        if (_errorMessage != null)
          _buildErrorView(_errorMessage!),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      color: OmegaColors.backgroundLight,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: OmegaColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: OmegaTextStyles.bodyMedium
                  .copyWith(color: OmegaColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _loadXdcContent();
              },
              icon: const Icon(Icons.refresh_rounded,
                  color: OmegaColors.primary),
              label: Text(
                'Retry',
                style: OmegaTextStyles.labelMedium
                    .copyWith(color: OmegaColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      color: isDark ? OmegaColors.surfaceDark : OmegaColors.surfaceLight,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: isDark
                ? OmegaColors.textSecondaryDark
                : OmegaColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Mini App · End-to-end encrypted',
            style: OmegaTextStyles.labelSmall.copyWith(
              color: isDark
                  ? OmegaColors.textSecondaryDark
                  : OmegaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
