package dev.tarnan.financetracker

import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FlutterFragmentActivity, not a FlutterActivity: local_auth shows the biometric prompt as
// a fragment (features/lock/), and fails with NOT_FRAGMENT_ACTIVITY otherwise.
//
// Three channels of the app's own, behind Dart seams in core/platform/:
// screen_security's setSecure(bool) adds or clears FLAG_SECURE on this window (no
// screenshots, no recording, a blank task-switcher thumbnail; screen_security.dart),
// clock's elapsedRealtime answers SystemClock.elapsedRealtime(), milliseconds since boot
// counting deep sleep, for the lock's timeout (monotonic_clock.dart), and system_settings
// opens a notification channel's settings or the app's details in Android and says
// whether Android restricts the app's background work (system_settings.dart). Method
// calls arrive on the main thread, where the window's flags are set.
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
        MethodChannel(messenger, "dev.tarnan.financetracker/system_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChannelSettings" -> result.success(
                        open(
                            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                .putExtra(Settings.EXTRA_CHANNEL_ID, call.arguments as String),
                        ),
                    )
                    "openAppDetails" -> result.success(
                        open(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ),
                        ),
                    )
                    "backgroundRestricted" -> result.success(backgroundRestricted())
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

    // Starts [intent]; false when no activity answers it.
    private fun open(intent: Intent): Boolean =
        try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }

    // Whether the user restricted the app's background use (Android 9 and later) or
    // Android put it in the restricted standby bucket (Android 11 and later).
    private fun backgroundRestricted(): Boolean {
        val byUser = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            getSystemService(ActivityManager::class.java).isBackgroundRestricted
        val byBucket = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            getSystemService(UsageStatsManager::class.java).appStandbyBucket ==
            UsageStatsManager.STANDBY_BUCKET_RESTRICTED
        return byUser || byBucket
    }

    private companion object {
        // quick_actions' extra for the chosen shortcut (QuickActions.EXTRA_ACTION).
        const val SHORTCUT_EXTRA = "some unique action key"
    }
}
