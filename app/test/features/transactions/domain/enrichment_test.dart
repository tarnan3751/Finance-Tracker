// The merchant enrichment fallback: Plaid's merchant name and logo are used untouched; a
// manual description is shown as typed; otherwise the dictionary names the raw name, or it
// is cleaned; colors are the brand's or a stable palette color. Checked on the 316 raw
// names Plaid Sandbox returned (test/fixtures/plaid_transaction_names.json, copied from
// server/test/fixtures/plaid/transactions_sync_page1.json, names only).
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/domain/merchant_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Transaction _transaction(
  String name, {
  String? merchantName,
  Uri? logoUrl,
  DataSource source = DataSource.plaid,
}) => Transaction(
  id: 't',
  accountId: 'a',
  amount: Money(-100, 'USD'),
  date: LocalDate(2026, 10, 1),
  pending: false,
  name: name,
  merchantName: merchantName,
  merchantLogoUrl: logoUrl,
  source: source,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
  syncVersion: 0,
);

void main() {
  final List<String> sandboxNames = (jsonDecode(
    File('test/fixtures/plaid_transaction_names.json').readAsStringSync(),
  ) as List<Object?>).cast<String>();

  group("Plaid's values", () {
    test('a merchant name and logo are used as they are', () {
      final Uri logo = Uri.parse(
        'https://plaid-merchant-logos.plaid.com/x.png',
      );
      final EnrichedMerchant m = EnrichedMerchant.resolve(
        _transaction(
          'NETFLIX.COM',
          merchantName: 'Some Merchant',
          logoUrl: logo,
        ),
      );
      expect(m.displayName, 'Some Merchant');
      expect(m.logoUrl, logo);
    });

    test('a merchant name is never replaced by the dictionary', () {
      final EnrichedMerchant m = EnrichedMerchant.resolve(
        _transaction('NETFLIX.COM', merchantName: 'Amazon Marketplace'),
      );
      expect(m.displayName, 'Amazon Marketplace');
      expect(m.logoUrl, isNull);
    });

    test("the brand color follows Plaid's merchant name first", () {
      final EnrichedMerchant m = EnrichedMerchant.resolve(
        _transaction('UNRELATED 123', merchantName: 'Netflix'),
      );
      expect(m.color, 0xFFE50914);
    });

    test("an institution's color is Plaid's primary color when present", () {
      expect(
        institutionColor(
          const Institution(
            id: 'i',
            name: 'Tartan Bank',
            primaryColor: 0xFF0075A3,
          ),
        ),
        0xFF0075A3,
      );
      expect(
        institutionColor(const Institution(id: 'i', name: 'Tartan Bank')),
        paletteColor('Tartan Bank'),
      );
    });
  });

  group('the dictionary', () {
    const Map<String, String> hits = {
      'NETFLIX.COM': 'Netflix',
      'WHOLEFDS MKT 10234': 'Whole Foods',
      'AMZN Mktp US*2K4AB1C23': 'Amazon',
      'Amazon.com*BDXXIXQKX': 'Amazon',
      'Prime Video Channels': 'Amazon Prime Video',
      'SQ *BLUE BOTTLE COFFEE 123': 'Blue Bottle Coffee',
      'PAYPAL *NETFLIX': 'Netflix',
      'PAYPAL INST XFER': 'PayPal',
      'DNH*GODADDY#XXXXXXXXXX': 'GoDaddy',
      '7-ELEVEN 34012': '7-Eleven',
      'Uber Eats': 'Uber Eats',
      'UBER 588639690 RIDE 05/12': 'Uber',
      'INTERAC PURCHASE - 67200 TARGET #052': 'Target',
      'PURCHASE AUTHORIZED ON 05/27 ROYAL FARMS 100 MONUMENT AVE':
          'Royal Farms',
      "5 PURCHASE-SIG DENNY'S 366992 EUGENE OR": "Denny's",
      'STOP & SHOP #25402 WEST CALDWELL': 'Stop & Shop',
      'EFT DEBIT  MICROSOFT XBOX CA 830 08/03': 'Microsoft Xbox',
      'XXXXXD CAVA KINGSTOWNE': 'Cava',
      'SHELL OIL 57442': 'Shell',
      // The brand's name since 2019, as Plaid also gives it.
      "Dunkin' Donuts": "Dunkin'",
      'DUNKIN #350123': "Dunkin'",
    };
    for (final MapEntry(key: String raw, value: String name) in hits.entries) {
      test('names "$raw" $name', () {
        expect(EnrichedMerchant.resolve(_transaction(raw)).displayName, name);
      });
    }

    test('matches whole words only', () {
      expect(lookupMerchant('APPLEBEES 1234')?.name, "Applebee's");
      expect(lookupMerchant('CAVALIER HOTEL'), isNull);
    });

    test('gives the brand color, else none', () {
      expect(lookupMerchant('NETFLIX.COM')!.color, 0xFFE50914);
      expect(lookupMerchant('WEGMANS #93')!.color, isNull);
    });

    test('has no key twice, and every key normalizes to words', () {
      final List<String> keys = [
        for (final MerchantEntry e in merchantDictionary)
          for (final String k in e.keys) normalizeMerchantText(k),
      ];
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, everyElement(matches(RegExp(r'^[a-z0-9]+( [a-z0-9]+)*$'))));
    });
  });

  group('the cleaned raw name', () {
    const Map<String, String> cleaned = {
      'GYRO FACTORY LLC': 'Gyro Factory LLC',
      'ATM WITHDRAWAL': 'ATM Withdrawal',
      'ACME CO INC': 'Acme CO INC',
      'IRS USATAXPYMT': 'IRS Usataxpymt',
      'DMV RENEWAL 4471': 'DMV Renewal',
      'MAPLE HOA DUES': 'Maple HOA Dues',
      'TST*TACO ROCK - LORTON': 'Taco Rock',
      'QUEENS BAR 35 E GRAND RIVER AVE #9 DETROIT MI CARD 29602991':
          'Queens Bar',
      'POS PUR 449399193 04/07 TIMESTAMP THE PIZZA PLACE 4205 NEW YORK':
          'The Pizza Place',
      'WITHDRAWAL 02178293119 POS POUR CHOICES': 'Pour Choices',
      'CITY POWER & LIGHT': 'City Power & Light',
      'Payment Thank You-Mobile': 'Payment Thank You-Mobile',
      'Monthly payment': 'Monthly payment',
      '123456': '123456',
    };
    for (final MapEntry(key: String raw, value: String name)
        in cleaned.entries) {
      test('of "$raw" is $name', () {
        final EnrichedMerchant m = EnrichedMerchant.resolve(_transaction(raw));
        expect(m.displayName, name);
        expect(m.logoUrl, isNull);
        expect(m.color, paletteColor(name));
      });
    }
  });

  test("a manual transaction's description is shown as typed", () {
    final EnrichedMerchant typed = EnrichedMerchant.resolve(
      _transaction('iPhone 15 case', source: DataSource.manual),
    );
    expect(typed.displayName, 'iPhone 15 case');
    final EnrichedMerchant known = EnrichedMerchant.resolve(
      _transaction('netflix', source: DataSource.manual),
    );
    expect(known.displayName, 'netflix');
    expect(known.color, 0xFFE50914);
  });

  test('palette colors are stable and ignore case and punctuation', () {
    expect(paletteColor('Gyro Factory'), paletteColor('GYRO FACTORY'));
    expect(paletteColor("Joe's Cafe"), paletteColor('JOES CAFE'));
    expect(palette, contains(paletteColor('anything at all')));
    // A fixed value: a change of the hash would recolor every letter avatar.
    expect(paletteColor('Gyro Factory'), 0xFF283593);
  });

  group("Sandbox's raw names", () {
    test('there are 316', () => expect(sandboxNames, hasLength(316)));

    test('every one resolves to a name with no reference left in it', () {
      for (final String raw in sandboxNames) {
        final String name = EnrichedMerchant.resolve(_transaction(raw))
            .displayName;
        expect(name.trim(), isNotEmpty, reason: raw);
        expect(name, isNot(matches(RegExp(r'[0-9]{3}|[#*]'))), reason: raw);
        expect(name, isNot(contains('  ')), reason: raw);
      }
    });

    test('the merchants Plaid recognized are in the dictionary', () {
      const List<String> recognized = [
        'Spotify',
        'McDonald\'s',
        'Starbucks',
        'Walmart',
        'Netflix',
        'Amazon',
        'Apple',
        'Target',
        'Uber',
        'KFC',
        'Lidl',
        'OpenAI',
        'Chick-fil-A',
        'Safeway',
        'Planet Fitness',
      ];
      final Set<String> named = {
        for (final String raw in sandboxNames) ?lookupMerchant(raw)?.name,
      };
      expect(named, containsAll(recognized));
    });
  });
}
