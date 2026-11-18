import 'package:flutter_test/flutter_test.dart';
import 'package:seedlux/core/conversion.dart';
import 'package:seedlux/core/dli.dart';

void main() {
  group('luxToPpfd', () {
    test('plein soleil : 54 000 lux ≈ 1 000 µmol/m²/s', () {
      expect(luxToPpfd(54000, SpectrumPreset.sun), closeTo(1000, 0.01));
    });

    test('HPS : 82 000 lux ≈ 1 000 µmol/m²/s', () {
      expect(luxToPpfd(82000, SpectrumPreset.hps), closeTo(1000, 0.01));
    });

    test('zéro lux → zéro PPFD pour tous les présets', () {
      for (final preset in SpectrumPreset.values) {
        expect(luxToPpfd(0, preset), 0);
      }
    });

    test('la table couvre tous les présets, avec des facteurs > 0', () {
      for (final preset in SpectrumPreset.values) {
        final spectrum = spectra[preset];
        expect(spectrum, isNotNull, reason: 'préset manquant : $preset');
        expect(spectrum!.luxPerUmol, greaterThan(0));
        expect(spectrum.label, isNotEmpty);
      }
    });
  });

  group('dli', () {
    test('500 µmol/m²/s sur 12 h = 21,6 mol/m²/j', () {
      expect(dli(500, 12), closeTo(21.6, 0.001));
    });

    test('photopériode nulle → DLI nul', () {
      expect(dli(1000, 0), 0);
    });
  });
}
