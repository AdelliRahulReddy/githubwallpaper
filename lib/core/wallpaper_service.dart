import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../models/contribution_data.dart';
import '../widgets/heatmap_painter.dart';
import 'constants.dart';
import 'preferences.dart';
import 'github_api.dart';

/// Service to handle wallpaper generation and setting
class WallpaperService {
  /// Fetches latest data, generates wallpaper, and sets it
  static Future<bool> refreshAndSetWallpaper({
    String target = 'both',
    bool showNotification = false,
  }) async {
    try {
      // Get credentials
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials not found');
      }

      // Fetch latest data from GitHub
      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      // Save to cache
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      // Generate and set wallpaper
      await generateAndSetWallpaper(data, target: target);

      return true;
    } catch (e) {
      print('WallpaperService error: $e');
      return false;
    }
  }

  /// Generates wallpaper image from cached data and sets it
  static Future<void> generateAndSetWallpaper(
    CachedContributionData data, {
    String target = 'both',
  }) async {
    final isDarkMode = AppPreferences.getDarkMode();

    final size = Size(
      AppConstants.wallpaperWidth.toDouble(),
      AppConstants.wallpaperHeight.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    final bgPaint = Paint()
      ..color = isDarkMode
          ? AppConstants.darkBackground
          : AppConstants.lightBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw heatmap
    final painter = HeatmapPainter(
      data: data,
      isDarkMode: isDarkMode,
      verticalPosition: AppPreferences.getVerticalPosition(),
      horizontalPosition: AppPreferences.getHorizontalPosition(),
      scale: AppPreferences.getScale(),
      opacity: AppPreferences.getOpacity(),
      customQuote: AppPreferences.getCustomQuote(),
      paddingTop: AppPreferences.getPaddingTop(),
      paddingBottom: AppPreferences.getPaddingBottom(),
      paddingLeft: AppPreferences.getPaddingLeft(),
      paddingRight: AppPreferences.getPaddingRight(),
      cornerRadius: AppPreferences.getCornerRadius(),
      quoteFontSize: AppPreferences.getQuoteFontSize(),
      quoteOpacity: AppPreferences.getQuoteOpacity(),
    );

    painter.paint(canvas, size);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Clean up old wallpaper files first
    await _cleanupOldWallpapers();

    // Save new wallpaper
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/github_wallpaper.png');
    await file.writeAsBytes(pngBytes);

    // Set wallpaper
    int location;
    switch (target) {
      case 'lock':
        location = AsyncWallpaper.LOCK_SCREEN;
        break;
      case 'home':
        location = AsyncWallpaper.HOME_SCREEN;
        break;
      case 'both':
      default:
        location = AsyncWallpaper.BOTH_SCREENS;
    }

    await AsyncWallpaper.setWallpaperFromFile(
      filePath: file.path,
      wallpaperLocation: location,
    );
  }

  /// Delete old wallpaper files to save storage
  static Future<void> _cleanupOldWallpapers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      for (var file in files) {
        if (file is File && file.path.contains('github_wallpaper')) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
