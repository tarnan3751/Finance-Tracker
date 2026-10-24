/// "Today" for screens that stay open: the clock's local date, re-read at every local
/// midnight and whenever the app comes back to the foreground, so a list left open over
/// midnight relabels its "Today" and "Yesterday" and moves its date presets.
library;

import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

part 'today_provider.g.dart';

/// The clock's local date, kept current: a timer fires at the next local midnight in the
/// clock's zone (rescheduled after it fires), and an app resume re-reads it too.
@Riverpod(keepAlive: true)
class Today extends _$Today {
  Timer? _timer;

  @override
  LocalDate build() {
    final Clock clock = ref.watch(clockProvider);
    final AppLifecycleListener lifecycle = AppLifecycleListener(
      onResume: () => _update(clock),
    );
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });
    _schedule(clock);
    return clock.today();
  }

  void _update(Clock clock) {
    state = clock.today();
    _schedule(clock);
  }

  void _schedule(Clock clock) {
    _timer?.cancel();
    _timer = Timer(untilNextLocalMidnight(clock), () => _update(clock));
  }
}

/// The time from [clock]'s now to the start of the next local day in its zone (on a day
/// whose midnight a DST change skips, to the first instant of that day).
Duration untilNextLocalMidnight(Clock clock) {
  final tz.TZDateTime now = tz.TZDateTime.from(clock.nowUtc(), clock.location);
  final tz.TZDateTime next = tz.TZDateTime(
    clock.location,
    now.year,
    now.month,
    now.day + 1,
  );
  return next.difference(now);
}
