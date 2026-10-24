/// The name this installation registers itself under: the Android model ("Pixel 6"), or
/// "Android device" when the platform does not say. It is data sent to the server, not
/// interface text, so it is not localized.
library;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_name.g.dart';

/// The name used when the platform gives none.
const String fallbackDeviceName = 'Android device';

/// The device's name, at most 100 characters (the contract's limit).
@Riverpod(keepAlive: true)
Future<String> deviceName(Ref ref) async {
  try {
    final String model = (await DeviceInfoPlugin().androidInfo).model.trim();
    if (model.isEmpty) return fallbackDeviceName;
    final List<int> runes = model.runes.toList();
    return runes.length <= 100 ? model : String.fromCharCodes(runes.take(100));
  } on Object {
    // No platform implementation (a test host), or the platform call failed.
    return fallbackDeviceName;
  }
}
