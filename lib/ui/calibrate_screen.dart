import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/calibration.dart';
import '../core/light_source.dart';
import '../core/smoothing.dart';

enum _Reference { sunDirect, blueSky, manual }

/// Calibration single-point (méthode Photone) : on mesure une référence
/// connue et on en déduit un facteur d'échelle appliqué au lux brut.
class CalibrateScreen extends StatefulWidget {
  const CalibrateScreen({super.key, required this.prefs, required this.source});

  final AppPrefs prefs;
  final LightSource source;

  @override
  State<CalibrateScreen> createState() => _CalibrateScreenState();
}

class _CalibrateScreenState extends State<CalibrateScreen> {
  final _smoother = ExponentialSmoother(tauSeconds: 1.5);
  final _manualController = TextEditingController();

  StreamSubscription<double>? _subscription;
  double _rawLux = 0;
  _Reference _reference = _Reference.sunDirect;

  @override
  void initState() {
    super.initState();
    _subscription = widget.source.luxStream().listen((lux) {
      if (!mounted) return;
      setState(() => _rawLux = _smoother.update(lux, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _manualController.dispose();
    super.dispose();
  }

  double? get _referenceLux => switch (_reference) {
    _Reference.sunDirect => sunDirectReferenceLux,
    _Reference.blueSky => blueSkyReferenceLux,
    _Reference.manual => double.tryParse(
      _manualController.text.replaceAll(',', '.'),
    ),
  };

  Future<void> _calibrate() async {
    final reference = _referenceLux;
    final messenger = ScaffoldMessenger.of(context);
    if (reference == null || reference <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Entrez une valeur de référence valide.')),
      );
      return;
    }
    if (_rawLux <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Mesure nulle : exposez le capteur à la source de référence.',
          ),
        ),
      );
      return;
    }

    final factor = computeCalibrationFactor(
      referenceLux: reference,
      measuredRawLux: _rawLux,
    );

    // Un facteur très éloigné de 1 signale presque toujours une mauvaise
    // condition de mesure (ombre, mauvaise référence) plutôt qu'un capteur
    // réellement décalé d'autant.
    if (factor < 0.2 || factor > 5) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Facteur inhabituel'),
          content: Text(
            'Le facteur calculé est ×${factor.toStringAsFixed(2)}, ce qui '
            'est très éloigné de 1. Vérifiez les conditions (plein soleil '
            'sans ombre, capteur bien orienté). Appliquer quand même ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await widget.prefs.setCalibrationFactor(factor);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Calibration appliquée : ×${factor.toStringAsFixed(3)}'),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _reset() async {
    await widget.prefs.setCalibrationFactor(1.0);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibration réinitialisée (×1,0).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factor = widget.prefs.calibrationFactor;

    return Scaffold(
      appBar: AppBar(title: const Text('Calibrer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Placez le capteur (bord supérieur du téléphone) face à une '
            'source dont la valeur est connue, attendez que la mesure se '
            'stabilise, puis appliquez.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Mesure brute actuelle',
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    '${_rawLux.round()} lux',
                    style: theme.textTheme.displaySmall,
                  ),
                  Text(
                    'calibration actuelle : ×${factor.toStringAsFixed(3)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Référence', style: theme.textTheme.titleMedium),
          RadioGroup<_Reference>(
            groupValue: _reference,
            onChanged: (v) => setState(() => _reference = v!),
            child: const Column(
              children: [
                RadioListTile<_Reference>(
                  value: _Reference.sunDirect,
                  title: Text('Plein soleil (~120 000 lux)'),
                  subtitle: Text(
                    'Midi ±2 h, ciel parfaitement dégagé, téléphone à plat '
                    'vers le ciel, sans aucune ombre.',
                  ),
                ),
                RadioListTile<_Reference>(
                  value: _Reference.blueSky,
                  title: Text('Bleu du ciel (~20 000 lux)'),
                  subtitle: Text(
                    'Capteur pointé vers le bleu du ciel (pas vers le '
                    'soleil), ciel dégagé.',
                  ),
                ),
                RadioListTile<_Reference>(
                  value: _Reference.manual,
                  title: Text('Valeur manuelle (luxmètre de référence)'),
                ),
              ],
            ),
          ),
          if (_reference == _Reference.manual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _manualController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Référence en lux',
                  hintText: 'ex. 35200',
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _calibrate,
            icon: const Icon(Icons.check),
            label: const Text('Appliquer la calibration'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: factor == 1.0 ? null : _reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Réinitialiser (×1,0)'),
          ),
        ],
      ),
    );
  }
}
