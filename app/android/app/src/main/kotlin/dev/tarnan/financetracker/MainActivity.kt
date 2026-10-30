package dev.tarnan.financetracker

import android.os.SystemClock
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FlutterFragmentActivity, not a FlutterActivity: local_auth shows the biometric prompt as
// a fragment (features/lock/), and fails with NOT_FRAGMENT_ACTIVITY otherwise.
//
// Two channels of the app's own, behind Dart seams in core/platform/:
// screen_security's setSecure(bool) adds or clears FLAG_SECURE on this window (no
// screenshots, no recording, a blank task-switcher thumbnail; screen_security.dart), and
// clock's elapsedRealtime answers SystemClock.elapsedRealtime(), milliseconds since boot
// counting deep sleep, for the lock's timeout (monotonic_clock.dart). Method calls arrive on
// the main thread, where the window's flags are set.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "dev.tarnan.financetracker/screen_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        if (call.arguments == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(messenger, "dev.tarnan.financetracker/clock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "elapsedRealtime" -> result.success(SystemClock.elapsedRealtime())
                    else -> result.notImplemented()
                }
            }
    }
}
