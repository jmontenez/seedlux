import 'package:flutter_test/flutter_test.dart';
import 'package:seedlux/core/calibration.dart';

void main() {
  group('computeCalibrationFactor', () {
    test('capteur lisant moitié trop bas → facteur 2', () {
      expect(
        computeCalibrationFactor(
          referenceLux: sunDirectReferenceLux,
          measuredRawLux: 60000,
        ),
        closeTo(2.0, 1e-9),
      );
    });

    test('capteur juste → facteur 1', () {
      expect(
        computeCalibrationFactor(
          referenceLux: blueSkyReferenceLux,
          measuredRawLux: 20000,
        ),
        closeTo(1.0, 1e-9),
      );
    });

    test('mesure nulle ou négative → ArgumentError', () {
      expect(
        () => computeCalibrationFactor(referenceLux: 1000, measuredRawLux: 0),
        throwsArgumentError,
      );
      expect(
        () => computeCalibrationFactor(referenceLux: 1000, measuredRawLux: -5),
        throwsArgumentError,
      );
    });
  });
}
