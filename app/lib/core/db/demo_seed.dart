/// The demo flavor's data: a household from the persona engine, generated at startup with
/// no server and no database (`PLAN.md` §7.1: synthesized data lives in the demo flavor,
/// labelled `demo`; `docs/reference/persona.md`).
///
/// The persona engine's accounts belong to demo Items and report the balance their
/// history gives; the app's accounts screens show balances derived from transactions, so
/// each non-zero opening balance (the balance the day before the window, which the
/// engine keeps apart from the transactions) is loaded as an "Opening balance"
/// transaction, `source: demo`, dated that day, as a manual account's opening balance is.
/// Investment accounts have no transaction history in the engine, so they derive to their
/// uninvested cash only (holdings arrive with Phase 6). The engine's Items are loaded
/// with their institutions, as the demo's fake server lists them; its liabilities,
/// holdings, recurring expectations and anomalies are not: the app has no repositories
/// for them yet.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

/// The persona the demo flavor starts with: the `FT_DEMO_PERSONA` dart-define's slug
/// ([PersonaId.slug]), or the renter when it is unset or names no persona.
PersonaId initialDemoPersona([
  String slug = const String.fromEnvironment('FT_DEMO_PERSONA'),
]) {
  for (final PersonaId persona in PersonaId.values) {
    if (persona.slug == slug) return persona;
  }
  return PersonaId.renter;
}

/// The demo seed of [persona] as of [today]: seed 1, the engine's full window.
DemoSeed demoSeedFor(PersonaId persona, LocalDate today) =>
    generateDemoSeed(persona, 1, today);

/// Loads [seed] into [store], through the store's rules: the Items with their
/// institutions, the accounts, an opening balance transaction for each non-zero opening
/// balance, then the transactions.
void loadDemoSeed(InMemoryStore store, DemoSeed seed) {
  final GeneratedHousehold household = seed.household;
  store.applyPlaidItems([
    for (final Item item in household.items)
      (
        item: item,
        institution: household.institutions.firstWhere(
          (i) => i.id == item.institutionId,
        ),
      ),
  ], store.clock.nowUtc());
  household.accounts.forEach(store.upsertAccount);
  for (final OpeningBalance opening in household.openingBalances) {
    if (opening.amount.isZero) continue;
    final LocalDate date = opening.date;
    final DateTime at = DateTime.utc(date.year, date.month, date.day);
    store.upsertTransaction(
      Transaction(
        id: '${opening.accountId}-opening',
        accountId: opening.accountId,
        amount: opening.amount,
        date: date,
        pending: false,
        name: 'Opening balance',
        source: DataSource.demo,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      ),
    );
  }
  household.transactions.forEach(store.upsertTransaction);
}
