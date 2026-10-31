/// What the background cycle runs after its sync and the reminders
/// (`docs/reference/background.md`, **The cycle**): today's balance snapshots written
/// again (`writeSnapshotsNow`, `features/net_worth/`), then the home screen widgets'
/// snapshot written once (`writeWidgetsNow`, `features/widgets/`), so they show what the
/// sync brought, net worth included, without the app being opened.
library;

import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_hooks.g.dart';

/// One step of the cycle over its container. A failure is logged by type; the cycle
/// goes on.
typedef BackgroundCycleHook = Future<void> Function(
  ProviderContainer container,
);

/// The steps, in order.
@Riverpod(keepAlive: true)
List<BackgroundCycleHook> backgroundCycleHooks(Ref ref) => const [
  writeSnapshotsNow,
  writeWidgetsNow,
];
