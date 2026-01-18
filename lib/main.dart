import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage/preferences.dart';
import 'storage/cache_manager.dart';
import 'services/background_worker.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await AppPreferences.init();
  await CacheManager.init();

  // Initialize background worker for auto-updates
  await BackgroundWorker.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const GitHubWallpaperApp());
}

class GitHubWallpaperApp extends StatelessWidget {
  const GitHubWallpaperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'SF Pro Display'),
      home: const HomeScreen(),
    );
  }
}
