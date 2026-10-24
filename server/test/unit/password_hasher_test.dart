import 'package:cryptography/cryptography.dart';
import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/auth/password_hasher.dart';
import 'package:test/test.dart';

const _small = Argon2Parameters(memoryKib: 64, iterations: 1, parallelism: 1);

void main() {
  test('the Argon2id implementation matches RFC 9106 §5.3', () async {
    final key =
        await Argon2id(
          parallelism: 4,
          memory: 32,
          iterations: 3,
          hashLength: 32,
        ).deriveKey(
          secretKey: SecretKey(List.filled(32, 0x01)),
          nonce: List.filled(16, 0x02),
          optionalSecret: List.filled(8, 0x03),
          associatedData: List.filled(12, 0x04),
        );
    final hex = [
      for (final b in await key.extractBytes())
        b.toRadixString(16).padLeft(2, '0'),
    ].join();
    expect(
      hex,
      '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
    );
  });

  test('hash then verify round-trips through the PHC string', () async {
    final hasher = PasswordHasher(_small);
    final phc = await hasher.hash('correct horse battery');
    expect(
      phc,
      matches(
        RegExp(
          r'^\$argon2id\$v=19\$m=64,t=1,p=1\$[A-Za-z0-9+/]{22}\$[A-Za-z0-9+/]{43}$',
        ),
      ),
    );
    expect(await hasher.verify('correct horse battery', phc), isTrue);
    expect(await hasher.verify('correct horse batterz', phc), isFalse);
    final parsed = PhcHash.parse(phc);
    expect(parsed.salt, hasLength(16));
    expect(parsed.hash, hasLength(32));
    expect(parsed.encode(), phc);
  });

  test('two hashes of one password differ by salt', () async {
    final hasher = PasswordHasher(_small);
    expect(
      await hasher.hash('same password'),
      isNot(await hasher.hash('same password')),
    );
  });

  test('verification reads the parameters from the stored string', () async {
    final old = await PasswordHasher(_small).hash('a password');
    final current = PasswordHasher(
      const Argon2Parameters(memoryKib: 128, iterations: 2, parallelism: 1),
    );
    expect(await current.verify('a password', old), isTrue);
    expect(current.needsRehash(old), isTrue);
    expect(current.needsRehash(await current.hash('a password')), isFalse);
  });

  test('a malformed or tampered PHC string', () async {
    final hasher = PasswordHasher(_small);
    expect(
      () => hasher.verify('x', r'$argon2i$v=19$m=64,t=1,p=1$AAAA$AAAA'),
      throwsFormatException,
    );
    final phc = await hasher.hash('a password');
    final tampered = phc.replaceRange(
      phc.length - 2,
      phc.length,
      phc.endsWith('AA') ? 'BB' : 'AA',
    );
    expect(await hasher.verify('a password', tampered), isFalse);
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}
