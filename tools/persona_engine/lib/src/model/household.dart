/// What the generator produces: one household's accounts and history, in `shared_models`
/// types where they exist and the package's own small types where they do not.
library;

import 'package:meta/meta.dart';
import 'package:persona_engine/src/model/anomaly.dart';
import 'package:persona_engine/src/model/investments.dart';
import 'package:persona_engine/src/model/liabilities.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/model/recurring_expectation.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Liability, Security;

/// The id of the account [key] in [persona]'s household.
String accountIdFor(PersonaId persona, String key) =>
    'demo-${persona.slug}-$key';

/// The id of the demo Item for the institution [institutionKey].
String itemIdFor(PersonaId persona, String institutionKey) =>
    'demo-item-${persona.slug}-$institutionKey';

/// An account's balance at the end of the day before the window: the starting point the
/// derived balance is counted from. It is not a transaction, so a demo account's history
/// looks like a linked account's. A loan's is its amortized balance from origination; an
/// investment account's is its uninvested cash, beside [GeneratedHousehold.openingHoldings].
@immutable
final class OpeningBalance {
  /// An opening balance.
  const OpeningBalance(this.accountId, this.date, this.amount);

  /// The account.
  final String accountId;

  /// The day before the window's first day.
  final LocalDate date;

  /// The balance, in the domain's sign (owed is negative).
  final Money amount;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'account_id': accountId,
    'date': date.toIso(),
    'amount': amount.toJson(),
  };
}

/// The two legs of a transfer between the household's own accounts. Their amounts are
/// equal and opposite and their dates equal.
@immutable
final class TransferPair {
  /// A pair.
  const TransferPair(this.outTransactionId, this.inTransactionId);

  /// The outflow leg.
  final String outTransactionId;

  /// The inflow leg.
  final String inTransactionId;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'out_transaction_id': outTransactionId,
    'in_transaction_id': inTransactionId,
  };
}

/// A generated household.
///
/// Every [transactions] entry has `source: demo`. Each non-investment account's
/// `currentBalance` is its [openingBalances] entry plus its transactions; an investment
/// account's is its holdings' value plus its uninvested cash. The household is defined
/// relative to [asOf]: its loan principals, interest paid this year and positions on
/// [asOf] do not depend on the window's length. Depository and card balances do, since
/// each window starts them from the persona's fixed openings.
@immutable
final class GeneratedHousehold {
  /// A household; built by the generator only.
  const GeneratedHousehold({
    required this.persona,
    required this.seed,
    required this.asOf,
    required this.window,
    required this.institutions,
    required this.items,
    required this.accounts,
    required this.openingBalances,
    required this.transactions,
    required this.transfers,
    required this.interestTransactionIds,
    required this.recurring,
    required this.holdings,
    required this.openingHoldings,
    required this.investmentTransactions,
    required this.liabilities,
    required this.anomalies,
  });

  /// The persona it was generated from.
  final Persona persona;

  /// The seed.
  final int seed;

  /// The last day of the window, and the date balances are reported for.
  final LocalDate asOf;

  /// The window, `[first day, asOf + 1)`.
  final LocalDateRange window;

  /// The institutions.
  final List<Institution> institutions;

  /// One demo Item per institution.
  final List<Item> items;

  /// The accounts, in the persona's order.
  final List<Account> accounts;

  /// Each non-investment account's opening balance.
  final List<OpeningBalance> openingBalances;

  /// The transactions, by date then emission order.
  final List<Transaction> transactions;

  /// The transfers between the household's accounts.
  final List<TransferPair> transfers;

  /// The loan and card interest charges, which the Sandbox outputs can leave out.
  final Set<String> interestTransactionIds;

  /// The streams that recur on a schedule.
  final List<RecurringExpectation> recurring;

  /// The positions on [asOf].
  final List<Holding> holdings;

  /// The positions on the window's eve, priced that day.
  final List<Holding> openingHoldings;

  /// Contributions and purchases.
  final List<InvestmentTransaction> investmentTransactions;

  /// Card and loan detail on [asOf].
  final List<Liability> liabilities;

  /// The planted anomalies.
  final List<Anomaly> anomalies;

  /// The account spec behind the account [accountId].
  AccountSpec accountSpec(String accountId) => persona.accounts.firstWhere(
    (a) => accountIdFor(persona.id, a.key) == accountId,
  );
}
