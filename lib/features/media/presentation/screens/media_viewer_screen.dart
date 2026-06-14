import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/colors.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaPath;
  final String mediaType;

  const MediaViewerScreen({
    super.key,
    required this.mediaPath,
    required this.mediaType,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  bool _showControls = true;

  void _toggleControls() => setState(() => _showControls = !_showControls);

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(widget.mediaPath)],
    ));
  }

  void _saveToGallery() {
    // TODO: implement gallery save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving to gallery...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      _showControls ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(child: _mediaContent),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, color: Colors.white),
                          onPressed: _saveToGallery,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: _share,
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _mediaContent {
    switch (widget.mediaType) {
      case 'image':
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.asset(
            widget.mediaPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        );
      case 'video':
        return const Center(
          child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 72),
        );
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              widget.mediaPath.split('/').last,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        );
    }
  }
}
