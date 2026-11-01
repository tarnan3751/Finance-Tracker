// The entered server URL's rule: an absolute http or https URL with a host and nothing
// after its path; https only in prod; and the address's current server (a compiled URL
// wins, and cannot be edited).
import 'package:finance_tracker/core/api/server_address.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prod takes an https URL, with a path, trimmed', () {
    expect(
      checkServerUrl(' https://money.example.com/ft ', Flavor.prod).url,
      Uri.parse('https://money.example.com/ft'),
    );
    expect(
      checkServerUrl('https://10.0.0.5:8443', Flavor.prod).url,
      Uri.parse('https://10.0.0.5:8443'),
    );
  });

  test('prod refuses http; dev takes it', () {
    expect(
      checkServerUrl('http://money.example.com', Flavor.prod).problem,
      ServerUrlProblem.notHttps,
    );
    expect(
      checkServerUrl('http://10.0.2.2:8080', Flavor.dev).url,
      Uri.parse('http://10.0.2.2:8080'),
    );
  });

  test('anything else is empty or invalid', () {
    expect(checkServerUrl('  ', Flavor.prod).problem, ServerUrlProblem.empty);
    for (final String text in [
      'money.example.com',
      'ftp://money.example.com',
      'https://',
      'https://user:pw@money.example.com',
      'https://money.example.com/?a=1',
      'https://money.example.com/#top',
      'https://money example.com',
    ]) {
      expect(
        checkServerUrl(text, Flavor.dev).problem,
        ServerUrlProblem.invalid,
        reason: text,
      );
    }
  });

  test('a compiled URL wins and cannot be edited', () {
    final ServerAddress compiled = ServerAddress(
      compiled: Uri.parse('https://a.example.com'),
      entered: Uri.parse('https://b.example.com'),
    );
    expect(compiled.editable, isFalse);
    expect(compiled.current, Uri.parse('https://a.example.com'));
    final ServerAddress entered = ServerAddress();
    expect(entered.editable, isTrue);
    expect(entered.current, isNull);
    entered.entered = Uri.parse('https://b.example.com');
    expect(entered.current, Uri.parse('https://b.example.com'));
  });
}
