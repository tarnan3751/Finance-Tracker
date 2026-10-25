/// What the developer screen picks from: the stored Items not removed, and an Item's
/// live accounts (`docs/reference/developer.md`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'developer_providers.g.dart';

/// The stored Items the Sandbox controls can act on: every one not `removed`, as
/// `ItemRepository.watchAll` orders them.
@riverpod
Stream<List<LinkedBank>> developerItems(Ref ref) => ref
    .watch(itemRepositoryProvider)
    .watchAll()
    .map(
      (banks) => [
        for (final LinkedBank b in banks)
          if (b.item.status != ItemStatus.removed) b,
      ],
    );

/// Item [itemId]'s live accounts on the device.
@riverpod
Stream<List<Account>> developerItemAccounts(Ref ref, String itemId) => ref
    .watch(accountRepositoryProvider)
    .watchAll()
    .map(
      (accounts) => [
        for (final a in accounts)
          if (a.itemId == itemId) a,
      ],
    );
