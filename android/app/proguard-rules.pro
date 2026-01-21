# ============================================================================
# GitHub Wallpaper - ProGuard Rules for Release Builds
# Prevents code stripping that would break WorkManager and Platform Channels
# ============================================================================

# ──────────────────────────────────────────────────────────────────────────
# 1. FLUTTER FRAMEWORK (Required)
# ──────────────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Don't obfuscate Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# ──────────────────────────────────────────────────────────────────────────
# 2. PLATFORM CHANNEL (CRITICAL - Your Wallpaper Feature)
# ──────────────────────────────────────────────────────────────────────────
# Keep MainActivity and all methods called from Dart
-keep class com.rahulreddy.githubwallpaper.MainActivity { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class io.flutter.plugin.common.MethodChannel$Result { *; }

# ──────────────────────────────────────────────────────────────────────────
# 3. WORKMANAGER (CRITICAL - Your Auto-Update Feature)
# ──────────────────────────────────────────────────────────────────────────
# Keep all WorkManager classes
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.background.systemalarm.** { *; }

# Don't strip WorkManager's background task callback
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Keep WorkManager initialization provider
-keep class androidx.startup.** { *; }

# ──────────────────────────────────────────────────────────────────────────
# 4. ANDROID SYSTEM APIs
# ──────────────────────────────────────────────────────────────────────────
# WallpaperManager API
-keep class android.app.WallpaperManager { *; }

# Keep native method names (used by Flutter)
-keepclasseswithmembernames class * {
    native <methods>;
}

# ──────────────────────────────────────────────────────────────────────────
# 5. KOTLIN COROUTINES (If you add async code later)
# ──────────────────────────────────────────────────────────────────────────
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ──────────────────────────────────────────────────────────────────────────
# 6. HTTP & NETWORKING (For GitHub API Calls)
# ──────────────────────────────────────────────────────────────────────────
# OkHttp (used by http package)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ──────────────────────────────────────────────────────────────────────────
# 7. GENERAL ANDROID RULES
# ──────────────────────────────────────────────────────────────────────────
# Keep AndroidX annotations
-keep class androidx.annotation.** { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ──────────────────────────────────────────────────────────────────────────
# 8. REMOVE LOGS IN RELEASE (Optional - Saves space)
# ──────────────────────────────────────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Keep warnings and errors for debugging production issues
-keep class android.util.Log {
    public static int w(...);
    public static int e(...);
}

# ──────────────────────────────────────────────────────────────────────────
# 9. OPTIMIZATION SETTINGS
# ──────────────────────────────────────────────────────────────────────────
# Allow aggressive optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Preserve line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
