/// An entry in the sync outbox (`PLAN.md` §6.2, §6.4).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/entities/hlc.dart';

part 'change_log_entry.freezed.dart';
part 'change_log_entry.g.dart';

/// One change to a user-authored entity, waiting to sync or already synced. [hlc] is
/// unique per node and orders the changes; it serializes as its packed string.
@freezed
abstract class ChangeLogEntry with _$ChangeLogEntry {
  /// An entry; [payload] is the changed fields as JSON.
  const factory ChangeLogEntry({
    required EntityType entityType,
    required String entityId,
    required ChangeOperation operation,
    required Map<String, dynamic> payload,
    @HlcConverter() required Hlc hlc,
    required String deviceId,
    required bool synced,
  }) = _ChangeLogEntry;

  /// Reads the snake_case JSON form.
  factory ChangeLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ChangeLogEntryFromJson(json);
}
