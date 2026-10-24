// The settings screen's Sync section: what each status shows, "Sync now", and that the
// demo flavor has no Sync section.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/pump_app.dart';

/// A controller fixed at a status, calling [_onSync] for "Sync now".
final class _FixedSync extends SyncController {
  _FixedSync(this._status, [this._onSync]);

  final SyncStatus _status;
  final void Function()? _onSync;

  @override
  SyncStatus build() => _status;

  @override
  Future<void> syncNow() async => _onSync?.call();
}

void main() {
  testWidgets(
    'with no session for sync, it asks to sign in and offers no Sync now',
    (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/settings',
        overrides: [
          localDataSyncsProvider.overrideWithValue(true),
          syncDeviceIdProvider.overrideWithValue(null),
        ],
      );
      expect(find.text('Sync'), findsOneWidget);
      expect(
        find.text('Sign in to sync your data between devices'),
        findsOneWidget,
      );
      expect(find.text('Sync now'), findsNothing);
    },
  );

  testWidgets(
    'signed in, it shows the last sync, the outbox and what is held back',
    (tester) async {
      int syncs = 0;
      final _FixedSync controller = _FixedSync(
        SyncStatus(
          phase: SyncPhase.idle,
          // 24 October 2026, 15:00 UTC; the test clock's zone is UTC.
          lastSyncAt: DateTime.utc(2026, 10, 24, 15),
          lastSummary: const SyncSummary(
            pushed: 1,
            pulled: 0,
            applied: 0,
            rejectedForGood: 2,
            clockDrift: 1,
            pullBlocked: false,
          ),
          ledger: (
            pending: 3,
            rejected: 2,
            lastRejected: Hlc(
              DateTime.utc(2026, 10, 23, 9).millisecondsSinceEpoch,
              0,
              'd',
            ),
            held: 1,
          ),
        ),
        () => syncs++,
      );
      await pumpApp(
        tester,
        initialLocation: '/settings',
        size: const Size(412, 1400),
        overrides: [syncControllerProvider.overrideWith(() => controller)],
      );
      // intl puts a narrow no-break space before the day period.
      expect(
        find.text('Last synced Oct 24, 2026 3:00\u202fPM'),
        findsOneWidget,
      );
      expect(find.text('3 changes waiting to sync'), findsOneWidget);
      expect(
        find.text(
          "A device's clock is far ahead, so some changes wait until it catches up",
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '2 changes were refused by the server, the latest made Oct 23, 2026 9:00\u202fAM',
        ),
        findsOneWidget,
      );
      expect(
        find.text('1 synced record this version of the app cannot show yet'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Sync now'));
      await tester.pump();
      expect(syncs, 1);
    },
  );

  testWidgets('the signed-in section lays out at text scale 2', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      textScale: 2,
      overrides: [
        syncControllerProvider.overrideWith(
          () => _FixedSync(
            SyncStatus(
              phase: SyncPhase.idle,
              lastSyncAt: DateTime.utc(2026, 10, 24, 15),
              ledger: (pending: 12, rejected: 0, lastRejected: null, held: 4),
            ),
          ),
        ),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed sync says so', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        syncControllerProvider.overrideWith(
          () => _FixedSync(
            const SyncStatus(
              phase: SyncPhase.idle,
              failure: SyncFailure.offline,
            ),
          ),
        ),
      ],
    );
    expect(
      find.text('The last sync could not reach the server'),
      findsOneWidget,
    );
  });

  testWidgets('Sync now waits while a session runs', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        syncControllerProvider.overrideWith(
          () => _FixedSync(const SyncStatus(phase: SyncPhase.running)),
        ),
      ],
    );
    expect(find.text('Syncing…'), findsOneWidget);
    final ButtonStyleButton button = tester.widget(
      find.ancestor(
        of: find.text('Sync now'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('in-memory data has no Sync section', (tester) async {
    await pumpApp(tester, initialLocation: '/settings');
    expect(find.text('Sync'), findsNothing);
  });

  testWidgets('the demo flavor has no Sync section', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      config: AppConfig.demo(),
    );
    expect(find.text('Sync'), findsNothing);
  });
}
