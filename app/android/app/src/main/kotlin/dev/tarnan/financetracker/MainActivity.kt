package dev.tarnan.financetracker

import io.flutter.embedding.android.FlutterFragmentActivity

// A FlutterFragmentActivity, not a FlutterActivity: local_auth shows the biometric prompt as
// a fragment (features/lock/), and fails with NOT_FRAGMENT_ACTIVITY otherwise.
class MainActivity : FlutterFragmentActivity()
