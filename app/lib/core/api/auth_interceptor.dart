/// Bearer tokens and the single-flight refresh (`docs/reference/server.md`, **Tokens**).
///
/// - Every operation the contract secures with `bearerAuth` (the generated client marks
///   it in `RequestOptions.extra['secure']`) gets `Authorization: Bearer` with the stored
///   access token, or with the one the call names (`accessTokenKey`, used while signing
///   in, before a session is stored).
/// - **On 401 `token_expired`** the request waits for one refresh shared by every request
///   that needs it, then is sent again, once. The server rotates refresh tokens with reuse
///   detection and no grace window, so two refreshes with one token would end the
///   session: a refresh starts only when no other is in flight and the stored access token
///   is still the one the failing request carried (otherwise another request already
///   refreshed, and the request is simply sent again with the new token). The stored
///   session is read again from storage first (`TokenStore.reload`), so a refresh the
///   background sync's isolate made is seen rather than repeated with a spent token.
/// - **A refused refresh** (any 401) and **401 `token_revoked`** clear the stored session
///   and fire `onSessionEnded`, but only while the store still holds the tokens the
///   failing call used, so a late answer to an old request cannot end a newer session.
/// - A refresh that fails any other way (a 429, a 5xx, no network) keeps the session; the
///   error reaches the callers. It is never retried here: if it did reach the server and
///   only the answer was lost, a second attempt would present a revoked token.
/// - Nothing is retried after a network error, and logout (`noRefreshKey`) and calls with
///   their own token are never refreshed.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/time/clock.dart';

/// `RequestOptions.extra`: the access token to send instead of the stored one.
const String accessTokenKey = 'ft.accessToken';

/// `RequestOptions.extra`: true for a call that must not be refreshed and sent again.
const String noRefreshKey = 'ft.noRefresh';

const String _sentKey = 'ft.sentAccess';
const String _retriedKey = 'ft.retried';

/// Exchanges a refresh token for a new pair, failing with the raw [DioException].
typedef Refresher = Future<AuthResult> Function(String refreshToken);

/// The problem `code` of [response], or null.
String? problemCodeOf(Response<Object?>? response) {
  final Object? data = response?.data;
  return data is Map && data['code'] is String ? data['code'] as String : null;
}

/// The interceptor. [retryWith] is the Dio a refreshed request is sent again through:
/// the one this interceptor is installed in.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._store,
    required this._refresh,
    required this._clock,
    required this._onSessionEnded,
  });

  final TokenStore _store;
  final Refresher _refresh;
  final Clock _clock;
  final void Function() _onSessionEnded;

  /// The Dio this interceptor is installed in, for sending a request again.
  late Dio retryWith;

  Future<Session?>? _inflight;

  static bool _secured(RequestOptions options) {
    final Object? secure = options.extra['secure'];
    return secure is List && secure.isNotEmpty;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_secured(options)) {
      final String? token =
          options.extra[accessTokenKey] as String? ??
          (await _store.read())?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_sentKey] = token;
      } else {
        options.headers.remove('Authorization');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions options = err.requestOptions;
    final Object? sent = options.extra[_sentKey];
    if (err.response?.statusCode != 401 ||
        !_secured(options) ||
        sent is! String ||
        options.extra[accessTokenKey] != null) {
      handler.next(err);
      return;
    }
    switch (problemCodeOf(err.response)) {
      case 'token_expired'
          when options.extra[noRefreshKey] != true &&
              options.extra[_retriedKey] != true:
        final Session? session;
        try {
          session = await _freshSession(sent);
        } on DioException catch (refreshError) {
          handler.next(refreshError);
          return;
        }
        if (session == null) {
          handler.next(err);
          return;
        }
        options.extra[_retriedKey] = true;
        try {
          handler.resolve(await retryWith.fetch<Object?>(options));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      case 'token_revoked':
        await _endSession(accessToken: sent);
        handler.next(err);
      default:
        handler.next(err);
    }
  }

  /// A session whose access token is newer than [sent]: the one another request already
  /// obtained, or the result of the one refresh in flight, started here if none is.
  Future<Session?> _freshSession(String sent) {
    final Future<Session?>? inflight = _inflight;
    if (inflight != null) return inflight;
    final Completer<Session?> completer = Completer<Session?>();
    // Installed before anything is awaited, so a concurrent caller joins this refresh.
    _inflight = completer.future;
    unawaited(
      _refreshFrom(sent)
          .then(completer.complete, onError: completer.completeError)
          .whenComplete(() => _inflight = null),
    );
    return completer.future;
  }

  Future<Session?> _refreshFrom(String sent) async {
    // Read again from storage: another isolate (the background sync) may have refreshed
    // the session, and its old refresh token is spent.
    final Session? current = await _store.reload();
    if (current == null) return null;
    if (current.accessToken != sent) return current;
    final AuthResult result;
    try {
      result = await _refresh(current.refreshToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _endSession(refreshToken: current.refreshToken);
      }
      rethrow;
    }
    // Written only if the store still holds the pair that was refreshed: a sign-out or
    // a new sign-in while the refresh ran must not be overwritten, and nothing else may
    // land between this check and the write (TokenStore.update).
    Session? next;
    await _store.update((latest) {
      if (latest?.refreshToken != current.refreshToken) return latest;
      return next = Session(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        accessExpiresAt: _clock.nowUtc().add(result.accessExpiresIn),
        user: latest!.user,
        device: result.device,
      );
    });
    return next;
  }

  /// Clears the session if it still holds [accessToken] or [refreshToken], atomically,
  /// and reports it ended.
  Future<void> _endSession({String? accessToken, String? refreshToken}) async {
    bool ended = false;
    await _store.update((latest) {
      if (latest == null) return latest;
      if (accessToken != null && latest.accessToken != accessToken) {
        return latest;
      }
      if (refreshToken != null && latest.refreshToken != refreshToken) {
        return latest;
      }
      ended = true;
      return null;
    });
    if (ended) _onSessionEnded();
  }
}
