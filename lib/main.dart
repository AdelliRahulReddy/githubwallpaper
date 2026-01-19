import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/preferences.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/github_api.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Background task started: $task');

      await AppPreferences.init();

      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || token == null) {
        print('❌ Credentials not found');
        return Future.value(false);
      }

      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      print('✅ Wallpaper data updated successfully');
      return Future.value(true);
    } catch (e) {
      print('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await AppPreferences.init();

  // Initialize WorkManager for auto-updates
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register periodic task (4 hours)
  await Workmanager().registerPeriodicTask(
    AppConstants.wallpaperTaskName,
    AppConstants.wallpaperTaskTag,
    frequency: AppConstants.updateInterval,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const GitHubWallpaperApp());
}

class GitHubWallpaperApp extends StatefulWidget {
  const GitHubWallpaperApp({Key? key}) : super(key: key);

  @override
  State<GitHubWallpaperApp> createState() => _GitHubWallpaperAppState();
}

class _GitHubWallpaperAppState extends State<GitHubWallpaperApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final isDarkMode = AppPreferences.getDarkMode();
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void updateThemeMode(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Wallpaper',
      debugShowCheckedModeBanner: false,

      // Use our universal theme system
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: _themeMode,

      // Navigation
      home: const AppNavigator(),

      // Global builder for theme updates
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                1.0, // Prevent system font scaling from breaking layout
          ),
          child: child!,
        );
      },
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(context, snapshot.error.toString());
        }

        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }

  Future<Widget> _determineInitialScreen() async {
    // Add small delay for smooth startup
    await Future.delayed(Duration(milliseconds: 300));

    // Check if user has completed onboarding
    final username = AppPreferences.getUsername();
    final hasOnboarded = username != null && username.isNotEmpty;

    // Check if user has cached data
    final hasCachedData = AppPreferences.getCachedData() != null;

    // Navigation logic:
    // 1. No username -> Onboarding
    // 2. Username but no data -> Setup
    // 3. Has data -> Dashboard

    if (!hasOnboarded) {
      return const OnboardingScreen();
    } else if (!hasCachedData) {
      return const SetupScreen();
    } else {
      return const DashboardScreen();
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: context.primaryColor,
            ),
            SizedBox(height: AppTheme.spacing24),
            CircularProgressIndicator(color: context.primaryColor),
            SizedBox(height: AppTheme.spacing16),
            Text('GitHub Wallpaper', style: context.textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: context.screenPadding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.colorScheme.error,
                ),
                SizedBox(height: AppTheme.spacing24),
                Text(
                  'Oops! Something went wrong',
                  style: context.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacing12),
                Text(
                  error,
                  style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacing32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart app
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GitHubWallpaperApp(),
                      ),
                    );
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
