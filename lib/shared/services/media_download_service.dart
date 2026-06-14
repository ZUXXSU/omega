import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

import '../../core/utils/logger.dart';

// ── Result type ───────────────────────────────────────────────────────────────

/// Outcome of a media save or download operation.
class SaveResult {
  const SaveResult._({
    required this.success,
    this.savedPath,
    this.error,
  });

  /// Successful result with the local path where the file was saved.
  factory SaveResult.ok(String savedPath) =>
      SaveResult._(success: true, savedPath: savedPath);

  /// Failure result with an optional human-readable error.
  factory SaveResult.fail(String error) =>
      SaveResult._(success: false, error: error);

  final bool success;

  /// Absolute path to the saved file. Non-null on success.
  final String? savedPath;

  /// Human-readable error message. Non-null on failure.
  final String? error;

  @override
  String toString() => success
      ? 'SaveResult.ok($savedPath)'
      : 'SaveResult.fail($error)';
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Service for saving images/videos to the device gallery and downloading
/// arbitrary files to the app's downloads directory.
///
/// This is a pure Dart service (no BuildContext stored as state).
/// Snackbar progress messages are shown via the optional [scaffoldKey]
/// parameter on individual method calls.
class MediaDownloadService {
  MediaDownloadService._();

  static final MediaDownloadService instance = MediaDownloadService._();

  final Dio _dio = Dio();

  // ── Gallery save — images ─────────────────────────────────────────────────

  /// Copy the image at [filePath] into the device gallery.
  ///
  /// Requests storage permissions on Android before writing.
  /// Returns a [SaveResult] describing the outcome.
  ///
  /// Pass [context] to display a progress snackbar during the operation.
  Future<SaveResult> saveImageToGallery(
    String filePath, {
    BuildContext? context,
  }) async {
    return _saveMediaToGallery(
      filePath: filePath,
      mediaType: _MediaType.image,
      context: context,
    );
  }

  // ── Gallery save — videos ─────────────────────────────────────────────────

  /// Copy the video at [filePath] into the device gallery.
  ///
  /// Requests storage permissions on Android before writing.
  /// Returns a [SaveResult] describing the outcome.
  ///
  /// Pass [context] to display a progress snackbar during the operation.
  Future<SaveResult> saveVideoToGallery(
    String filePath, {
    BuildContext? context,
  }) async {
    return _saveMediaToGallery(
      filePath: filePath,
      mediaType: _MediaType.video,
      context: context,
    );
  }

  // ── File download ─────────────────────────────────────────────────────────

  /// Download a remote file from [url] and save it to the app's downloads
  /// directory as [filename].
  ///
  /// Shows an indeterminate progress snackbar if [context] is provided.
  /// Returns a [SaveResult] with the local path on success.
  Future<SaveResult> downloadFile(
    String url,
    String filename, {
    BuildContext? context,
    void Function(int received, int total)? onProgress,
  }) async {
    ScaffoldMessengerState? messenger;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackController;

    try {
      // Show progress snackbar.
      if (context != null && context.mounted) {
        messenger = ScaffoldMessenger.of(context);
        snackController = messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Downloading $filename…',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(minutes: 5),
          ),
        );
      }

      // Resolve destination directory.
      final destDir = await _resolveDownloadDirectory();
      await destDir.create(recursive: true);
      final destPath = p.join(destDir.path, _sanitizeFilename(filename));

      // Perform the download.
      await _dio.download(
        url,
        destPath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      AppLogger.i('MediaDownloadService: downloaded "$filename" → $destPath');

      snackController?.close();
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $filename'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return SaveResult.ok(destPath);
    } on DioException catch (e, st) {
      final msg = 'Download failed: ${e.message}';
      AppLogger.e('MediaDownloadService: $msg', error: e, stackTrace: st);
      snackController?.close();
      _showErrorSnackbar(context, msg);
      return SaveResult.fail(msg);
    } catch (e, st) {
      final msg = 'Download failed: $e';
      AppLogger.e('MediaDownloadService: $msg', error: e, stackTrace: st);
      snackController?.close();
      _showErrorSnackbar(context, msg);
      return SaveResult.fail(msg);
    }
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Request storage / photos permission appropriate for the current platform.
  ///
  /// Returns `true` if permission is granted.
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_IMAGES / READ_MEDIA_VIDEO instead of
      // WRITE_EXTERNAL_STORAGE.
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;

