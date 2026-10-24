/// A Plaid connection to one institution (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'item.freezed.dart';
part 'item.g.dart';

/// A Plaid Item: one login at one institution. The transactions cursor is server-only
/// state and is not part of this model.
@freezed
abstract class Item with _$Item {
  /// An Item. [lastSuccessfulSyncAt] is null before its first successful sync;
  /// [errorCode] is Plaid's error code (`ITEM_LOGIN_REQUIRED`, ...) while [status] is
  /// `loginRequired` or `error`, else null.
  const factory Item({
    required String id,
    required String institutionId,
    @JsonKey(unknownEnumValue: ItemStatus.unknown) required ItemStatus status,
    @UtcInstantConverter() DateTime? lastSuccessfulSyncAt,
    String? errorCode,
  }) = _Item;

  /// Reads the snake_case JSON form.
  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}
