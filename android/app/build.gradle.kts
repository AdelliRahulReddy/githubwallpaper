plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rahulreddy.githubwallpaper"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ FIXED: Add Kotlin JVM target to match Java
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.rahulreddy.githubwallpaper"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Workaround: Copy APK to Flutter expected location (fixes Kotlin DSL path detection issue)
tasks.whenTaskAdded {
    if (name == "assembleDebug" || name == "assembleRelease") {
        doLast {
            val buildType = if (name.contains("Debug")) "debug" else "release"
            val sourceDir = file("${project.layout.buildDirectory.get()}/outputs/flutter-apk")
            val targetDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
            
            if (sourceDir.exists()) {
                targetDir.mkdirs()
                sourceDir.listFiles()?.forEach { apkFile ->
                    if (apkFile.name.endsWith(".apk")) {
                        apkFile.copyTo(file("${targetDir}/${apkFile.name}"), overwrite = true)
                    }
                }
            }
        }
    }
}
