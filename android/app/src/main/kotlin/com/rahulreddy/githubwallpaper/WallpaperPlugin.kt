package com.rahulreddy.githubwallpaper

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.Activity

class WallpaperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private val TAG = "WallpaperPlugin"

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "github_wallpaper/wallpaper")
        channel.setMethodCallHandler(this)
        Log.d(TAG, "Plugin attached to engine (Context available)")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    // ActivityAware implementation to get the Activity context when in foreground
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        Log.d(TAG, "Plugin attached to activity (Higher permission context available)")
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setWallpaper" -> handleSetWallpaper(call, result)
            "getWallpaperDimensions" -> handleGetWallpaperDimensions(result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetWallpaperDimensions(result: MethodChannel.Result) {
        try {
            // Use Activity if available, else fallback to Application context
            val bestContext = activity ?: context
            if (bestContext == null) {
                result.error("CONTEXT_MISSING", "No context available", null)
                return
            }

            val manager = WallpaperManager.getInstance(bestContext)
            val width = manager.desiredMinimumWidth
            val height = manager.desiredMinimumHeight
            
            Log.d(TAG, "Plugin: Desired dimensions: ${width}x${height}")
            
            result.success(mapOf(
                "width" to width,
                "height" to height
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Plugin: Failed to get dimensions: ${e.message}")
            result.error("DIMENSION_ERROR", e.message, null)
        }
    }

    private fun handleSetWallpaper(call: MethodCall, result: MethodChannel.Result) {
        try {
            val path = call.argument<String>("path") ?: return result.error("INVALID_ARGUMENT", "Path is null", null)
            val target = call.argument<String>("target") ?: "both"

            val bestContext = activity ?: context
            if (bestContext == null) {
                result.error("CONTEXT_MISSING", "No context available to set wallpaper", null)
                return
            }

            Log.d(TAG, "Plugin: Set wallpaper (path=$path, target=$target)")

            // Load Bitmap
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
            }
            val bitmap = BitmapFactory.decodeFile(path, options) ?: return result.error("DECODE_ERROR", "Failed to decode", null)

            val manager = WallpaperManager.getInstance(bestContext)
            
            // Suggest dimensions
            try {
                manager.suggestDesiredDimensions(bitmap.width, bitmap.height)
            } catch (e: Exception) {
                Log.w(TAG, "Plugin: Suggest dimensions failed: ${e.message}")
            }

            val sdkVersion = android.os.Build.VERSION.SDK_INT
            
            when (target) {
                "home" -> {
                    if (sdkVersion >= android.os.Build.VERSION_CODES.N) {
                        manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                    } else {
                        manager.setBitmap(bitmap)
                    }
                }
                "lock" -> {
                    if (sdkVersion >= android.os.Build.VERSION_CODES.N) {
                        manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                    } else {
                        return result.error("NOT_SUPPORTED", "Lock screen requires API 24+", null)
                    }
                }
                "both" -> {
                    if (sdkVersion >= android.os.Build.VERSION_CODES.N) {
                        manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                        manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                    } else {
                        manager.setBitmap(bitmap)
                    }
                }
            }

            Log.i(TAG, "Plugin: Success")
            result.success(true)

        } catch (e: Exception) {
            Log.e(TAG, "Plugin: Critical failure: ${e.message}", e)
            result.error("WALLPAPER_ERROR", e.message, null)
        }
    }
}
