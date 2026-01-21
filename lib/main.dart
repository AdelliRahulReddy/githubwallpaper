import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme.dart';
import 'core/preferences.dart';
import 'core/wallpaper_service.dart';
import 'core/constants.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';

/// Global key to restart app when theme changes
final GlobalKey<_MyAppState> appKey = GlobalKey<_MyAppState>();

/// ✅ Background task callback - runs ONCE PER DAY (24 hours)
/// This is called by WorkManager when the scheduled task executes
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Background wallpaper update started');
    debugPrint('Task: $task');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // ✅ Initialize preferences in background context
      await AppPreferences.init();
      debugPrint('✓ Preferences initialized');

      // ✅ Get user's wallpaper target preference
      final target = AppPreferences.getWallpaperTarget();
      debugPrint('✓ Wallpaper target: $target');

      // ✅ Fetch latest data and set wallpaper
      final success = await WallpaperService.refreshAndSetWallpaper(
        target: target,
      );

      if (success) {
        debugPrint('✓ Background wallpaper update completed successfully');
        return Future.value(true);
      } else {
        debugPrint(
          '✗ Wallpaper update returned false (might have skipped - already updated today)',
        );
        return Future.value(true); // Still return true (not an error)
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Background wallpaper update failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('App starting...');

  // ✅ Initialize preferences first
  await AppPreferences.init();
  debugPrint('✓ Preferences initialized');

  // ✅ Initialize WorkManager for background updates
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to true during development for logs
  );
  debugPrint('✓ WorkManager initialized');

  // ✅ FIXED: Register periodic background task using CONSTANTS (24 hours)
  await Workmanager().registerPeriodicTask(
    AppConstants.wallpaperTaskName, // ✅ Use constant
    AppConstants.wallpaperTaskTag, // ✅ Use constant
    frequency: AppConstants.updateInterval, // ✅ FIXED: 24 hours from constants
    existingWorkPolicy:
        ExistingPeriodicWorkPolicy.replace, // ✅ FIXED: replace allows updates
    constraints: Constraints(
      networkType: NetworkType.connected, // Requires internet
      requiresBatteryNotLow: true, // ✅ NEW: Don't run on low battery
      requiresStorageNotLow: true, // ✅ NEW: Don't run on low storage
    ),
    backoffPolicy: BackoffPolicy.exponential, // ✅ NEW: Smart retry on failure
    backoffPolicyDelay: const Duration(
      minutes: 15,
    ), // ✅ NEW: Wait 15min before retry
  );
  debugPrint(
    '✓ WorkManager task registered (interval: ${AppConstants.updateInterval.inHours}h)',
  );

  // ✅ Set status bar style
  _setSystemUI();

  runApp(MyApp(key: appKey));
}

/// ✅ Configure system UI (status bar, navigation bar)
void _setSystemUI() {
  final isDarkMode = AppPreferences.getDarkMode();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDarkMode
          ? const Color(0xFF0D1117)
          : Colors.white,
      systemNavigationBarIconBrightness: isDarkMode
          ? Brightness.light
          : Brightness.dark,
    ),
  );
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
    _setSystemUI();
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

    // ✅ If user has completed setup and has cached data, go to main screen
    if (username != null &&
        username.isNotEmpty &&
        token != null &&
        token.isNotEmpty &&
        cachedData != null) {
      return const MainNavigation();
    }

    // ✅ Show onboarding for new users
    return const OnboardingScreen();
  }
}
