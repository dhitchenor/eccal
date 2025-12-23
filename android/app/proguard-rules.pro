# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep MainActivity - CRITICAL!
-keep class com.dhitchenor.eccal.MainActivity { *; }
-keep class com.dhitchenor.eccal.** { *; }

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# AndroidX
-keep class androidx.lifecycle.** { *; }

# Google Play Core (optional dependencies - ignore if missing)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }

# Ignore missing Google Play Core split install classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile