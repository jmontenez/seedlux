import 'package:flutter_test/flutter_test.dart';
import 'package:seedlux/core/smoothing.dart';

void main() {
  group('ExponentialSmoother', () {
    test('le premier échantillon est retourné tel quel', () {
      final smoother = ExponentialSmoother();
      expect(smoother.update(500, DateTime(2026, 1, 1)), 500);
    });

    test('converge vers une nouvelle valeur stable', () {
      final smoother = ExponentialSmoother(tauSeconds: 0.5);
      var t = DateTime(2026, 1, 1);
      smoother.update(0, t);
      double value = 0;
      for (var i = 0; i < 50; i++) {
        t = t.add(const Duration(milliseconds: 200));
        value = smoother.update(1000, t);
      }
      expect(value, closeTo(1000, 1));
    });

    test('lisse les variations : la sortie reste entre les extrêmes', () {
      final smoother = ExponentialSmoother();
      var t = DateTime(2026, 1, 1);
      smoother.update(100, t);
      t = t.add(const Duration(milliseconds: 100));
      final smoothed = smoother.update(1000, t);
      expect(smoothed, greaterThan(100));
      expect(smoothed, lessThan(1000));
    });
  });

  group('QuantizationDetector', () {
    test('gros paliers sur plage large → capteur grossier', () {
      final detector = QuantizationDetector();
      for (var i = 0; i < 30; i++) {
        detector.add([0.0, 300.0, 600.0][i % 3]);
      }
      expect(detector.isCoarse, isTrue);
    });

    test('valeurs continues → capteur fin', () {
      final detector = QuantizationDetector();
      for (var i = 0; i < 30; i++) {
        detector.add(100.0 + i * 7.3);
      }
      expect(detector.isCoarse, isFalse);
    });

    test('lumière stable → pas de faux positif', () {
      final detector = QuantizationDetector();
      for (var i = 0; i < 30; i++) {
        detector.add(450);
      }
      expect(detector.isCoarse, isFalse);
    });

    test('pas de verdict avant assez d\'échantillons', () {
      final detector = QuantizationDetector();
      detector.add(0);
      detector.add(600);
      expect(detector.isCoarse, isFalse);
    });
  });
}
