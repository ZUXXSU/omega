class AppConstants {
  static const String appName = 'Omega';
  static const String appPackage = 'com.omega.messenger';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyAccountConfigured = 'account_configured';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyAutoDeleteTimer = 'auto_delete_timer';
  static const String keyReadReceipts = 'read_receipts';
  static const String keyLastSyncTime = 'last_sync_time';

  // Message types
  static const int msgTypeText = 10;
  static const int msgTypeImage = 20;
  static const int msgTypeVideo = 21;
  static const int msgTypeAudio = 40;
  static const int msgTypeVoice = 41;
  static const int msgTypeFile = 60;
  static const int msgTypeGif = 23;
  static const int msgTypeSticker = 23;
  static const int msgTypeLocation = 80;
  static const int msgTypeWebRtcOffer = 111;
  static const int msgTypeWebRtcAnswer = 112;

  // Chat types
  static const int chatTypeSingle = 100;
  static const int chatTypeGroup = 120;
  static const int chatTypeBroadcast = 160;

  // Message states
  static const int msgStatePending = 0;
  static const int msgStateSent = 1;
  static const int msgStateDelivered = 2;
  static const int msgStateRead = 3;
  static const int msgStateFailed = 4;

  // Pagination
  static const int msgPageSize = 50;
  static const int chatPageSize = 30;
  static const int contactPageSize = 50;

  // Media limits
  static const int maxFileSizeMb = 100;
  static const int maxImageSizeMb = 25;
  static const int maxVideoLengthSeconds = 300;
  static const int voiceMessageMaxSeconds = 300;

  // UI
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 20.0;
  static const double avatarSizeSmall = 36.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 72.0;
  static const double avatarSizeXL = 96.0;
}
