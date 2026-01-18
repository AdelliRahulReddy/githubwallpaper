import 'package:flutter/material.dart';

class AppConstants {
  // GitHub API
  static const String githubApiUrl = 'https://api.github.com/graphql';
  static const Duration apiTimeout = Duration(seconds: 60);

  // GitHub Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFC9D1D9);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkAccent = Color(0xFF58A6FF);
  static const Color darkSuccess = Color(0xFF238636);

  // GitHub Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F8FA);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightTextPrimary = Color(0xFF24292F);
  static const Color lightTextSecondary = Color(0xFF57606A);
  static const Color lightAccent = Color(0xFF0969DA);
  static const Color lightSuccess = Color(0xFF2DA44E);

  // Contribution Colors (GitHub Green Scale)
  static const Color level0 = Color(0xFF161B22); // Dark: empty
  static const Color level1 = Color(0xFF0E4429);
  static const Color level2 = Color(0xFF006D32);
  static const Color level3 = Color(0xFF26A641);
  static const Color level4 = Color(0xFF39D353);

  static const Color level0Light = Color(0xFFEBEDF0); // Light: empty
  static const Color level1Light = Color(0xFF9BE9A8);
  static const Color level2Light = Color(0xFF40C463);
  static const Color level3Light = Color(0xFF30A14E);
  static const Color level4Light = Color(0xFF216E39);

  // Today highlight
  static const Color todayHighlight = Color(0xFFFF9500); // Orange glow

  // Heatmap Settings
  static const double boxSize = 12.0;
  static const double boxSpacing = 3.0;
  static const double boxRadius = 2.0;
  static const double todayBorderWidth = 2.0;

  // Default Positions
  static const double defaultVerticalPosition = 0.36;
  static const double defaultHorizontalPosition = 0.5;
  static const double defaultScale = 1.0;

  // Slider Ranges
  static const double minVerticalPos = 0.2;
  static const double maxVerticalPos = 0.7;
  static const double minScale = 0.7;
  static const double maxScale = 1.3;

  // WorkManager
  static const String wallpaperTaskName = 'github-wallpaper-update';
  static const String wallpaperTaskTag = 'updateGitHubWallpaper';
  static const Duration updateInterval = Duration(hours: 4);

  // Storage Keys
  static const String keyUsername = 'github_username';
  static const String keyToken = 'github_token';
  static const String keyDarkMode = 'isDarkMode';
  static const String keyVerticalPos = 'verticalPosition';
  static const String keyHorizontalPos = 'horizontalPosition';
  static const String keyScale = 'scale';
  static const String keyCustomQuote = 'customQuote';
  static const String keyCachedData = 'cachedData';
  static const String keyLastUpdate = 'lastUpdate';

  // Wallpaper Settings
  static const int wallpaperWidth = 1080;
  static const int wallpaperHeight = 2400;
}
