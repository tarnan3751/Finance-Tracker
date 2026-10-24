/// A financial institution as Plaid names it (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'institution.freezed.dart';
part 'institution.g.dart';

/// A bank or other institution. Plaid does not always provide a logo or a colour
/// (`PLAN.md` §7.1), so both are optional and the app's enrichment fallback fills in.
@freezed
abstract class Institution with _$Institution {
  /// An institution; [id] is Plaid's institution id and [primaryColor] is ARGB.
  const factory Institution({
    required String id,
    required String name,
    Uri? logoUrl,
    int? primaryColor,
  }) = _Institution;

  /// Reads the snake_case JSON form.
  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);
}
