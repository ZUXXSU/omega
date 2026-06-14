import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../core/utils/logger.dart';

part 'settings_provider.g.dart';

@immutable
class AppSettings {
  final bool chatNotifications;
  final bool groupNotifications;
  final bool sound;
  final bool vibration;
  final bool messagePreview;
  final bool badge;
  final bool readReceipts;
  final bool typingIndicators;
  final String lastSeen;
  final bool biometricLock;
  final bool screenSecurity;
  final bool mvboxEnabled;
  final bool sentboxWatch;
  final bool bccSelf;
  final bool showClassicEmails;
  final bool onlyFetchDcMsgs;
  final int downloadLimitBytes;
  final int autoDeleteDeviceDays;
  final int autoDeleteServerDays;
  final bool isDarkMode;

  const AppSettings({
    this.chatNotifications = true,
    this.groupNotifications = true,
    this.sound = true,
    this.vibration = true,
    this.messagePreview = true,
    this.badge = true,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.lastSeen = 'Everyone',
    this.biometricLock = false,
    this.screenSecurity = false,
    this.mvboxEnabled = true,
    this.sentboxWatch = true,
    this.bccSelf = false,
    this.showClassicEmails = false,
    this.onlyFetchDcMsgs = false,
    this.downloadLimitBytes = 26214400,
    this.autoDeleteDeviceDays = 0,
    this.autoDeleteServerDays = 0,
    this.isDarkMode = false,
  });

  AppSettings copyWith({
    bool? chatNotifications,
    bool? groupNotifications,
    bool? sound,
    bool? vibration,
    bool? messagePreview,
    bool? badge,
    bool? readReceipts,
    bool? typingIndicators,
    String? lastSeen,
    bool? biometricLock,
    bool? screenSecurity,
    bool? mvboxEnabled,
    bool? sentboxWatch,
    bool? bccSelf,
    bool? showClassicEmails,
    bool? onlyFetchDcMsgs,
    int? downloadLimitBytes,
    int? autoDeleteDeviceDays,
    int? autoDeleteServerDays,
    bool? isDarkMode,
  }) =>
      AppSettings(
        chatNotifications: chatNotifications ?? this.chatNotifications,
        groupNotifications: groupNotifications ?? this.groupNotifications,
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
        messagePreview: messagePreview ?? this.messagePreview,
        badge: badge ?? this.badge,
        readReceipts: readReceipts ?? this.readReceipts,
        typingIndicators: typingIndicators ?? this.typingIndicators,
        lastSeen: lastSeen ?? this.lastSeen,
        biometricLock: biometricLock ?? this.biometricLock,
        screenSecurity: screenSecurity ?? this.screenSecurity,
        mvboxEnabled: mvboxEnabled ?? this.mvboxEnabled,
        sentboxWatch: sentboxWatch ?? this.sentboxWatch,
        bccSelf: bccSelf ?? this.bccSelf,
        showClassicEmails: showClassicEmails ?? this.showClassicEmails,
        onlyFetchDcMsgs: onlyFetchDcMsgs ?? this.onlyFetchDcMsgs,
        downloadLimitBytes: downloadLimitBytes ?? this.downloadLimitBytes,
        autoDeleteDeviceDays: autoDeleteDeviceDays ?? this.autoDeleteDeviceDays,
        autoDeleteServerDays: autoDeleteServerDays ?? this.autoDeleteServerDays,
        isDarkMode: isDarkMode ?? this.isDarkMode,
      );
}

@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final config = await rpc.getConfig(1);
      state = AppSettings(
        mvboxEnabled: config['mvbox_enabled'] as bool? ?? true,
        sentboxWatch: config['sentbox_watch'] as bool? ?? true,
        bccSelf: config['bcc_self'] as bool? ?? false,
        showClassicEmails: (config['show_emails'] as int? ?? 0) != 0,
        downloadLimitBytes: config['download_limit'] as int? ?? 26214400,
        readReceipts: config['read_receipts'] as bool? ?? true,
        autoDeleteDeviceDays: config['auto_delete_device_days'] as int? ?? 0,
        autoDeleteServerDays: config['auto_delete_server_days'] as int? ?? 0,
        // Local prefs
        chatNotifications: StorageService.getBool('chat_notifications', defaultValue: true),
        sound: StorageService.getBool('sound', defaultValue: true),
        vibration: StorageService.getBool('vibration', defaultValue: true),
        biometricLock: StorageService.getBool('biometric_lock'),
        screenSecurity: StorageService.getBool('screen_security'),
      );
    } catch (e, st) {
      AppLogger.e('Settings load failed', e, st);
    }
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      await rpc.setConfig(1, 'mvbox_enabled', updated.mvboxEnabled);
      await rpc.setConfig(1, 'sentbox_watch', updated.sentboxWatch);
      await rpc.setConfig(1, 'bcc_self', updated.bccSelf);
      await rpc.setConfig(1, 'read_receipts', updated.readReceipts);
      await rpc.setConfig(1, 'download_limit', updated.downloadLimitBytes);
      await rpc.setConfig(1, 'auto_delete_device_days', updated.autoDeleteDeviceDays);
      await rpc.setConfig(1, 'auto_delete_server_days', updated.autoDeleteServerDays);

      await StorageService.setBool('chat_notifications', updated.chatNotifications);
      await StorageService.setBool('sound', updated.sound);
      await StorageService.setBool('vibration', updated.vibration);
      await StorageService.setBool('biometric_lock', updated.biometricLock);
      await StorageService.setBool('screen_security', updated.screenSecurity);
    } catch (e) {
      AppLogger.e('Settings save failed', e);
    }
  }

  Future<void> toggle(String key) async {
    final updated = switch (key) {
      'chatNotifications' => state.copyWith(chatNotifications: !state.chatNotifications),
      'groupNotifications' => state.copyWith(groupNotifications: !state.groupNotifications),
      'sound' => state.copyWith(sound: !state.sound),
      'vibration' => state.copyWith(vibration: !state.vibration),
      'messagePreview' => state.copyWith(messagePreview: !state.messagePreview),
      'badge' => state.copyWith(badge: !state.badge),
      'readReceipts' => state.copyWith(readReceipts: !state.readReceipts),
      'typingIndicators' => state.copyWith(typingIndicators: !state.typingIndicators),
      'biometricLock' => state.copyWith(biometricLock: !state.biometricLock),
      'screenSecurity' => state.copyWith(screenSecurity: !state.screenSecurity),
      'mvboxEnabled' => state.copyWith(mvboxEnabled: !state.mvboxEnabled),
      'sentboxWatch' => state.copyWith(sentboxWatch: !state.sentboxWatch),
      'bccSelf' => state.copyWith(bccSelf: !state.bccSelf),
      'showClassicEmails' => state.copyWith(showClassicEmails: !state.showClassicEmails),
      'onlyFetchDcMsgs' => state.copyWith(onlyFetchDcMsgs: !state.onlyFetchDcMsgs),
      _ => state,
    };
    await update(updated);
  }
}
