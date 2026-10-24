# R8 keep rules for the release build, on top of proguard-android-optimize.txt and the
# rules Flutter and each plugin ship. R8 touches Java and Kotlin code only: native
# libraries loaded over FFI, such as the encrypted database's SQLite3 Multiple Ciphers
# build, need no rule. Only dependencies that R8 would otherwise break are kept here; the
# app's own classes are not.

# The Plaid Link Android SDK behind plaid_flutter (Phase 3).
-keep class com.plaid.** { *; }

# WorkManager, which the Plaid Link SDK depends on, creates its Room database by
# reflection at startup (androidx.startup); R8 full mode drops the generated database's
# no-argument constructor unless it is kept, and the release app then crashes on launch.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
