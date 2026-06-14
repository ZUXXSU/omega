import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class VoiceMessageWidget extends StatefulWidget {
  final String? filePath;
  final int? durationMs;
  final bool isOutgoing;

  const VoiceMessageWidget({
    super.key,
    this.filePath,
    this.durationMs,
    required this.isOutgoing,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _total = Duration(milliseconds: widget.durationMs ?? 0);
    _posSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.playerStateStream.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s.playing;
          _isLoading = s.processingState == ProcessingState.loading ||
              s.processingState == ProcessingState.buffering;
        });
        if (s.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
        }
      }
    });
    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.filePath == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.idle) {
        await _player.setFilePath(widget.filePath!);
      }
      await _player.play();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isOutgoing ? Colors.white : OmegaColors.textPrimary;
    final fgSub = widget.isOutgoing ? Colors.white70 : OmegaColors.textSecondary;
    final trackBg = widget.isOutgoing ? Colors.white24 : OmegaColors.inputFill;
    final trackFg = widget.isOutgoing ? Colors.white : OmegaColors.primary;

    final progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayButton(
          isPlaying: _isPlaying,
          isLoading: _isLoading,
          color: fg,
          onTap: _toggle,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Waveform(progress: progress, isOutgoing: widget.isOutgoing),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_isPlaying ? _position : _total),
                    style: OmegaTextStyles.labelSmall.copyWith(color: fgSub, fontSize: 10),
                  ),
                  if (_isPlaying)
                    Text(
                      _formatDuration(_total - _position),
                      style: OmegaTextStyles.labelSmall.copyWith(color: fgSub, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final Color color;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: isLoading
            ? CircularProgressIndicator(strokeWidth: 2, color: color)
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: color,
                size: 32,
              ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final double progress;
  final bool isOutgoing;

  const _Waveform({required this.progress, required this.isOutgoing});

  // Fake waveform bars — real app would use audio_waveforms package
  static const _bars = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.7, 0.5, 0.6,
    0.8, 0.9, 0.7, 0.5, 0.6, 0.8, 0.4, 0.7, 0.9, 0.6,
    0.5, 0.8, 0.4, 0.7, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7];

  @override
  Widget build(BuildContext context) {
    final playedColor = isOutgoing ? Colors.white : OmegaColors.primary;
    final unplayedColor = isOutgoing ? Colors.white38 : OmegaColors.inputFill;

    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_bars.length, (i) {
          final fraction = i / _bars.length;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: _bars[i] * 24,
              decoration: BoxDecoration(
                color: fraction <= progress ? playedColor : unplayedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Voice recorder widget ──────────────────────────────────────────────────

class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String path, int durationMs) onFinished;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onFinished,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String get _timeLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OmegaColors.error.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            _timeLabel,
            style: OmegaTextStyles.labelLarge.copyWith(
              color: OmegaColors.error,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.delete_outline_rounded, color: OmegaColors.textSecondary),
            label: const Text('Cancel', style: TextStyle(color: OmegaColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              _timer?.cancel();
              // TODO: stop actual recording and get path
              widget.onFinished('/tmp/voice_${DateTime.now().millisecondsSinceEpoch}.aac', _elapsed.inMilliseconds);
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: OmegaColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(color: OmegaColors.error, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
