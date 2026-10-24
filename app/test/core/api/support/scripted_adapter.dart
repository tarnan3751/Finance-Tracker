// A Dio adapter that answers each request with whatever the test's handler returns, and
// records what was asked: for the client tests that need exact control of the answers
// (the interceptor's races, the problem mapper). The behaviour tests run against the
// in-app fake server instead.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_models/shared_models.dart';

/// One recorded request: method, path (without the base path) and headers.
typedef Recorded = ({String method, String path, Map<String, dynamic> headers});

/// A scripted answer: a status and a JSON body (a problem for a 4xx or 5xx).
typedef Answer = ({int status, Object? body, Map<String, String> headers});

Answer ok(Object? body, [int status = 200]) =>
    (status: status, body: body, headers: const {});

Answer problem(
  int status,
  String code, {
  Map<String, String> headers = const {},
}) => (
  status: status,
  body: {
    'type': 'urn:finance-tracker:problem:$code',
    'title': code,
    'status': status,
    'code': code,
  },
  headers: headers,
);

final class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

  /// Answers a request; throwing a [DioException] fails it without a response.
  FutureOr<Answer> Function(RequestOptions options, Object? body) handler;

  final List<Recorded> requests = [];

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final List<int> bytes = [
        for (final Uint8List chunk in await requestStream.toList()) ...chunk,
      ];
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    }
    final String path = options.uri.path.replaceFirst(RegExp('^/v1'), '');
    requests.add((
      method: options.method,
      path: path,
      headers: Map.of(options.headers),
    ));
    final Answer answer = await handler(options, body);
    return ResponseBody.fromString(
      answer.body == null ? '' : jsonEncode(answer.body),
      answer.status,
      headers: {
        Headers.contentTypeHeader: [
          answer.status >= 400
              ? 'application/problem+json'
              : 'application/json',
        ],
        for (final MapEntry(:key, :value) in answer.headers.entries)
          key: [value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final User testUser = User(
  id: 'user-1',
  email: 'ada@example.com',
  displayName: 'Ada',
  createdAt: DateTime.utc(2026, 10, 1),
);

const Device testDevice = Device(
  id: 'device-1',
  userId: 'user-1',
  name: 'Pixel 6',
);

/// An `AuthTokens` body.
Map<String, Object?> authTokens(String access, String refresh) => {
  'access_token': access,
  'refresh_token': refresh,
  'access_expires_in': 900,
  'device': testDevice.toJson(),
};