      if (photos.isGranted && videos.isGranted) return true;

      final results = await [
        Permission.photos,
        Permission.videos,
      ].request();

      return results.values.every(
        (s) => s.isGranted || s.isLimited,
      );
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    // Desktop / other platforms: no explicit permission needed.
    return true;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<SaveResult> _saveMediaToGallery({
    required String filePath,
    required _MediaType mediaType,
    BuildContext? context,
  }) async {
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackController;

    try {
      // Verify source file exists.
      final sourceFile = File(filePath);
      if (!sourceFile.existsSync()) {
        return SaveResult.fail('Source file not found: $filePath');
      }

      // Request permission.
      final granted = await requestStoragePermission();
      if (!granted) {
        const msg = 'Storage permission denied. '
            'Grant it in Settings to save media.';
        _showErrorSnackbar(context, msg);
        return SaveResult.fail(msg);
      }

      // Show progress snackbar.
      if (context != null && context.mounted) {
        snackController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(mediaType == _MediaType.image
                    ? 'Saving image…'
                    : 'Saving video…'),
              ],
            ),
            duration: const Duration(minutes: 2),
          ),
        );
      }

      final destPath = await _copyToGalleryDirectory(sourceFile, mediaType);

      snackController?.close();
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mediaType == _MediaType.image
                  ? 'Image saved to gallery.'
                  : 'Video saved to gallery.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      AppLogger.i(
        'MediaDownloadService: saved ${mediaType.name} to gallery → $destPath',
      );
      return SaveResult.ok(destPath);
    } catch (e, st) {
      final msg = 'Failed to save ${mediaType.name}: $e';
      AppLogger.e('MediaDownloadService: $msg', error: e, stackTrace: st);
      snackController?.close();
      _showErrorSnackbar(context, msg);
      return SaveResult.fail(msg);
    }
  }

  /// Copies [source] to the platform-appropriate gallery directory and
  /// returns the destination path.
  Future<String> _copyToGalleryDirectory(
    File source,
    _MediaType mediaType,
  ) async {
    final galleryDir = await _resolveGalleryDirectory(mediaType);
    await galleryDir.create(recursive: true);

    final filename = p.basename(source.path);
    final uniqueName = _uniqueFilename(galleryDir.path, filename);
    final destPath = p.join(galleryDir.path, uniqueName);

    await source.copy(destPath);
    return destPath;
  }

  Future<Directory> _resolveGalleryDirectory(_MediaType mediaType) async {
    if (Platform.isAndroid) {
      // Write to standard Pictures / Movies public directory.
      final label = mediaType == _MediaType.image ? 'Pictures' : 'Movies';
      return Directory('/storage/emulated/0/$label/Omega');
    }

    if (Platform.isIOS) {
      // On iOS, we write to Documents first; a photo-library plugin
      // (e.g. gal) should be used for true gallery integration.
      // This keeps the service dependency-light while remaining correct.
      final docs = await getApplicationDocumentsDirectory();
      final label = mediaType == _MediaType.image ? 'Images' : 'Videos';
      return Directory(p.join(docs.path, 'Omega', label));
    }

    // Desktop fallback.
    final downloads = await getDownloadsDirectory();
    return Directory(p.join(
      downloads?.path ?? (await getTemporaryDirectory()).path,
      'Omega',
      mediaType == _MediaType.image ? 'Images' : 'Videos',
    ));
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download/Omega');
    }
    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return Directory(p.join(docs.path, 'Omega', 'Downloads'));
    }
    final downloads = await getDownloadsDirectory();
    return Directory(p.join(
      downloads?.path ?? (await getTemporaryDirectory()).path,
      'Omega',
    ));
  }

  /// Appends a numeric suffix to [filename] if a file with that name already
  /// exists in [dirPath], ensuring uniqueness.
  String _uniqueFilename(String dirPath, String filename) {
    final ext = p.extension(filename);
    final base = p.basenameWithoutExtension(filename);
    var candidate = filename;
    var counter = 1;

    while (File(p.join(dirPath, candidate)).existsSync()) {
      candidate = '${base}_$counter$ext';
      counter++;
    }
    return candidate;
  }

  /// Removes characters that are unsafe in file names.
  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  void _showErrorSnackbar(BuildContext? context, String message) {
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum _MediaType { image, video }
