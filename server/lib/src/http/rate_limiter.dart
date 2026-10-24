/// The token bucket on `register`, `login` and `refreshTokens` (`docs/reference/server.md`,
/// **Rate limiting**).
library;

import 'dart:io';

import 'package:shelf/shelf.dart';

/// One bucket per key (the operation and the client IP): [capacity] tokens, refilled at
/// [capacity] per [window], on the server's clock.
final class RateLimiter {
  /// A limiter reading the time from [now].
  RateLimiter({
    required this.now,
    this.capacity = 10,
    this.window = const Duration(minutes: 1),
  });

  /// The server's clock.
  final DateTime Function() now;

  /// Tokens per bucket.
  final int capacity;

  /// The time a full bucket takes to refill.
  final Duration window;

  final Map<String, _Bucket> _buckets = {};

  int get _refillMillis => window.inMilliseconds ~/ capacity;

  /// Takes a token from [key]'s bucket. Returns null when one was available, otherwise
  /// the whole seconds until one is (at least 1).
  int? take(String key) {
    final nowMillis = now().millisecondsSinceEpoch;
    if (_buckets.length > 1000) {
      _buckets.removeWhere(
        (_, b) => nowMillis - b.refilledAt >= window.inMilliseconds,
      );
    }
    final bucket = _buckets.putIfAbsent(
      key,
      () => _Bucket(capacity, nowMillis),
    );
    final earned = (nowMillis - bucket.refilledAt) ~/ _refillMillis;
    if (earned > 0) {
      bucket.tokens = (bucket.tokens + earned).clamp(0, capacity);
      bucket.refilledAt = bucket.tokens == capacity
          ? nowMillis
          : bucket.refilledAt + earned * _refillMillis;
    }
    if (bucket.tokens > 0) {
      bucket.tokens--;
      return null;
    }
    final waitMillis = _refillMillis - (nowMillis - bucket.refilledAt);
    return ((waitMillis + 999) ~/ 1000).clamp(1, window.inSeconds);
  }
}

final class _Bucket {
  _Bucket(this.tokens, this.refilledAt);

  int tokens;
  int refilledAt;
}

/// The client's IP address as the socket reports it (`X-Forwarded-For` is never
/// trusted: nothing proxies the dev server), or `unknown` outside `shelf_io`.
String socketClientIp(Request request) {
  final info = request.context['shelf.io.connection_info'];
  return info is HttpConnectionInfo ? info.remoteAddress.address : 'unknown';
}
