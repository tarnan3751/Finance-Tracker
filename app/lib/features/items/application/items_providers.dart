/// The linked banks the screen shows (`docs/reference/items.md`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'items_providers.g.dart';

/// The stored Items, as `ItemRepository.watchAll` orders them; an Item unlinked with its
/// history kept (`removed`) only while one of its accounts is still live on the device.
@riverpod
Stream<List<LinkedBank>> linkedBanks(Ref ref) async* {
  final Set<String> linkedItems = {
    for (final Account a in await ref.watch(_liveAccountsProvider.future))
      ?a.itemId,
  };
  yield* ref
      .watch(itemRepositoryProvider)
      .watchAll()
      .map(
        (banks) => [
          for (final LinkedBank b in banks)
            if (b.item.status != ItemStatus.removed ||
                linkedItems.contains(b.id))
              b,
        ],
      );
}

@riverpod
Stream<List<Account>> _liveAccounts(Ref ref) =>
    ref.watch(accountRepositoryProvider).watchAll();
