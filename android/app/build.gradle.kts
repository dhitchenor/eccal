plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = project.properties["flutter.applicationId"].toString()
    compileSdk = project.properties["flutter.compileSdkVersion"].toString().toInt()
    ndkVersion = project.properties["flutter.ndkVersion"].toString()

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = project.findProperty("flutter.applicationId")?.toString() 
                    ?: "com.hitchenor.diary_app"
        versionName = project.properties["flutter.applicationId"].toString()
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = project.properties["flutter.minSdkVersion"].toString().toInt()
        targetSdk = project.properties["flutter.targetSdkVersion"].toString().toInt()
        versionCode = project.properties["flutter.versionCode"].toString().toInt()
        versionName = project.properties["flutter.versionName"].toString()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Add ProGuard rules to prevent MainActivity from being removed
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