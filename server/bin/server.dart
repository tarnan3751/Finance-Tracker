/// Starts the development server on localhost, port 8080 or `PORT` when set.
///
/// The Phase 0 skeleton reads no other environment and no `.env` file; Phase 2 adds the
/// configuration the real server needs (`.env.example`). Stop it with Ctrl-C.
library;

import 'dart:io';

import 'package:finance_tracker_server/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(
    buildHandler(),
    InternetAddress.loopbackIPv4,
    port,
  );
  stdout.writeln('Serving on http://${server.address.host}:${server.port}');
}
