package com.rahulreddy.githubwallpaper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Plugins are automatically registered by the Flutter engine.
        // The WallpaperPlugin will handle the "github_wallpaper/wallpaper" channel.
    }
}
