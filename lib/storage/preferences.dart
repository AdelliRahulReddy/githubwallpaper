import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contribution_data.dart';
import '../utils/constants.dart';

class AppPreferences {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure initialized
  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('AppPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // GitHub Credentials
  static Future<void> setUsername(String username) async {
    await _instance.setString(AppConstants.keyUsername, username);
  }

  static String? getUsername() {
    return _instance.getString(AppConstants.keyUsername);
  }

  static Future<void> setToken(String token) async {
    await _instance.setString(AppConstants.keyToken, token);
  }

  static String? getToken() {
    return _instance.getString(AppConstants.keyToken);
  }

  // UI Settings
  static Future<void> setDarkMode(bool isDark) async {
    await _instance.setBool(AppConstants.keyDarkMode, isDark);
  }

  static bool getDarkMode() {
    return _instance.getBool(AppConstants.keyDarkMode) ?? false;
  }

  static Future<void> setVerticalPosition(double position) async {
    await _instance.setDouble(AppConstants.keyVerticalPos, position);
  }

  static double getVerticalPosition() {
    return _instance.getDouble(AppConstants.keyVerticalPos) ??
        AppConstants.defaultVerticalPosition;
  }

  static Future<void> setHorizontalPosition(double position) async {
    await _instance.setDouble(AppConstants.keyHorizontalPos, position);
  }

  static double getHorizontalPosition() {
    return _instance.getDouble(AppConstants.keyHorizontalPos) ??
        AppConstants.defaultHorizontalPosition;
  }

  static Future<void> setScale(double scale) async {
    await _instance.setDouble(AppConstants.keyScale, scale);
  }

  static double getScale() {
    return _instance.getDouble(AppConstants.keyScale) ??
        AppConstants.defaultScale;
  }

  static Future<void> setCustomQuote(String quote) async {
    await _instance.setString(AppConstants.keyCustomQuote, quote);
  }

  static String getCustomQuote() {
    return _instance.getString(AppConstants.keyCustomQuote) ?? '';
  }

  // Last Update Timestamp
  static Future<void> setLastUpdate(DateTime dateTime) async {
    await _instance.setString(
      AppConstants.keyLastUpdate,
      dateTime.toIso8601String(),
    );
  }

  static DateTime? getLastUpdate() {
    final dateString = _instance.getString(AppConstants.keyLastUpdate);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  // Reset to defaults
  static Future<void> resetSettings() async {
    await setDarkMode(false);
    await setVerticalPosition(AppConstants.defaultVerticalPosition);
    await setHorizontalPosition(AppConstants.defaultHorizontalPosition);
    await setScale(AppConstants.defaultScale);
    await setCustomQuote('');
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _instance.clear();
  }
}
