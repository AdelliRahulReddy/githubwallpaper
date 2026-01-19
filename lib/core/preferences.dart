import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/contribution_data.dart';
import 'constants.dart';

class AppPreferences {
  static const String _keyUsername = 'github_username';
  static const String _keyToken = 'github_token';
  static const String _keyCachedData = 'cached_data';
  static const String _keyLastUpdate = 'last_update';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyVerticalPosition = 'vertical_position';
  static const String _keyHorizontalPosition = 'horizontal_position';
  static const String _keyScale = 'scale';
  static const String _keyOpacity = 'opacity';
  static const String _keyCustomQuote = 'custom_quote';
  static const String _keyPaddingTop = 'padding_top';
  static const String _keyPaddingBottom = 'padding_bottom';
  static const String _keyPaddingLeft = 'padding_left';
  static const String _keyPaddingRight = 'padding_right';
  static const String _keyCornerRadius = 'corner_radius';
  static const String _keyQuoteFontSize = 'quote_font_size';
  static const String _keyQuoteOpacity = 'quote_opacity';
  static const String _keyWallpaperTarget = 'wallpaper_target';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('AppPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Username
  static Future<void> setUsername(String username) async {
    await prefs.setString(_keyUsername, username);
  }

  static String? getUsername() {
    return prefs.getString(_keyUsername);
  }

  // Token
  static Future<void> setToken(String token) async {
    await prefs.setString(_keyToken, token);
  }

  static String? getToken() {
    return prefs.getString(_keyToken);
  }

  // Cached Data
  static Future<void> setCachedData(CachedContributionData data) async {
    final json = jsonEncode(data.toJson());
    await prefs.setString(_keyCachedData, json);
  }

  static CachedContributionData? getCachedData() {
    final json = prefs.getString(_keyCachedData);
    if (json == null) return null;
    return CachedContributionData.fromJson(jsonDecode(json));
  }

  // Last Update
  static Future<void> setLastUpdate(DateTime dateTime) async {
    await prefs.setString(_keyLastUpdate, dateTime.toIso8601String());
  }

  static DateTime? getLastUpdate() {
    final str = prefs.getString(_keyLastUpdate);
    if (str == null) return null;
    return DateTime.parse(str);
  }

  // Dark Mode
  static Future<void> setDarkMode(bool enabled) async {
    await prefs.setBool(_keyDarkMode, enabled);
  }

  static bool getDarkMode() {
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Vertical Position
  static Future<void> setVerticalPosition(double value) async {
    await prefs.setDouble(_keyVerticalPosition, value);
  }

  static double getVerticalPosition() {
    return prefs.getDouble(_keyVerticalPosition) ??
        AppConstants.defaultVerticalPosition;
  }

  // Horizontal Position
  static Future<void> setHorizontalPosition(double value) async {
    await prefs.setDouble(_keyHorizontalPosition, value);
  }

  static double getHorizontalPosition() {
    return prefs.getDouble(_keyHorizontalPosition) ??
        AppConstants.defaultHorizontalPosition;
  }

  // Scale
  static Future<void> setScale(double value) async {
    await prefs.setDouble(_keyScale, value);
  }

  static double getScale() {
    return prefs.getDouble(_keyScale) ?? AppConstants.defaultScale;
  }

  // Opacity
  static Future<void> setOpacity(double value) async {
    await prefs.setDouble(_keyOpacity, value);
  }

  static double getOpacity() {
    return prefs.getDouble(_keyOpacity) ?? 1.0;
  }

  // Custom Quote
  static Future<void> setCustomQuote(String quote) async {
    await prefs.setString(_keyCustomQuote, quote);
  }

  static String getCustomQuote() {
    return prefs.getString(_keyCustomQuote) ?? '';
  }

  // Padding Top
  static Future<void> setPaddingTop(double value) async {
    await prefs.setDouble(_keyPaddingTop, value);
  }

  static double getPaddingTop() {
    return prefs.getDouble(_keyPaddingTop) ?? 0.0;
  }

  // Padding Bottom
  static Future<void> setPaddingBottom(double value) async {
    await prefs.setDouble(_keyPaddingBottom, value);
  }

  static double getPaddingBottom() {
    return prefs.getDouble(_keyPaddingBottom) ?? 0.0;
  }

  // Padding Left
  static Future<void> setPaddingLeft(double value) async {
    await prefs.setDouble(_keyPaddingLeft, value);
  }

  static double getPaddingLeft() {
    return prefs.getDouble(_keyPaddingLeft) ?? 0.0;
  }

  // Padding Right
  static Future<void> setPaddingRight(double value) async {
    await prefs.setDouble(_keyPaddingRight, value);
  }

  static double getPaddingRight() {
    return prefs.getDouble(_keyPaddingRight) ?? 0.0;
  }

  // Corner Radius
  static Future<void> setCornerRadius(double value) async {
    await prefs.setDouble(_keyCornerRadius, value);
  }

  static double getCornerRadius() {
    return prefs.getDouble(_keyCornerRadius) ?? 0.0;
  }

  // Quote Font Size
  static Future<void> setQuoteFontSize(double value) async {
    await prefs.setDouble(_keyQuoteFontSize, value);
  }

  static double getQuoteFontSize() {
    return prefs.getDouble(_keyQuoteFontSize) ?? 14.0;
  }

  // Quote Opacity
  static Future<void> setQuoteOpacity(double value) async {
    await prefs.setDouble(_keyQuoteOpacity, value);
  }

  static double getQuoteOpacity() {
    return prefs.getDouble(_keyQuoteOpacity) ?? 1.0;
  }

  // Wallpaper Target
  static Future<void> setWallpaperTarget(String target) async {
    await prefs.setString(_keyWallpaperTarget, target);
  }

  static String getWallpaperTarget() {
    return prefs.getString(_keyWallpaperTarget) ?? 'both';
  }

  // Clear All
  static Future<void> clearAll() async {
    await prefs.clear();
  }
}
