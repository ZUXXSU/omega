import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';
part 'chat.g.dart';

enum ChatType { single, group, broadcast, mailingList }

enum ChatVisibility { normal, archived, pinned }

@freezed
class Chat with _$Chat {
  const factory Chat({
    required int id,
    required String name,
    required ChatType type,
    @Default(ChatVisibility.normal) ChatVisibility visibility,
    String? profileImagePath,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int unreadCount,
    @Default(false) bool isMuted,
    @Default(false) bool isVerified,
    @Default(false) bool isSelfTalk,
    @Default(false) bool isDeviceTalk,
    @Default(false) bool isProtected,
    int? selfContactId,
    @Default([]) List<int> memberIds,
    DateTime? ephemeralTimer,
    String? color,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
}
