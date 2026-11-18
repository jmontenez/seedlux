import 'package:flutter/services.dart';

import 'light_source.dart';

/// Capteur de luminosité ambiante Android (`Sensor.TYPE_LIGHT`), exposé par
/// le platform channel de `MainActivity.kt`.
///
/// Précision très variable selon le modèle de téléphone : certains ALS sont
/// quantifiés par gros paliers — l'UI avertit via `QuantizationDetector`.
class AlsLightSource implements LightSource {
  static const _info = MethodChannel('seedlux/light/info');
  static const _stream = EventChannel('seedlux/light/stream');

  @override
  String get id => 'als';

  @override
  Future<bool> isAvailable() async {
    try {
      return await _info.invokeMethod<bool>('hasSensor') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Plateforme sans ce channel (ex. iOS avant la v1.1).
      return false;
    }
  }

  @override
  Stream<double> luxStream() =>
      _stream.receiveBroadcastStream().map((lux) => (lux as num).toDouble());

  @override
  Future<SensorInfo?> info() async {
    try {
      final raw = await _info.invokeMethod<Map<Object?, Object?>>('sensorInfo');
      if (raw == null) return null;
      return SensorInfo(
        name: raw['name'] as String? ?? 'inconnu',
        vendor: raw['vendor'] as String? ?? 'inconnu',
        resolution: (raw['resolution'] as num?)?.toDouble(),
        maxRange: (raw['maxRange'] as num?)?.toDouble(),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
