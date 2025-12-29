# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Generative AI
-keep class com.google.** { *; }
-dontwarn com.google.**

# Notification
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Permission Handler
-keep class com.baseflow.** { *; }
-dontwarn com.baseflow.**

# Timezone
-keep class com.github.** { *; }
-dontwarn com.github.**
