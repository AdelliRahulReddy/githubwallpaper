import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contribution_data.dart';
import '../utils/constants.dart';

class CacheManager {
  static SharedPreferences? _prefs;

  // Initialize
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('CacheManager not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Save contribution data
  static Future<void> saveCachedData(CachedContributionData data) async {
    final jsonString = jsonEncode(data.toJson());
    await _instance.setString(AppConstants.keyCachedData, jsonString);
  }

  // Load contribution data
  static CachedContributionData? getCachedData() {
    final jsonString = _instance.getString(AppConstants.keyCachedData);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return CachedContributionData.fromJson(jsonMap);
    } catch (e) {
      print('Error parsing cached data: $e');
      return null;
    }
  }

  // Check if cache is valid (less than 4 hours old)
  static bool isCacheValid() {
    final cachedData = getCachedData();

    if (cachedData == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(cachedData.lastUpdated);

    return difference < AppConstants.updateInterval;
  }

  // Check if cache is from current month
  static bool isCacheCurrentMonth() {
    final cachedData = getCachedData();

    if (cachedData == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheDate = cachedData.lastUpdated;

    return now.year == cacheDate.year && now.month == cacheDate.month;
  }

  // Get cache age in minutes
  static int getCacheAgeMinutes() {
    final cachedData = getCachedData();

    if (cachedData == null) {
      return -1;
    }

    final now = DateTime.now();
    final difference = now.difference(cachedData.lastUpdated);

    return difference.inMinutes;
  }

  // Clear cache
  static Future<void> clearCache() async {
    await _instance.remove(AppConstants.keyCachedData);
  }
}
