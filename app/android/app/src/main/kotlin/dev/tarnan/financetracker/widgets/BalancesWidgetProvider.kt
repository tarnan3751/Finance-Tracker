package dev.tarnan.financetracker.widgets

import android.content.Context
import android.widget.RemoteViews
import dev.tarnan.financetracker.R
import org.json.JSONObject

// Balances (2 by 2, 4 by 2 and wider): net worth today with what it is computed from
// (account balances, or estimated from transactions), and at 4 cells the three largest
// accounts with their balances as reported or from transactions; the amounts masked while
// the app is locked. A tap opens Accounts; the net worth opens the Net worth segment.
class BalancesWidgetProvider : FinanceWidgetProvider() {
    // The accounts' column: the footer below it; a row is two lines.
    override val chromeSp = 15f
    override val rowSp = 33f
    override val rowDp = 4f

    override fun render(
        context: Context,
        snapshot: JSONObject?,
        wide: Boolean,
        rows: Int,
    ): RemoteViews {
        val netWorth = snapshot?.optJSONObject("net_worth")
        val accounts = snapshot?.rows("accounts").orEmpty()
        if (snapshot == null || !snapshot.optBoolean("signed_in") ||
            (netWorth == null && accounts.isEmpty())
        ) {
            return setUp(context, R.string.widget_balances_label, launchLink("accounts"))
        }
        val layout = if (wide) R.layout.widget_balances_wide else R.layout.widget_balances_small
        return RemoteViews(context.packageName, layout).apply {
            setOnClickPendingIntent(android.R.id.background, launch(context, launchLink("accounts")))
            if (netWorth == null) {
                setViewVisibility(R.id.net_worth_block, android.view.View.GONE)
            } else {
                show(R.id.net_worth, masked(snapshot, netWorth.text("text")))
                show(R.id.net_worth_basis, netWorth.text("basis"))
                setContentDescription(R.id.net_worth_block, netWorth.text("spoken"))
                setOnClickPendingIntent(
                    R.id.net_worth_block,
                    launch(context, launchLink("insights", "net-worth")),
                )
            }
            if (wide) {
                ROWS.forEachIndexed { i, ids ->
                    val account = if (i < rows) accounts.getOrNull(i) else null
                    if (account == null) {
                        setViewVisibility(ids.row, android.view.View.GONE)
                    } else {
                        setViewVisibility(ids.row, android.view.View.VISIBLE)
                        show(ids.name, account.text("name"))
                        show(ids.balance, masked(snapshot, account.text("text")))
                        show(ids.basis, account.text("basis"))
                        setContentDescription(ids.row, account.text("spoken"))
                    }
                }
            }
            footer(snapshot)
        }
    }

    private class Row(val row: Int, val name: Int, val balance: Int, val basis: Int)

    private companion object {
        val ROWS = listOf(
            Row(R.id.account_0, R.id.account_name_0, R.id.account_balance_0, R.id.account_basis_0),
            Row(R.id.account_1, R.id.account_name_1, R.id.account_balance_1, R.id.account_basis_1),
            Row(R.id.account_2, R.id.account_name_2, R.id.account_balance_2, R.id.account_basis_2),
        )
    }
}
