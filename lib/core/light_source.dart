/// Abstraction d'une source de mesure de lumière.
///
/// v0.1 : capteur de luminosité ambiante Android ([AlsLightSource]).
/// v1.1 : caméra iOS via EXIF BrightnessValue (platform channel Swift).
/// v2   : caméra RAW haute précision (Android + iOS, équation ISO 2720).
///
/// Tout le reste de l'app (conversion, calibration, UI) ne dépend que de
/// cette interface : ajouter un mode de mesure = ajouter une implémentation.
abstract interface class LightSource {
  /// Identifiant stable de la source (ex. `als`, `camera`).
  String get id;

  /// Vrai si la source est utilisable sur cet appareil.
  Future<bool> isAvailable();

  /// Flux d'éclairement **brut** en lux, non lissé, non calibré.
  Stream<double> luxStream();

  /// Métadonnées du capteur sous-jacent (diagnostic), null si inconnues.
  Future<SensorInfo?> info();
}

class SensorInfo {
  const SensorInfo({
    required this.name,
    required this.vendor,
    this.resolution,
    this.maxRange,
  });

  final String name;
  final String vendor;

  /// Pas minimal du capteur en lux (révélateur de la quantization).
  final double? resolution;

  /// Valeur maximale mesurable en lux.
  final double? maxRange;
}
