// The stream merge on worked examples (docs/reference/recurring.md, **Merging**).
import 'package:finance_tracker/features/recurring/domain/stream_merge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

RecurringStream stream({
  String id = 's1',
  String account = 'acc-1',
  String merchant = 'Netflix',
  RecurringSource source = RecurringSource.detected,
  List<String> ids = const [],
}) => RecurringStream(
  id: id,
  accountId: account,
  merchantName: merchant,
  cadence: RecurringCadence.monthly,
  averageAmount: Money(-1549, 'USD'),
  status: RecurringStatus.active,
  isSubscription: false,
  source: source,
  transactionIds: ids,
);

void main() {
  group('mergeStreams', () {
    test(
      'a detected stream sharing a transaction with a pulled one is dropped',
      () {
        final RecurringStream plaid = stream(
          id: 'p1',
          source: RecurringSource.plaid,
          ids: ['t1', 't2'],
        );
        final RecurringStream overlapping = stream(
          id: 'detected-a',
          ids: ['t2', 't3'],
        );
        final RecurringStream other = stream(
          id: 'detected-b',
          merchant: 'Spotify',
          ids: ['t9'],
        );
        expect(mergeStreams([plaid], [overlapping, other]), [plaid, other]);
      },
    );

    test('a pulled stream without ids covers its account and merchant', () {
      final RecurringStream demo = stream(
        id: 'demo-stream-netflix',
        merchant: 'NETFLIX',
        source: RecurringSource.demo,
      );
      final RecurringStream same = stream(id: 'detected-a', ids: ['t1']);
      final RecurringStream elsewhere = stream(
        id: 'detected-b',
        account: 'acc-2',
        ids: ['t5'],
      );
      expect(mergeStreams([demo], [same, elsewhere]), [demo, elsewhere]);
    });

    test('the result is sorted by merchant name, then id', () {
      final List<RecurringStream> merged = mergeStreams(
        [
          stream(
            id: 'p2',
            merchant: 'Spotify',
            source: RecurringSource.plaid,
            ids: ['x'],
          ),
        ],
        [
          stream(id: 'detected-b', merchant: 'Hulu', ids: ['y']),
          stream(id: 'detected-a', merchant: 'Hulu', ids: ['z']),
        ],
      );
      expect(merged.map((s) => s.id), ['detected-a', 'detected-b', 'p2']);
    });
  });
}
