/// The Dio adapter in front of `FakeServer`: it turns a request into a `FakeRequest`
/// (the path without `/v1`, the query, the headers, the body decoded from JSON, or its
/// bytes for an image body) and the server's answer into a response body (JSON, or image
/// bytes for a `Uint8List` body, PNG unless the answer names its type), so
/// everything above the adapter (the generated client, its serializers, the interceptors)
/// runs exactly as against a real server.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';

/// The adapter.
final class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._server);

  final FakeServer _server;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final List<int> bytes = [
      if (requestStream != null)
        for (final Uint8List chunk in await requestStream.toList()) ...chunk,
    ];
    Object? body;
    final bool image =
        '${options.headers[Headers.contentTypeHeader] ?? options.contentType ?? ''}'
            .toLowerCase()
            .startsWith('image/');
    if (image) {
      body = Uint8List.fromList(bytes);
    } else if (bytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(bytes));
      } on FormatException {
        body = invalidJson;
      }
    }
    final Uri uri = options.uri;
    final String path = uri.path.startsWith('/v1/')
        ? uri.path.substring(3)
        : '/not-under-v1${uri.path}';
    final String? operationId = FakeServer.match(
      options.method,
      path,
    )?.route.operationId;
    if (_server.latency > Duration.zero) {
      await Future<void>.delayed(_server.latency);
    }
    if (operationId != null && _server.takeNetworkFailure(operationId)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'the fake server dropped the connection',
      );
    }
    final FakeResponse response = await _server.handle((
      method: options.method,
      path: path,
      query: uri.queryParameters,
      headers: {
        for (final MapEntry(:key, :value) in options.headers.entries)
          key.toLowerCase(): '$value',
      },
      body: body,
    ));
    if (response.body case final Uint8List bytes) {
      final Map<String, List<String>> headers = {
        for (final MapEntry(:key, :value) in response.headers.entries)
          key.toLowerCase(): [value],
      };
      headers[Headers.contentTypeHeader] ??= ['image/png'];
      return ResponseBody.fromBytes(bytes, response.status, headers: headers);
    }
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        if (response.body != null)
          Headers.contentTypeHeader: [
            response.status >= 400
                ? 'application/problem+json'
                : 'application/json',
          ],
        for (final MapEntry(:key, :value) in response.headers.entries)
          key.toLowerCase(): [value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
