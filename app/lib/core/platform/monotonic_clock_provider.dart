/// Which [MonotonicClock] measures elapsed time: the fake by default (the tests), the
/// app's channel in every flavor (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/monotonic_clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monotonic_clock_provider.g.dart';

/// The monotonic clock.
@Riverpod(keepAlive: true)
MonotonicClock monotonicClock(Ref ref) => FakeMonotonicClock();
