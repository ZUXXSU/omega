import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/text_styles.dart';
import '../../../../../shared/models/message.dart';
import '../../../../../shared/widgets/omega_avatar.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = false,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            message.isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isOutgoing) ...[
            if (showAvatar)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: OmegaAvatar(name: 'A', size: 28),
              )
            else
              const SizedBox(width: 34),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: _BubbleContent(message: message, showSenderName: showSenderName),
            ),
          ),
          if (message.isOutgoing) ...[
            const SizedBox(width: 4),
            _StatusIcon(state: message.state),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _MessageOptions(message: message),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final Message message;
  final bool showSenderName;

  const _BubbleContent({required this.message, required this.showSenderName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = message.isOutgoing
        ? OmegaColors.bubbleOutgoing
        : (isDark ? OmegaColors.bubbleIncomingDark : OmegaColors.bubbleIncoming);
    final textColor = message.isOutgoing ? Colors.white : (isDark ? OmegaColors.textPrimaryDark : OmegaColors.textPrimary);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isOutgoing ? 16 : 4),
          bottomRight: Radius.circular(message.isOutgoing ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSenderName) ...[
              Text(
                'Sender',
                style: OmegaTextStyles.labelSmall.copyWith(color: OmegaColors.secondary),
              ),
              const SizedBox(height: 2),
            ],
            if (message.quotedMessageId != null) ...[
              _QuotePreview(text: message.quotedText ?? '', isOutgoing: message.isOutgoing),
              const SizedBox(height: 4),
            ],
            _MessageContent(message: message, textColor: textColor),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeago.format(message.timestamp, locale: 'en_short'),
                style: OmegaTextStyles.labelSmall.copyWith(
                  color: message.isOutgoing
                      ? Colors.white.withOpacity(0.7)
                      : OmegaColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final Message message;
  final Color textColor;

  const _MessageContent({required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: OmegaTextStyles.bodyMedium.copyWith(color: textColor),
        );
      case MessageType.image:
        return _MediaPreview(
          filePath: message.filePath,
          type: MessageType.image,
          caption: message.text,
        );
      case MessageType.video:
        return _MediaPreview(
          filePath: message.filePath,
          type: MessageType.video,
          caption: message.text,
        );
      case MessageType.audio:
      case MessageType.voice:
        return _AudioMessage(message: message, textColor: textColor);
      case MessageType.file:
        return _FileMessage(message: message, textColor: textColor);
      default:
        return Text(message.text ?? '', style: OmegaTextStyles.bodyMedium.copyWith(color: textColor));
    }
  }
}

class _MediaPreview extends StatelessWidget {
  final String? filePath;
  final MessageType type;
  final String? caption;

  const _MediaPreview({this.filePath, required this.type, this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 180,
            width: double.infinity,
            color: OmegaColors.inputFill,
            child: Icon(
              type == MessageType.video ? Icons.play_circle_outline_rounded : Icons.image_outlined,
              size: 48,
              color: OmegaColors.textSecondary,
            ),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(caption!, style: OmegaTextStyles.bodySmall),
        ],
      ],
    );
  }
}

class _AudioMessage extends StatelessWidget {
  final Message message;
  final Color textColor;

  const _AudioMessage({required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_outline_rounded, color: textColor, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.durationMs != null
                    ? '${(message.durationMs! / 1000).toStringAsFixed(0)}s'
                    : 'Voice',
                style: OmegaTextStyles.labelSmall.copyWith(color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileMessage extends StatelessWidget {
  final Message message;
  final Color textColor;

  const _FileMessage({required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_outlined, color: textColor, size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'File',
                style: OmegaTextStyles.labelMedium.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
              if (message.fileBytes != null)
                Text(
                  _formatBytes(message.fileBytes!),
                  style: OmegaTextStyles.caption.copyWith(color: textColor.withOpacity(0.7)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

class _QuotePreview extends StatelessWidget {
  final String text;
  final bool isOutgoing;

  const _QuotePreview({required this.text, required this.isOutgoing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOutgoing
            ? Colors.white.withOpacity(0.15)
            : OmegaColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isOutgoing ? Colors.white : OmegaColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: OmegaTextStyles.bodySmall.copyWith(
          color: isOutgoing ? Colors.white.withOpacity(0.8) : OmegaColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageState state;

  const _StatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case MessageState.pending:
        return const Icon(Icons.access_time_rounded, size: 12, color: OmegaColors.messageSent);
      case MessageState.sent:
        return const Icon(Icons.check_rounded, size: 12, color: OmegaColors.messageSent);
      case MessageState.delivered:
        return const Icon(Icons.done_all_rounded, size: 12, color: OmegaColors.messageDelivered);
      case MessageState.read:
        return const Icon(Icons.done_all_rounded, size: 12, color: OmegaColors.messageRead);
      case MessageState.failed:
        return const Icon(Icons.error_outline_rounded, size: 12, color: OmegaColors.messageFailed);
    }
  }
}

class _MessageOptions extends StatelessWidget {
  final Message message;

  const _MessageOptions({required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('Reply'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.text ?? ''));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward_rounded),
            title: const Text('Forward'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_border_rounded),
            title: const Text('Star'),
            onTap: () => Navigator.pop(context),
          ),
          if (message.isOutgoing)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: OmegaColors.error),
              title: const Text('Delete', style: TextStyle(color: OmegaColors.error)),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}
