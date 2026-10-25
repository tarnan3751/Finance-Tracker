// The transaction row on bank data: Plaid's merchant and logo when it gave them, else the
// dictionary's name or the cleaned raw name on a letter avatar in the brand or palette
// color, the account and the category, and "Pending" on a pending transaction.
import 'package:finance_tracker/core/widgets/merchant_avatar.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _tile(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(TransactionTile));

void main() {
  Future<void> pumpList(WidgetTester tester) => pumpApp(
    tester,
    initialLocation: '/transactions',
    overrides: [storeOverride(linkedStore())],
  );

  testWidgets("Plaid's merchant and logo are shown as Plaid gave them", (
    tester,
  ) async {
    await pumpList(tester);

    final Image logo = tester.widget(
      find.descendant(of: _tile('Starbucks'), matching: find.byType(Image)),
    );
    expect(
      (logo.image as NetworkImage).url,
      'https://plaid-merchant-logos.plaid.com/starbucks_956.png',
    );
    // flutter_test answers every request 400, so the letter shows in its place.
    expect(
      find.descendant(of: _tile('Starbucks'), matching: find.text('S')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _tile('Starbucks'),
        matching: find.text('Platypus Checking · Uncategorized'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a raw name the dictionary knows shows its merchant', (
    tester,
  ) async {
    await pumpList(tester);

    expect(find.text('NETFLIX.COM'), findsNothing);
    final CircleAvatar avatar = tester.widget(
      find.descendant(
        of: _tile('Netflix'),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(avatar.backgroundColor, const Color(0xFFE50914));
    expect(
      find.descendant(of: _tile('Netflix'), matching: find.byType(Image)),
      findsNothing,
    );
  });

  testWidgets('an unknown raw name is cleaned, on a palette color', (
    tester,
  ) async {
    await pumpList(tester);

    expect(find.text('TST*TACO ROCK - LORTON'), findsNothing);
    final MerchantAvatar avatar = tester.widget(
      find.descendant(
        of: _tile('Taco Rock'),
        matching: find.byType(MerchantAvatar),
      ),
    );
    expect(avatar.color, paletteColor('Taco Rock'));
    expect(avatar.logoUrl, isNull);
  });

  testWidgets('a pending transaction is marked', (tester) async {
    await pumpList(tester);

    expect(
      find.descendant(of: _tile('Uber'), matching: find.text('Pending')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _tile('Netflix'), matching: find.text('Pending')),
      findsNothing,
    );
  });

  testWidgets('the account ledger rows carry the avatars too', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/accounts/$linkedCheckingId',
      overrides: [storeOverride(linkedStore())],
    );

    expect(_tile('Netflix'), findsOneWidget);
    expect(
      find.descendant(
        of: _tile('Netflix'),
        matching: find.byType(MerchantAvatar),
      ),
      findsOneWidget,
    );
  });
}
