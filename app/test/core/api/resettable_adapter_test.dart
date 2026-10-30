// The resettable adapter: requests go to the current pool; a reset closes the old one
// without force (a request in flight finishes) and sends what follows to a new one; and
// the API's Dio has its send timeout.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Pool implements HttpClientAdapter {
  _Pool(this.id);

  final int id;
  int fetches = 0;
  bool? closedWithForce;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetches++;
    return ResponseBody.fromString('$id', 200);
  }

  @override
  void close({bool force = false}) => closedWithForce = force;
}

void main() {
  test(
    'a reset closes the old pool without force and opens a new one',
    () async {
      final List<_Pool> pools = [];
      final ResettableHttpClientAdapter adapter = ResettableHttpClientAdapter(
        () {
          final _Pool pool = _Pool(pools.length);
          pools.add(pool);
          return pool;
        },
      );
      final Dio dio = Dio()..httpClientAdapter = adapter;
      expect((await dio.get<String>('http://x.test/')).data, '0');
      adapter.reset();
      expect(pools.first.closedWithForce, isFalse);
      expect((await dio.get<String>('http://x.test/')).data, '1');
      expect([for (final p in pools) p.fetches], [1, 1]);
      adapter.close(force: true);
      expect(pools.last.closedWithForce, isTrue);
    },
  );

  test("the API's Dio times out a body it cannot send in 30 s", () {
    final Dio dio = buildDio(AppConfig.dev(), version: () async => '1');
    expect(dio.options.sendTimeout, const Duration(seconds: 30));
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
  });
}
