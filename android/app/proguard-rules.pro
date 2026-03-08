# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core - deferred components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Bluetooth Serial
-keep class com.github.otyrin.** { *; }
-dontwarn com.github.otyrin.**

# Flutter Blue Plus
-keep class com.lib.flutter_blue_plus.** { *; }
-dontwarn com.lib.flutter_blue_plus.**

# Bluetooth
-keep class android.bluetooth.** { *; }
-dontwarn android.bluetooth.**
