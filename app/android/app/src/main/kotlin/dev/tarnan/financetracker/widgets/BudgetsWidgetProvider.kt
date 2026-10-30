package dev.tarnan.financetracker.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import dev.tarnan.financetracker.R
import org.json.JSONObject

// Budgets (4 by 2): this period's budgets as the app ordered them (over-limit first),
// each with its bar filled as the app's budget card fills it, in the error colour when
// over, what is left or over and the percent spent; while the app is locked, the names
// only, with masked numbers and empty bars. A tap opens the Budgets segment; a row opens
// that budget.
class BudgetsWidgetProvider : FinanceWidgetProvider() {
    // The title and the footer; a row is a line and its bar.
    override val chromeSp = 34f
    override val rowSp = 18f
    override val rowDp = 12f

    override fun render(
        context: Context,
        snapshot: JSONObject?,
        wide: Boolean,
        rows: Int,
    ): RemoteViews {
        val budgets = snapshot?.rows("budgets").orEmpty()
        if (snapshot == null || !snapshot.optBoolean("signed_in") || budgets.isEmpty()) {
            return setUp(context, R.string.widget_budgets_label, launchLink("plan", "budgets"))
        }
        return RemoteViews(context.packageName, R.layout.widget_budgets).apply {
            setOnClickPendingIntent(
                android.R.id.background,
                launch(context, launchLink("plan", "budgets")),
            )
            ROWS.forEachIndexed { i, ids ->
                val budget = if (i < rows) budgets.getOrNull(i) else null
                if (budget == null) {
                    setViewVisibility(ids.row, View.GONE)
                    return@forEachIndexed
                }
                // Locked: no colour, no fill and no numbers tell how a budget stands.
                val locked = snapshot.locked
                val over = !locked && budget.optBoolean("over")
                setViewVisibility(ids.row, View.VISIBLE)
                show(ids.name, budget.text("name"))
                // A locked snapshot holds neither; the mask stands in for both.
                showEither(ids.detail, ids.detailOver, over, if (locked) MASK else budget.text("detail"))
                showEither(ids.percent, ids.percentOver, over, if (locked) MASK else budget.text("percent"))
                setViewVisibility(if (over) ids.barOver else ids.bar, View.VISIBLE)
                setViewVisibility(if (over) ids.bar else ids.barOver, View.GONE)
                setProgressBar(
                    if (over) ids.barOver else ids.bar,
                    10000,
                    if (locked) 0 else budget.optInt("fill_bp").coerceIn(0, 10000),
                    false,
                )
                setContentDescription(ids.row, budget.text("spoken"))
                budget.text("id")?.let {
                    setOnClickPendingIntent(ids.row, launch(context, launchLink("plan", "budgets", it)))
                }
            }
            footer(snapshot)
        }
    }

    private class Row(
        val row: Int,
        val name: Int,
        val detail: Int,
        val detailOver: Int,
        val percent: Int,
        val percentOver: Int,
        val bar: Int,
        val barOver: Int,
    )

    private companion object {
        val ROWS = listOf(
            Row(
                R.id.budget_0, R.id.budget_name_0, R.id.budget_detail_0, R.id.budget_detail_over_0,
                R.id.budget_percent_0, R.id.budget_percent_over_0, R.id.budget_bar_0,
                R.id.budget_bar_over_0,
            ),
            Row(
                R.id.budget_1, R.id.budget_name_1, R.id.budget_detail_1, R.id.budget_detail_over_1,
                R.id.budget_percent_1, R.id.budget_percent_over_1, R.id.budget_bar_1,
                R.id.budget_bar_over_1,
            ),
            Row(
                R.id.budget_2, R.id.budget_name_2, R.id.budget_detail_2, R.id.budget_detail_over_2,
                R.id.budget_percent_2, R.id.budget_percent_over_2, R.id.budget_bar_2,
                R.id.budget_bar_over_2,
            ),
        )
    }
}
