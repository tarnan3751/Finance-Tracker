package dev.tarnan.financetracker

import android.content.Intent
import android.os.Bundle
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
//
// The activity stays singleTop: a home screen widget's tap or an app shortcut while the app
// runs arrives in onNewIntent, which the plugins behind the LaunchIntent seam
// (core/platform/launch_intent.dart) read and pass to the router. The new intent also
// becomes the activity's own, so nothing reads the one the app was started with again.
// A launch link is ignored when Android recreates the activity (after the process died,
// from Recents) or relaunches it from history: its intent still carries the link, which
// would reopen the destination (and the camera, for Scan receipt) unasked. The link and
// the shortcut's extra are cleared before the plugins attach.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val fromHistory = intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (savedInstanceState != null || fromHistory) {
            intent.data = null
            intent.removeExtra(SHORTCUT_EXTRA)
        }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

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

    private companion object {
        // quick_actions' extra for the chosen shortcut (QuickActions.EXTRA_ACTION).
        const val SHORTCUT_EXTRA = "some unique action key"
    }
}
