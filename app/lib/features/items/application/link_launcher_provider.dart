/// Which [LinkLauncher] opens Plaid Link: `plaid_flutter` by default (dev and prod on
/// the network), the fake launcher wherever the in-app fake server runs (the demo
/// flavor, `FT_FAKE_SERVER`, the tests), through `fakeApiOverrides`.
library;

import 'package:finance_tracker/features/items/data/plaid_flutter_link_launcher.dart';
import 'package:finance_tracker/features/items/domain/link_launcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'link_launcher_provider.g.dart';

/// The Link launcher.
@Riverpod(keepAlive: true)
LinkLauncher linkLauncher(Ref ref) => PlaidFlutterLinkLauncher();
