# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive and Storage classes from being obfuscated if needed (usually handled by R8 automatically)
-keep class com.mongodb.** { *; }
-keep class com.google.firebase.** { *; }
