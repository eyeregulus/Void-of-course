# Proguard rules for Void of Course app

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods/FFI classes if any are used
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter Play Store Deferred Components (ignore warnings for missing Play Store classes)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
