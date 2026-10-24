import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('GET /v1/health answers 200 with status ok', () async {
    final response = await buildHandler()(
      Request('GET', Uri.parse('http://localhost/v1/health')),
    );

    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/json');
    expect(jsonDecode(await response.readAsString()), {'status': 'ok'});
  });
}
