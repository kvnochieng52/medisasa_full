# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter engine
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Gson specific rules
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }

# OkHttp specific rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# HTTP client rules
-keep class java.lang.invoke.** { *; }
-keep class org.apache.http.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# General rules for better compatibility
-dontwarn java.lang.invoke.*
-dontwarn **$$serializer
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep application class
-keep class com.xyvrahealth.app.** { *; }

# Keep MainActivity
-keep class com.xyvrahealth.app.MainActivity { *; }

# Prevent crashes from reflection
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core - Fix for R8 missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter deferred components and Play Store split compatibility
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }

# Additional Play Core rules
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }