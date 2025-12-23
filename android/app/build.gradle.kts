import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
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
        versionName = project.properties["flutter.applicationId"].toString()
        minSdk = project.properties["flutter.minSdkVersion"].toString().toInt()
        targetSdk = project.properties["flutter.targetSdkVersion"].toString().toInt()
        versionCode = project.properties["flutter.versionCode"].toString().toInt()
        versionName = project.properties["flutter.versionName"].toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { File(rootProject.projectDir, "app/$it") }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Use release signing config if available, otherwise fall back to debug
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

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

dependencies {
    implementation("androidx.documentfile:documentfile:1.0.1")
}
