import 'package:flutter_test/flutter_test.dart';
import 'package:seedlux/update/updater.dart';

void main() {
  group('isNewerVersion', () {
    test('versions strictement supérieures', () {
      expect(isNewerVersion('0.2.0', '0.1.0'), isTrue);
      expect(isNewerVersion('0.1.1', '0.1.0'), isTrue);
      expect(isNewerVersion('1.0.0', '0.9.9'), isTrue);
      expect(isNewerVersion('10.0.0', '9.0.0'), isTrue);
    });

    test('versions égales ou inférieures', () {
      expect(isNewerVersion('0.1.0', '0.1.0'), isFalse);
      expect(isNewerVersion('0.1.0', '0.1.1'), isFalse);
      expect(isNewerVersion('0.9.9', '1.0.0'), isFalse);
    });

    test('suffixes de build ignorés', () {
      expect(isNewerVersion('0.2.0', '0.1.0+5'), isTrue);
      expect(isNewerVersion('0.1.0+9', '0.1.0+1'), isFalse);
      expect(isNewerVersion('0.2.0-beta', '0.1.0'), isTrue);
    });

    test('composants manquants traités comme 0', () {
      expect(isNewerVersion('1.0', '0.9.9'), isTrue);
      expect(isNewerVersion('1', '1.0.0'), isFalse);
    });
  });
}
