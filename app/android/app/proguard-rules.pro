# R8 keep rules for the release build, on top of proguard-android-optimize.txt and the
# rules Flutter and each plugin ship. R8 touches Java and Kotlin code only: native
# libraries loaded over FFI, such as the encrypted database's SQLite3 Multiple Ciphers
# build, need no rule. Only dependencies that R8 would otherwise break are kept here; the
# app's own classes are not.

# The Plaid Link Android SDK behind plaid_flutter (Phase 3).
-keep class com.plaid.** { *; }
