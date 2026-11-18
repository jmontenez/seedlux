import 'dart:math' as math;

/// Lissage exponentiel du flux de lux — l'ALS émet à cadence irrégulière et
/// avec du bruit ; la constante de temps [tauSeconds] stabilise l'affichage.
class ExponentialSmoother {
  ExponentialSmoother({this.tauSeconds = 0.8});

  final double tauSeconds;

  double? _value;
  DateTime? _lastAt;

  double get value => _value ?? 0;

  double update(double sample, DateTime now) {
    final previous = _value;
    final lastAt = _lastAt;
    _lastAt = now;
    if (previous == null || lastAt == null) {
      _value = sample;
      return sample;
    }
    final dtSeconds = now.difference(lastAt).inMicroseconds / 1e6;
    final alpha = 1 - math.exp(-math.max(dtSeconds, 0) / tauSeconds);
    final next = previous + alpha * (sample - previous);
    _value = next;
    return next;
  }

  void reset() {
    _value = null;
    _lastAt = null;
  }
}

/// Détecte un ALS grossièrement quantifié (certains téléphones ne remontent
/// que quelques paliers de plusieurs centaines de lux).
///
/// Heuristique : sur la fenêtre récente, très peu de valeurs distinctes alors
/// que la plage couverte est large. Ne se déclenche qu'en lumière variable —
/// une lumière parfaitement stable est indistinguable d'un capteur grossier.
class QuantizationDetector {
  static const _windowSize = 40;
  static const _minSamples = 20;
  static const _maxDistinct = 4;
  static const _minSpanLux = 100.0;

  final List<double> _window = [];

  void add(double rawLux) {
    _window.add(rawLux);
    if (_window.length > _windowSize) {
      _window.removeAt(0);
    }
  }

  bool get isCoarse {
    if (_window.length < _minSamples) return false;
    final distinct = _window.toSet().length;
    final span = _window.reduce(math.max) - _window.reduce(math.min);
    return distinct <= _maxDistinct && span > _minSpanLux;
  }

  void reset() => _window.clear();
}
