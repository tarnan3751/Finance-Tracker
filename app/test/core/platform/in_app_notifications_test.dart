// The in-app notifications: newest first, one per key, at most the limit, with read
// state; the notifier provider adds to them.
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Notifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

BudgetThresholdNotification alert(String budget, {int bp = 8000}) =>
    BudgetThresholdNotification(
      budgetId: budget,
      categoryId: 'c1',
      periodStart: LocalDate(2026, 10, 1),
      thresholdBp: bp,
      spent: Money(8000, 'USD'),
      available: Money(10000, 'USD'),
      raisedAt: DateTime.utc(2026, 10, 24),
    );

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer.test());

  List<(String, bool)> listed() => [
    for (final InAppNotification n in container.read(
      inAppNotificationsProvider,
    ))
      (n.notification.key, n.read),
  ];

  test('the notifier adds unread notifications, newest first', () async {
    final Notifier notifier = container.read(appNotifierProvider);
    await notifier.notify(alert('b1'));
    await notifier.notify(alert('b2'));
    expect(listed(), [
      ('budget/b2/2026-10-01/8000', false),
      ('budget/b1/2026-10-01/8000', false),
    ]);
  });

  test('read state: one by key, or all', () {
    final InAppNotifications list = container.read(
      inAppNotificationsProvider.notifier,
    );
    list
      ..add(alert('b1'))
      ..add(alert('b2'))
      ..markRead('budget/b1/2026-10-01/8000');
    expect(listed(), [
      ('budget/b2/2026-10-01/8000', false),
      ('budget/b1/2026-10-01/8000', true),
    ]);
    list.markAllRead();
    expect(listed().every((n) => n.$2), isTrue);
  });

  test('the same key twice is one notification, and the list is bounded', () {
    final InAppNotifications list = container.read(
      inAppNotificationsProvider.notifier,
    );
    list
      ..add(alert('b1'))
      ..markAllRead()
      ..add(alert('b1'));
    expect(listed(), [('budget/b1/2026-10-01/8000', false)]);
    for (int i = 0; i < inAppNotificationLimit + 5; i++) {
      list.add(alert('n$i'));
    }
    expect(listed(), hasLength(inAppNotificationLimit));
    expect(
      listed().first.$1,
      'budget/n${inAppNotificationLimit + 4}/2026-10-01/8000',
    );
  });
}
