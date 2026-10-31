import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/services.dart' show appFlavor;

Future<void> main() {
  // `--flavor` and this entry point must agree (`build.md`): the developer tools are
  // compiled in by the one (`kDevTools`) and shown by the other. No flavor: a host test.
  assert(
    appFlavor == null || appFlavor == 'demo',
    'built with --flavor $appFlavor but started as demo',
  );
  return bootstrap(AppConfig.demo());
}
