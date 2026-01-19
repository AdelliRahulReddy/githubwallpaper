import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme.dart';
import 'core/preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await AppPreferences.init();
    // TODO: Implement background wallpaper update logic
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  await AppPreferences.init();

  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: AppPreferences.getDarkMode()
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: AppPreferences.getDarkMode()
          ? Color(0xFF0D1117)
          : Colors.white,
      systemNavigationBarIconBrightness: AppPreferences.getDarkMode()
          ? Brightness.light
          : Brightness.dark,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppPreferences.getDarkMode();

    return MaterialApp(
      title: 'GitHub Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _getInitialScreen(),
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
