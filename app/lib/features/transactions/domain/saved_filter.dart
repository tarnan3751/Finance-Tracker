/// A saved set of the transaction list's filters (`docs/reference/transactions.md`,
/// **Saved filters**). Pure Dart.
library;

import 'dart:convert';

/// The filters saved under [name]. [filters] is the JSON object of the list's
/// `TransactionFilters`, which the application layer writes and reads; here it is opaque.
final class SavedFilter {
  /// A saved filter; [filters] is copied, unmodifiable.
  SavedFilter({
    required this.id,
    required this.name,
    required this.position,
    required Map<String, Object?> filters,
  }) : filters = Map.unmodifiable(filters);

  final String id;
  final String name;

  /// Where it is listed: ascending, then by id.
  final int position;
  final Map<String, Object?> filters;

  @override
  bool operator ==(Object other) =>
      other is SavedFilter &&
      other.id == id &&
      other.name == name &&
      other.position == position &&
      jsonEncode(other.filters) == jsonEncode(filters);

  @override
  int get hashCode => Object.hash(id, name, position, jsonEncode(filters));

  @override
  String toString() => 'SavedFilter($id, position: $position)';
}
