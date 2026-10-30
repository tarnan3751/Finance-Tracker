package dev.tarnan.financetracker.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import dev.tarnan.financetracker.MainActivity
import dev.tarnan.financetracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

// The home screen widgets render the snapshot the app wrote (features/widgets/ in Dart:
// WidgetData, written as JSON under "snapshot" in home_widget's preferences) and nothing
// else: every text, amounts and dates included, was formatted by the app in the device's
// locale, no database is opened here, and a redraw only reads one preference, well within
// a receiver's time. A snapshot of another format version reads as none. A tap opens the
// app at a financetracker:// link (core/router/launch_links.dart) through home_widget's
// launch action, which the app's LaunchIntent seam reads. While the app lock is enabled the
// snapshot is "locked": every amount, percent and bar is masked ([masked]), names, due dates
// and the footer stay, and each row's spoken text (the app's) says the amount is hidden.

// The key the snapshot is stored under and its format version (widget_data.dart's
// widgetSnapshotKey and widgetSnapshotVersion).
private const val SNAPSHOT_KEY = "snapshot"
private const val SNAPSHOT_VERSION = 1

// The snapshot, or null when none was written or it is of another version.
internal fun readSnapshot(prefs: SharedPreferences): JSONObject? {
    val raw = prefs.getString(SNAPSHOT_KEY, null) ?: return null
    return try {
        JSONObject(raw).takeIf { it.optInt("v") == SNAPSHOT_VERSION }
    } catch (e: JSONException) {
        null
    }
}

// The snapshot's [name] list's objects.
internal fun JSONObject.rows(name: String): List<JSONObject> {
    val array: JSONArray = optJSONArray(name) ?: return emptyList()
    return (0 until array.length()).mapNotNull { array.optJSONObject(it) }
}

// What a masked amount shows: no digits, no length, no sign (widget_data.dart's
// widgetMask, which a locked snapshot already holds; masking here is the fallback).
internal const val MASK = "\u2022\u2022\u2022\u2022"

// Whether the snapshot asks for amounts to be masked.
internal val JSONObject.locked: Boolean
    get() = optBoolean("locked")

// [value], or the mask when [snapshot] is locked (and [value] is not null).
internal fun masked(snapshot: JSONObject, value: String?): String? =
    if (value != null && snapshot.locked) MASK else value

// A string field, or null when absent or null.
internal fun JSONObject.text(name: String): String? =
    if (isNull(name)) null else optString(name)

// The launch link of [segments], each encoded: financetracker://plan/bills/<id>.
internal fun launchLink(vararg segments: String): String =
    "financetracker://" + segments.joinToString("/") { Uri.encode(it) }

// Opens the app at [link].
internal fun launch(context: Context, link: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(link))

// [id] shown with [value], or gone when it is null.
internal fun RemoteViews.show(id: Int, value: String?) {
    if (value == null) {
        setViewVisibility(id, View.GONE)
    } else {
        setViewVisibility(id, View.VISIBLE)
        setTextViewText(id, value)
    }
}

// Of two views styled alike but for their colour, [normal] and [alert], shows [alert]
// with [value] when [alerting], else [normal].
internal fun RemoteViews.showEither(normal: Int, alert: Int, alerting: Boolean, value: String?) {
    show(if (alerting) alert else normal, value)
    setViewVisibility(if (alerting) normal else alert, View.GONE)
}

// A widget that renders the snapshot at its size: [render] with wide true from 250 dp
// across (4 cells), else false. On Android 12 and later the launcher picks between the two
// as the widget is resized; before, the width the launcher reports picks one.
//
// The rows shown are those that fit the widget's height at the system's font scale
// ([rows]), at most three: a widget that would clip drops its last row instead, never the
// footer.
abstract class FinanceWidgetProvider : HomeWidgetProvider() {
    // The widget's views for [snapshot] (null: nothing written yet), with at most [rows]
    // rows.
    abstract fun render(
        context: Context,
        snapshot: JSONObject?,
        wide: Boolean,
        rows: Int,
    ): RemoteViews

    // The height of everything but the rows, in sp (text) and dp (padding and spacing).
    protected abstract val chromeSp: Float
    protected open val chromeDp: Float = PADDING_DP

    // One row's height, in sp (text) and dp (padding, a bar).
    protected abstract val rowSp: Float
    protected abstract val rowDp: Float

    // How many rows (one to three) fit [heightDp] at the system's font scale; three when
    // the launcher reports no height. Text is scaled linearly, which overestimates the
    // non-linear scaling of Android 14 and later, so the estimate errs towards dropping.
    private fun rows(context: Context, heightDp: Int): Int {
        if (heightDp <= 0) return MAX_ROWS
        val scale = context.resources.configuration.fontScale
        val free = heightDp - chromeDp - chromeSp * scale
        return (free / (rowDp + rowSp * scale)).toInt().coerceIn(1, MAX_ROWS)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = readSnapshot(widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views(context, appWidgetManager, id, snapshot))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val snapshot = readSnapshot(HomeWidgetPlugin.getData(context))
        appWidgetManager.updateAppWidget(
            appWidgetId,
            views(context, appWidgetManager, appWidgetId, snapshot),
        )
    }

    private fun views(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        snapshot: JSONObject?,
    ): RemoteViews {
        val options = manager.getAppWidgetOptions(id)
        // The portrait height (the larger of the two the launcher reports).
        val rows = rows(context, options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to render(context, snapshot, false, rows),
                    SizeF(WIDE_DP, 40f) to render(context, snapshot, true, rows),
                ),
            )
        }
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        return render(context, snapshot, width >= WIDE_DP, rows)
    }

    // The set-up state: the widget's [title] and "Open Finance Tracker to set up"; a tap
    // opens the app at [link].
    protected fun setUp(context: Context, title: Int, link: String): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_setup).apply {
            setTextViewText(R.id.title, context.getString(title))
            setOnClickPendingIntent(android.R.id.background, launch(context, link))
        }

    // The snapshot's footer, "Updated 2:41 PM".
    protected fun RemoteViews.footer(snapshot: JSONObject) =
        show(R.id.updated, snapshot.text("updated"))

    private companion object {
        const val WIDE_DP = 250f
        const val PADDING_DP = 24f
        const val MAX_ROWS = 3
    }
}
