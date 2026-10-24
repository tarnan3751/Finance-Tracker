import 'package:cryptography/cryptography.dart';
import 'package:finance_tracker_server/src/plaid/token_cipher.dart';
import 'package:test/test.dart';

void main() {
  final cipher = TokenCipher(List.filled(32, 9));

  test('round-trips, with a fresh nonce each time', () async {
    final a = await cipher.seal('access-sandbox-123', itemId: 'item-1');
    final b = await cipher.seal('access-sandbox-123', itemId: 'item-1');
    expect(a.nonce, hasLength(12));
    expect(a.nonce, isNot(b.nonce));
    expect(a.ciphertext, isNot(b.ciphertext));
    expect(
      await cipher.open(a.ciphertext, nonce: a.nonce, itemId: 'item-1'),
      'access-sandbox-123',
    );
  });

  test('the token is not in the ciphertext', () async {
    final sealed = await cipher.seal('access-sandbox-123', itemId: 'item-1');
    expect(String.fromCharCodes(sealed.ciphertext), isNot(contains('access')));
  });

  test('tampering, another Item or another key fails authentication', () async {
    final sealed = await cipher.seal('access-sandbox-123', itemId: 'item-1');
    final flipped = [...sealed.ciphertext]..[0] ^= 1;
    final throwsAuth = throwsA(isA<SecretBoxAuthenticationError>());
    expect(
      cipher.open(flipped, nonce: sealed.nonce, itemId: 'item-1'),
      throwsAuth,
    );
    final tag = [...sealed.ciphertext]..[sealed.ciphertext.length - 1] ^= 1;
    expect(cipher.open(tag, nonce: sealed.nonce, itemId: 'item-1'), throwsAuth);
    final nonce = [...sealed.nonce]..[0] ^= 1;
    expect(
      cipher.open(sealed.ciphertext, nonce: nonce, itemId: 'item-1'),
      throwsAuth,
    );
    expect(
      cipher.open(sealed.ciphertext, nonce: sealed.nonce, itemId: 'item-2'),
      throwsAuth,
    );
    expect(
      TokenCipher(List.filled(32, 8))
          .open(sealed.ciphertext, nonce: sealed.nonce, itemId: 'item-1'),
      throwsAuth,
    );
  });

  test('a key that is not 32 bytes is refused', () {
    expect(() => TokenCipher(List.filled(16, 1)), throwsArgumentError);
  });
}
