import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  test('GET /health answers ok and the contract version', () async {
    final server = await TestServer.start();
    final r = await server.call('get', '/health');
    expect(r.status, 200);
    expect(r.json, {'status': 'ok', 'version': contractVersion});
  });

  test('the server implements the contract version the document declares', () {
    final info = contract.root['info']! as Map<String, Object?>;
    expect(contractVersion, info['version']);
  });
}
