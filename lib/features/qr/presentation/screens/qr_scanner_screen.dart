import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../core/constants/route_constants.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final QrScanMode mode;

  const QrScannerScreen({super.key, this.mode = QrScanMode.contact});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

enum QrScanMode { contact, groupInvite, accountLogin, backup }

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _processing = false;
  String? _result;
  bool _hasFlash = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _controller.start().then((_) {
      if (mounted) setState(() => _hasFlash = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    final qr = barcode!.rawValue!;

    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final result = await rpc.checkQr(qr: qr);
      final type = result['type'] as String? ?? '';
      final text = result['text'] as String? ?? '';
      final id = (result['id'] as num?)?.toInt();

      if (!mounted) return;

      switch (type) {
        case 'qr_ask_verifycontact':
          await _showVerifyContactDialog(qr, id, text);
        case 'qr_ask_verifygroup':
          await _showJoinGroupDialog(qr, id, text);
        case 'qr_account':
        case 'qr_login':
          await _showAccountLoginDialog(qr, text);
        case 'qr_backup':
          await _showBackupTransferDialog(qr);
        default:
          _showError('Unknown QR code: $text');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showVerifyContactDialog(String qr, int? contactId, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add & Verify Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, size: 48, color: OmegaColors.primary),
            const SizedBox(height: 12),
            Text(text, style: OmegaTextStyles.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'This contact will be added and verified via end-to-end encryption.',
              style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textSecondary),
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
    if (confirmed == true && mounted) {
      context.pop();
      if (contactId != null) context.go('/contacts/$contactId');
    }
  }

  Future<void> _showJoinGroupDialog(String qr, int? chatId, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add_rounded, size: 48, color: OmegaColors.secondary),
            const SizedBox(height: 12),
            Text(text, style: OmegaTextStyles.titleMedium, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Join')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.pop();
      if (chatId != null) context.go('/chats/$chatId');
    }
  }

  Future<void> _showAccountLoginDialog(String qr, String text) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Setup'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) context.go(RouteConstants.accountSetup);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupTransferDialog(String qr) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Transfer'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to source device...'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OmegaColors.error,
      ),
    );
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          switch (widget.mode) {
            QrScanMode.contact => 'Scan Contact',
            QrScanMode.groupInvite => 'Scan Group Invite',
            QrScanMode.accountLogin => 'Scan Account QR',
            QrScanMode.backup => 'Scan Backup QR',
          },
        ),
        actions: [
          if (_hasFlash)
            IconButton(
              icon: Icon(_flashOn ? Icons.flash_off : Icons.flash_on),
              onPressed: () {
                setState(() => _flashOn = !_flashOn);
                _controller.toggleTorch();
              },
            ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Processing...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at QR code',
                style: OmegaTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final scanSize = size.width * 0.65;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16))),
      ),
      paint,
    );

    final cornerPaint = Paint()
      ..color = OmegaColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    final corners = [
      [scanRect.topLeft, const Offset(cornerLen, 0), const Offset(0, cornerLen)],
      [scanRect.topRight, const Offset(-cornerLen, 0), const Offset(0, cornerLen)],
      [scanRect.bottomLeft, const Offset(cornerLen, 0), const Offset(0, -cornerLen)],
      [scanRect.bottomRight, const Offset(-cornerLen, 0), const Offset(0, -cornerLen)],
    ];

    for (final corner in corners) {
      final origin = corner[0] as Offset;
      final hEnd = origin + corner[1] as Offset;
      final vEnd = origin + corner[2] as Offset;
      canvas.drawLine(origin, hEnd, cornerPaint);
      canvas.drawLine(origin, vEnd, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
