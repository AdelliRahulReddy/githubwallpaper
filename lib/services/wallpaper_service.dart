import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../models/contribution_data.dart';
import '../storage/preferences.dart';
import '../storage/cache_manager.dart';
import '../api/github_api.dart';
import '../api/github_repository.dart';
import '../ui/widgets/heatmap_painter.dart';
import '../utils/constants.dart';

class WallpaperService {
  // Generate and set wallpaper
  static Future<String> updateWallpaper() async {
    try {
      // Load credentials
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || token == null) {
        throw Exception('GitHub credentials not found');
      }

      // Fetch latest data
      final api = GitHubAPI(token: token);
      final repository = GitHubRepository(api: api);
      final data = await repository.getContributions(username);

      // Save to cache
      await CacheManager.saveCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      // Generate wallpaper image
      final file = await _generateWallpaperImage(data);

      // Set as wallpaper
      await AsyncWallpaper.setWallpaperFromFile(
        filePath: file.path,
        wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
      );

      return 'Wallpaper updated successfully!';
    } catch (e) {
      throw Exception('Failed to update wallpaper: ${e.toString()}');
    }
  }

  // Generate wallpaper image from data
  static Future<File> _generateWallpaperImage(
    CachedContributionData data,
  ) async {
    // Load user preferences
    final isDarkMode = AppPreferences.getDarkMode();
    final verticalPos = AppPreferences.getVerticalPosition();
    final horizontalPos = AppPreferences.getHorizontalPosition();
    final scale = AppPreferences.getScale();
    final customQuote = AppPreferences.getCustomQuote();

    final size = Size(
      AppConstants.wallpaperWidth.toDouble(),
      AppConstants.wallpaperHeight.toDouble(),
    );

    // Create picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    final bgPaint = Paint()
      ..color = isDarkMode
          ? AppConstants.darkBackground
          : AppConstants.lightBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw heatmap using painter
    final painter = HeatmapPainter(
      data: data,
      isDarkMode: isDarkMode,
      verticalPosition: verticalPos,
      horizontalPosition: horizontalPos,
      scale: scale,
      customQuote: customQuote,
    );

    painter.paint(canvas, size);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/github_wallpaper_$timestamp.png');
    await file.writeAsBytes(pngBytes);

    // Clean up old wallpaper files
    await _cleanupOldFiles(directory);

    return file;
  }

  // Clean up old wallpaper files (keep only last 3)
  static Future<void> _cleanupOldFiles(Directory directory) async {
    try {
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('github_wallpaper_'))
          .toList();

      if (files.length > 3) {
        // Sort by modification time
        files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
        );

        // Delete oldest files
        for (var i = 0; i < files.length - 3; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }
}
