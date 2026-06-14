import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage
  static Future<void> writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      AppLogger.e('SecureStorage write error', e);
    }
  }

  static Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      AppLogger.e('SecureStorage read error', e);
      return null;
    }
  }

  static Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      AppLogger.e('SecureStorage delete error', e);
    }
  }

  static Future<void> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      AppLogger.e('SecureStorage clearAll error', e);
    }
  }

  // Preferences
  static Future<void> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  static Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  static String? getString(String key) => _prefs.getString(key);

  static Future<void> setInt(String key, int value) async =>
      _prefs.setInt(key, value);

  static int? getInt(String key) => _prefs.getInt(key);

  static Future<void> remove(String key) async => _prefs.remove(key);

  static Future<void> clear() async => _prefs.clear();

  // Typed helpers
  static bool get isOnboardingComplete =>
      getBool(AppConstants.keyOnboardingComplete);

  static Future<void> setOnboardingComplete() =>
      setBool(AppConstants.keyOnboardingComplete, true);

  static bool get isAccountConfigured =>
      getBool(AppConstants.keyAccountConfigured);

  static Future<void> setAccountConfigured() =>
      setBool(AppConstants.keyAccountConfigured, true);
}
