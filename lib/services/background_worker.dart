import 'package:workmanager/workmanager.dart';
import '../utils/constants.dart';
import '../storage/preferences.dart';
import '../storage/cache_manager.dart';
import 'wallpaper_service.dart';

// Top-level callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('📱 Background task started: $task');

      // Initialize storage
      await AppPreferences.init();
      await CacheManager.init();

      // Update wallpaper
      final result = await WallpaperService.updateWallpaper();
      print('✅ $result');

      return Future.value(true);
    } catch (e) {
      print('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundWorker {
  // Initialize and register periodic task
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set true for testing
    );

    await registerPeriodicUpdate();
  }

  // Register 4-hour periodic update
  static Future<void> registerPeriodicUpdate() async {
    await Workmanager().registerPeriodicTask(
      AppConstants.wallpaperTaskName,
      AppConstants.wallpaperTaskTag,
      frequency: AppConstants.updateInterval,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,

      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: Duration(minutes: 15),
    );

    print('🔔 Periodic wallpaper update registered (every 4 hours)');
  }

  // Trigger immediate one-time update
  static Future<void> triggerImmediateUpdate() async {
    await Workmanager().registerOneOffTask(
      'immediate-update',
      AppConstants.wallpaperTaskTag,
      initialDelay: Duration(seconds: 5),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    print('🚀 Immediate update scheduled');
  }

  // Cancel all tasks
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('🛑 All background tasks cancelled');
  }

  // Cancel periodic update only
  static Future<void> cancelPeriodicUpdate() async {
    await Workmanager().cancelByUniqueName(AppConstants.wallpaperTaskName);
    print('🛑 Periodic update cancelled');
  }
}
