// A FinanceApi that serves receipt photos from a map, with scripted failures, for the
// receipt fetch's tests; every other operation is unsupported.
import 'dart:typed_data';

import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';

/// Receipt photos by hash; [failures] answer the next fetches in order.
final class ReceiptApi implements FinanceApi {
  final Map<String, Uint8List> photos = {};
  final List<ApiException> failures = [];

  /// The hashes fetched, in order.
  final List<String> fetched = [];

  @override
  Future<Uint8List> getReceipt(String sha256) async {
    fetched.add(sha256);
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return photos[sha256] ?? (throw const NotFound(status: 404));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
