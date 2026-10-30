// The launch links: each widget and shortcut link to its router location (ids encoded,
// Sync now asking for a session), anything else to nothing; the four shortcuts; the
// router opening at a start link; a running app's link going there; and the two
// shortcut screens: the transactions starting with the search field (closing it returns
// to the plain location), on an expanded window a bill's link beside the bills list and
// the search beside its placeholder, and the new transaction's editor opening the camera, also when
// Add transaction's editor is already open, and under the lock only once unlocked.
import 'dart:typed_data';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/platform/app_shortcuts.dart';
import 'package:finance_tracker/core/platform/fake_image_source.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/launch_links.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/bills/presentation/bill_editor_screen.dart';
import 'package:finance_tracker/features/bills/presentation/bills_screen.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/lock/presentation/lock_gate.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:finance_tracker/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

String? _location(String link) => launchTargetOf(Uri.parse(link))?.location;

String _path(WidgetTester tester) {
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  return container
      .read(goRouterProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();
}

void main() {
  group('launchTargetOf', () {
    test('the widgets\' links', () {
      expect(_location('financetracker://accounts'), '/accounts');
      expect(_location('financetracker://insights/net-worth'), '/net-worth');
      expect(_location('financetracker://plan/budgets'), '/budgets');
      expect(
        _location('financetracker://plan/budgets/b-1'),
        '/budgets/b-1/transactions',
      );
      expect(_location('financetracker://plan/bills'), '/bills');
      expect(_location('financetracker://plan/bills/bill-7'), '/bills/bill-7');
    });

    test('an id is decoded from the link and encoded in the location', () {
      expect(
        _location('financetracker://plan/bills/a%20b'),
        const EditBillRoute('a b').location,
      );
    });

    test('the shortcuts\' links; only Sync now asks for a session', () {
      expect(
        _location('financetracker://transactions/new'),
        '/transactions/new',
      );
      expect(
        _location('financetracker://transactions/new?receipt=camera'),
        '/transactions/new?receipt=camera',
      );
      expect(
        _location('financetracker://transactions/new?receipt=other'),
        '/transactions/new',
      );
      expect(_location('financetracker://search'), '/transactions?search=true');
      expect(
        launchTargetOf(syncLink),
        const LaunchTarget('/settings', syncs: true),
      );
      expect(launchTargetOf(searchLink)!.syncs, isFalse);
    });

    test('anything else opens nothing', () {
      for (final String link in [
        'https://accounts',
        'financetracker://',
        'financetracker://settings/delete-account',
        'financetracker://plan',
        'financetracker://plan/bills/a/b',
        'financetracker://accounts/x',
        'other://accounts',
      ]) {
        expect(_location(link), isNull, reason: link);
      }
    });
  });

  test('the four app shortcuts', () {
    final List<AppShortcut> shortcuts = appShortcutsFor(AppLocalizationsEn());
    expect(
      [for (final s in shortcuts) s.title],
      ['Add transaction', 'Scan receipt', 'Search transactions', 'Sync now'],
    );
    expect(
      [for (final s in shortcuts) s.icon],
      [
        'ic_shortcut_add',
        'ic_shortcut_receipt',
        'ic_shortcut_search',
        'ic_shortcut_sync',
      ],
    );
    expect(
      [for (final s in shortcuts) launchTargetOf(s.link)?.location],
      [
        '/transactions/new',
        '/transactions/new?receipt=camera',
        '/transactions?search=true',
        '/settings',
      ],
    );
  });

  test('the router opens at the link the app was started at', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.demo())],
    );
    addTearDown(container.dispose);
    container
        .read(launchLocationProvider.notifier)
        .startAt(Uri.parse('financetracker://plan/bills/bill-7'));
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/bills/bill-7',
    );
  });

  test('a start at an unknown link or none opens at Accounts', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.demo())],
    );
    addTearDown(container.dispose);
    container
        .read(launchLocationProvider.notifier)
        .startAt(Uri.parse('financetracker://nowhere'));
    expect(container.read(launchLocationProvider), isNull);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/accounts',
    );
  });

  testWidgets('a link that reaches the running app goes there', (tester) async {
    await pumpApp(tester, overrides: [storeOverride(seededStore())]);
    final GoRouter router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(goRouterProvider);
    int syncs = 0;
    expect(
      openLaunchLink(
        router,
        Uri.parse('financetracker://plan/bills'),
        sync: () => syncs++,
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(_path(tester), '/bills');
    expect(syncs, 0);
    expect(openLaunchLink(router, syncLink, sync: () => syncs++), isTrue);
    await tester.pumpAndSettle();
    expect(_path(tester), '/settings');
    expect(syncs, 1);
    expect(
      openLaunchLink(
        router,
        Uri.parse('financetracker://nowhere'),
        sync: () => syncs++,
      ),
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(_path(tester), '/settings');
  });

  group('on an expanded window, the two panes', () {
    testWidgets('a bill\'s link shows the bills list beside the bill', (
      tester,
    ) async {
      await pumpApp(
        tester,
        size: expandedSize,
        overrides: [storeOverride(seededStore())],
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await tester.runAsync(
        () => container
            .read(billRepositoryProvider)
            .upsert(
              BillReminder(
                id: 'bill-7',
                name: 'Rent',
                dueDate: LocalDate(2026, 11, 1),
              ),
            ),
      );
      openLaunchLink(
        container.read(goRouterProvider),
        Uri.parse('financetracker://plan/bills/bill-7'),
        sync: () {},
      );
      await tester.pumpAndSettle();
      expect(_path(tester), '/bills/bill-7');
      expect(find.byType(TwoPane), findsOneWidget);
      expect(find.byType(BillsScreen), findsOneWidget);
      expect(find.byType(BillEditorScreen), findsOneWidget);
    });

    testWidgets('Search transactions opens the list beside it searching', (
      tester,
    ) async {
      await pumpApp(
        tester,
        size: expandedSize,
        overrides: [storeOverride(seededStore())],
      );
      openLaunchLink(
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
            .read(goRouterProvider),
        searchLink,
        sync: () {},
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TransactionsScreen),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('Search transactions starts searching; closing goes back', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions?search=true',
      overrides: [storeOverride(seededStore())],
    );
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(_path(tester), '/transactions');
  });

  group('Scan receipt', () {
    late FakeImageSource images;

    setUp(
      () => images = FakeImageSource(
        () async => PickedImage(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9])),
      ),
    );

    testWidgets('opens the camera with the new transaction', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/transactions/new?receipt=camera',
        overrides: [
          storeOverride(seededStore()),
          imageSourceProvider.overrideWithValue(images),
        ],
      );
      expect(images.cameraPicks, 1);
      expect(find.bySemanticsLabel('Receipt image'), findsOneWidget);
    });

    testWidgets('opens the camera in the Add transaction editor already open', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/transactions/new',
        overrides: [
          storeOverride(seededStore()),
          imageSourceProvider.overrideWithValue(images),
        ],
      );
      expect(images.cameraPicks, 0);
      final GoRouter router = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(goRouterProvider);
      openLaunchLink(router, scanReceiptLink, sync: () {});
      await tester.pumpAndSettle();
      expect(images.cameraPicks, 1);
      expect(find.bySemanticsLabel('Receipt image'), findsOneWidget);
    });

    testWidgets('under the lock, opens the camera only once unlocked', (
      tester,
    ) async {
      final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
      await meta.write(AppMetaKeys.lockEnabled, 'true');
      await pumpApp(
        tester,
        initialLocation: '/transactions/new?receipt=camera',
        overrides: [
          storeOverride(seededStore()),
          imageSourceProvider.overrideWithValue(images),
          appMetaStoreProvider.overrideWithValue(meta),
          deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
        ],
      );
      expect(find.byType(LockScreen), findsOneWidget);
      expect(images.cameraPicks, 0);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsNothing);
      expect(images.cameraPicks, 1);
    });
  });
}
