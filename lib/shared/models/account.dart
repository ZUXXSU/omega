import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required int id,
    required String email,
    required String displayName,
    String? profileImagePath,
    String? statusMessage,
    @Default(false) bool isConfigured,
    @Default(false) bool isFresh,
    String? serverAddress,
    int? serverPort,
    String? inboxFolder,
    @Default(true) bool mvboxEnabled,
    @Default(true) bool sentboxWatch,
    @Default(true) bool inboxWatch,
    @Default(false) bool bccSelf,
    String? signature,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}
