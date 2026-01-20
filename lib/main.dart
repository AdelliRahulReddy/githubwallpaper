import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme.dart';
import 'core/preferences.dart';
import 'core/wallpaper_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';

/// Global key to restart app when theme changes
final GlobalKey<_MyAppState> appKey = GlobalKey<_MyAppState>();

/// Background task callback - runs every 2-4 hours
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize preferences in background
      await AppPreferences.init();

      // Fetch latest data and set wallpaper automatically
      final target = AppPreferences.getWallpaperTarget();
      await WallpaperService.refreshAndSetWallpaper(target: target);

      print('Background wallpaper update completed successfully');
      return Future.value(true);
    } catch (e) {
      print('Background wallpaper update failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  await AppPreferences.init();

  // Initialize Workmanager for background updates
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic background task (every 4 hours by default)
  await Workmanager().registerPeriodicTask(
    'github-wallpaper-update',
    'updateGitHubWallpaper',
    frequency: Duration(hours: 4),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(MyApp(key: appKey));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
  
  /// Call this to rebuild the entire app (e.g., after theme change)
  static void restartApp(BuildContext context) {
    appKey.currentState?.restartApp();
  }
}

class _MyAppState extends State<MyApp> {
  Key _appKey = UniqueKey();

  void restartApp() {
    setState(() {
      _appKey = UniqueKey();
      _updateSystemUI();
    });
  }

  void _updateSystemUI() {
    final isDarkMode = AppPreferences.getDarkMode();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? Color(0xFF0D1117) : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppPreferences.getDarkMode();

    return KeyedSubtree(
      key: _appKey,
      child: MaterialApp(
        title: 'GitHub Wallpaper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: _getInitialScreen(),
      ),
    );
  }

  Widget _getInitialScreen() {
    final username = AppPreferences.getUsername();
    final token = AppPreferences.getToken();
    final cachedData = AppPreferences.getCachedData();

    // If user has completed setup and has cached data
    if (username != null && token != null && cachedData != null) {
      return MainNavigation();
    }

    // Show onboarding for new users
    return OnboardingScreen();
  }
}
