package dev.tarnan.financetracker.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import dev.tarnan.financetracker.R
import org.json.JSONObject

// Upcoming bills (2 by 2, 4 by 2 and wider): the next three unpaid bills as the app
// ordered them (missed first, in the error colour), with their due dates, and at 4 cells
// their amounts, masked (and missed ones in the neutral colour) while the app is locked.
// A tap opens the Bills segment; a row opens that bill.
class BillsWidgetProvider : FinanceWidgetProvider() {
    // The title and the footer; a row is two lines.
    override val chromeSp = 34f
    override val rowSp = 33f
    override val rowDp = 4f

    override fun render(
        context: Context,
        snapshot: JSONObject?,
        wide: Boolean,
        rows: Int,
    ): RemoteViews {
        val bills = snapshot?.rows("bills").orEmpty()
        if (snapshot == null || !snapshot.optBoolean("signed_in") || bills.isEmpty()) {
            return setUp(context, R.string.widget_bills_label, launchLink("plan", "bills"))
        }
        val layout = if (wide) R.layout.widget_bills_wide else R.layout.widget_bills_small
        return RemoteViews(context.packageName, layout).apply {
            setOnClickPendingIntent(
                android.R.id.background,
                launch(context, launchLink("plan", "bills")),
            )
            ROWS.forEachIndexed { i, ids ->
                val bill = if (i < rows) bills.getOrNull(i) else null
                if (bill == null) {
                    setViewVisibility(ids.row, View.GONE)
                    return@forEachIndexed
                }
                setViewVisibility(ids.row, View.VISIBLE)
                show(ids.name, bill.text("name"))
                // Locked: the neutral colour, so the masked widget shows no bill's status.
                val overdue = !snapshot.locked && bill.optBoolean("overdue")
                showEither(ids.due, ids.dueOverdue, overdue, bill.text("due_text"))
                if (wide) show(ids.amount, masked(snapshot, bill.text("amount")))
                setContentDescription(ids.row, bill.text("spoken"))
                bill.text("id")?.let {
                    setOnClickPendingIntent(ids.row, launch(context, launchLink("plan", "bills", it)))
                }
            }
            footer(snapshot)
        }
    }

    private class Row(val row: Int, val name: Int, val due: Int, val dueOverdue: Int, val amount: Int)

    private companion object {
        val ROWS = listOf(
            Row(R.id.bill_0, R.id.bill_name_0, R.id.bill_due_0, R.id.bill_due_overdue_0, R.id.bill_amount_0),
            Row(R.id.bill_1, R.id.bill_name_1, R.id.bill_due_1, R.id.bill_due_overdue_1, R.id.bill_amount_1),
            Row(R.id.bill_2, R.id.bill_name_2, R.id.bill_due_2, R.id.bill_due_overdue_2, R.id.bill_amount_2),
        )
    }
}
