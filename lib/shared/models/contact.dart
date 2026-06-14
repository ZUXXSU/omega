import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

@freezed
class Contact with _$Contact {
  const factory Contact({
    required int id,
    required String email,
    required String displayName,
    String? authName,
    String? profileImagePath,
    String? statusMessage,
    @Default(false) bool isVerified,
    @Default(false) bool isBlocked,
    @Default(false) bool isBot,
    @Default(false) bool isSelf,
    @Default(false) bool isDeleted,
    String? color,
    DateTime? lastSeen,
    @Default(false) bool isOnline,
    @Default(0) int mutualChatId,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
}
