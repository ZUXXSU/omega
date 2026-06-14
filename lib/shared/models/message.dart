import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageState { pending, sent, delivered, read, failed }

enum MessageType {
  text,
  image,
  video,
  audio,
  voice,
  file,
  gif,
  sticker,
  location,
  systemInfo,
  webrtcOffer,
  webrtcAnswer,
}

@freezed
class Message with _$Message {
  const factory Message({
    required int id,
    required int chatId,
    required int fromContactId,
    required MessageType type,
    @Default(MessageState.pending) MessageState state,
    String? text,
    String? htmlText,
    String? filePath,
    String? fileMimeType,
    String? fileName,
    int? fileBytes,
    int? durationMs,
    double? latitude,
    double? longitude,
    required DateTime timestamp,
    DateTime? receivedAt,
    @Default(false) bool isOutgoing,
    @Default(false) bool isForwarded,
    @Default(false) bool isInfo,
    @Default(false) bool hasLocation,
    @Default(false) bool isSealed,
    @Default(false) bool isBot,
    int? quotedMessageId,
    String? quotedText,
    int? quotedContactId,
    @Default([]) List<int> reactionContactIds,
    Map<String, int>? reactionCounts,
    String? subject,
    String? overrideSenderName,
    @Default(false) bool showPadlock,
    @Default(false) bool hasDeliveryReports,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
