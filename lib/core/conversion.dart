/// Conversion lux → PPFD (µmol·m⁻²·s⁻¹) par type de spectre.
///
/// Il n'existe PAS de conversion universelle : un luxmètre pondère la lumière
/// selon la sensibilité de l'œil humain (courbe V(λ)), le PPFD compte les
/// photons 400–700 nm à plat. Le facteur dépend donc du spectre de la source.
///
/// Facteurs exprimés en lux par µmol·m⁻²·s⁻¹, issus des notes techniques
/// Apogee Instruments (« Conversion: lux to PPFD ») et de la littérature
/// horticole.
library;

enum SpectrumPreset {
  sun,
  ledFullSpectrum,
  hps,
  metalHalide,
  fluorescent,
  ledRedBlue,
}

class Spectrum {
  const Spectrum({required this.label, required this.luxPerUmol, this.note});

  /// Libellé affiché dans l'UI.
  final String label;

  /// Lux mesurés pour 1 µmol·m⁻²·s⁻¹ sous ce spectre.
  final double luxPerUmol;

  /// Avertissement optionnel affiché quand le préset est sélectionné.
  final String? note;
}

const Map<SpectrumPreset, Spectrum> spectra = {
  // Apogee : soleil ≈ 0,0185 µmol par lux → 54 lux/µmol.
  SpectrumPreset.sun: Spectrum(label: 'Soleil', luxPerUmol: 54),
  // LED blanches horticoles 3000–5700 K : 60–70 selon le modèle.
  SpectrumPreset.ledFullSpectrum: Spectrum(
    label: 'LED blanche',
    luxPerUmol: 66,
    note:
        'LED blanches (full spectrum) : facteur réel entre 60 et 70 '
        'selon le modèle. Les LED enrichies en rouge 660 nm lisent plus bas.',
  ),
  // Apogee : HPS ≈ 0,0122 µmol par lux → 82 lux/µmol.
  SpectrumPreset.hps: Spectrum(label: 'HPS (sodium)', luxPerUmol: 82),
  // Apogee : MH ≈ 0,0141 µmol par lux → 71 lux/µmol.
  SpectrumPreset.metalHalide: Spectrum(
    label: 'MH (halogénures)',
    luxPerUmol: 71,
  ),
  // Tubes fluo blancs (T5) : ≈ 74 lux/µmol.
  SpectrumPreset.fluorescent: Spectrum(
    label: 'Fluorescent (T5)',
    luxPerUmol: 74,
  ),
  // Le rouge 660 nm et le bleu 450 nm sont quasi invisibles pour un luxmètre
  // (V(660) ≈ 0,06, V(450) ≈ 0,04) : facteur très bas ET très incertain.
  SpectrumPreset.ledRedBlue: Spectrum(
    label: 'LED rouge/bleu',
    luxPerUmol: 10,
    note:
        'Spectre rouge/bleu (« blurple ») : facteur très approximatif '
        '(7–14 selon le ratio). Un capteur de lux est un mauvais instrument '
        'pour ce type de lampe — valeur indicative seulement.',
  ),
};

/// Convertit un éclairement (lux, déjà calibré) en PPFD estimé.
double luxToPpfd(double lux, SpectrumPreset preset) =>
    lux / spectra[preset]!.luxPerUmol;
