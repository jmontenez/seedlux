import 'package:shared_preferences/shared_preferences.dart';

import 'conversion.dart';

/// Références de calibration « gratuites » (méthode du whitepaper Photone) :
/// soleil direct de midi par ciel clair, ou capteur pointé vers le bleu du
/// ciel. Valables partout, à ±quelques % près selon saison/latitude.
const double sunDirectReferenceLux = 120000;
const double blueSkyReferenceLux = 20000;

/// Calibration single-point : facteur d'échelle appliqué au lux brut,
/// calculé une fois contre une référence connue.
double computeCalibrationFactor({
  required double referenceLux,
  required double measuredRawLux,
}) {
  if (measuredRawLux <= 0) {
    throw ArgumentError.value(
      measuredRawLux,
      'measuredRawLux',
      'La mesure doit être strictement positive pour calibrer.',
    );
  }
  return referenceLux / measuredRawLux;
}

/// Préférences persistées de l'app (calibration, préset, photopériode…).
class AppPrefs {
  AppPrefs(this._prefs);

  static const _kCalibrationFactor = 'calibration_factor';
  static const _kPreset = 'spectrum_preset';
  static const _kPhotoperiodHours = 'photoperiod_hours';
  static const _kLastUpdateCheck = 'last_update_check_epoch_ms';

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async =>
      AppPrefs(await SharedPreferences.getInstance());

  double get calibrationFactor => _prefs.getDouble(_kCalibrationFactor) ?? 1.0;

  Future<void> setCalibrationFactor(double value) =>
      _prefs.setDouble(_kCalibrationFactor, value);

  SpectrumPreset get preset {
    final name = _prefs.getString(_kPreset);
    return SpectrumPreset.values.asNameMap()[name] ??
        SpectrumPreset.ledFullSpectrum;
  }

  Future<void> setPreset(SpectrumPreset value) =>
      _prefs.setString(_kPreset, value.name);

  double get photoperiodHours => _prefs.getDouble(_kPhotoperiodHours) ?? 12;

  Future<void> setPhotoperiodHours(double value) =>
      _prefs.setDouble(_kPhotoperiodHours, value);

  DateTime? get lastUpdateCheck {
    final ms = _prefs.getInt(_kLastUpdateCheck);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastUpdateCheck(DateTime value) =>
      _prefs.setInt(_kLastUpdateCheck, value.millisecondsSinceEpoch);
}
