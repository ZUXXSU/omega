import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/text_styles.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int chatId;
  final Future<void> Function(String text) onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.chatId,
    required this.onSend,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Future<void> _send() async {
    await widget.onSend(widget.controller.text);
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file_rounded),
                color: OmegaColors.textSecondary,
                onPressed: _showAttachMenu,
                tooltip: 'Attach',
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? OmegaColors.inputFillDark
                        : OmegaColors.inputFill,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: OmegaTextStyles.bodyMedium.copyWith(
                              color: OmegaColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        color: OmegaColors.textSecondary,
                        onPressed: _showEmojiPicker,
                        padding: const EdgeInsets.only(right: 4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hasText
                    ? _SendButton(onTap: _send, key: const ValueKey('send'))
                    : _VoiceButton(
                        isRecording: _isRecording,
                        onTap: _toggleRecording,
                        key: const ValueKey('voice'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _AttachMenu(),
    );
  }

  void _showEmojiPicker() {
    // TODO: integrate emoji_picker_flutter
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    // TODO: integrate record package
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: OmegaColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const _VoiceButton({super.key, required this.isRecording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isRecording ? OmegaColors.error : OmegaColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _AttachMenu extends StatelessWidget {
  const _AttachMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.image_outlined, 'Gallery', OmegaColors.secondary),
      (Icons.camera_alt_outlined, 'Camera', Colors.red),
      (Icons.insert_drive_file_outlined, 'Document', Colors.blue),
      (Icons.location_on_outlined, 'Location', Colors.orange),
      (Icons.contact_page_outlined, 'Contact', Colors.purple),
      (Icons.gif_box_outlined, 'GIF', Colors.pink),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: items.map((item) {
            return InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: item.$3.withOpacity(0.1),
                    child: Icon(item.$1, color: item.$3),
                  ),
                  const SizedBox(height: 8),
                  Text(item.$2, style: OmegaTextStyles.labelSmall),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
