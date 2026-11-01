// The app's own channels to MainActivity: the screen security's setSecure and the
// monotonic clock's elapsedRealtime, as the Kotlin handlers receive and answer them; and
// the flavors' default for "Block screenshots".
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/platform/channel_monotonic_clock.dart';
import 'package:finance_tracker/core/platform/channel_screen_security.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('the screen security sends setSecure with the flag', () async {
    const MethodChannel channel = MethodChannel(
      'dev.tarnan.financetracker/screen_security',
    );
    final List<MethodCall> calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await const ChannelScreenSecurity().set(true);
    await const ChannelScreenSecurity().set(false);

    expect(calls.map((c) => (c.method, c.arguments)), [
      ('setSecure', true),
      ('setSecure', false),
    ]);
  });

  test('the monotonic clock reads elapsedRealtime in milliseconds', () async {
    const MethodChannel channel = MethodChannel(
      'dev.tarnan.financetracker/clock',
    );
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'elapsedRealtime' ? 90061 : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    expect(
      await const ChannelMonotonicClock().elapsed(),
      const Duration(milliseconds: 90061),
    );
  });

  test("screenshots are blocked by default in prod's live mode only", () {
    final AppConfig prod = AppConfig.prod();
    expect(prod.secureScreenDefault, isTrue);
    expect(prod.withChoices(mode: AppMode.live).secureScreenDefault, isTrue);
    expect(prod.withChoices(mode: AppMode.demo).secureScreenDefault, isFalse);
    expect(prod.withChoices(mode: null).secureScreenDefault, isFalse);
    final AppConfig dev = AppConfig.dev();
    for (final AppMode? mode in [AppMode.live, AppMode.demo, null]) {
      expect(dev.withChoices(mode: mode).secureScreenDefault, isFalse);
    }
    expect(AppConfig.demo().secureScreenDefault, isFalse);
  });
}
