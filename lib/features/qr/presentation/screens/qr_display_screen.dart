import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/delta_rpc_client.dart';

class QrDisplayScreen extends ConsumerWidget {
  final int? chatId;
  final String title;

  const QrDisplayScreen({super.key, this.chatId, this.title = 'Your QR Code'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context, ref),
            tooltip: 'Share',
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: ref.read(deltaRpcClientProvider).getQrCode(chatId: chatId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: snapshot.data!,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: OmegaColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0D0D1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    chatId != null ? 'Scan to join this group' : 'Scan to add me as contact',
                    style: OmegaTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The QR code verifies your identity\nand sets up end-to-end encryption.',
                    style: OmegaTextStyles.bodySmall.copyWith(color: OmegaColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => _share(context, ref),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share as Image'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final qr = await ref.read(deltaRpcClientProvider).getQrCode(chatId: chatId);
    await SharePlus.instance.share(ShareParams(text: qr));
  }
}
