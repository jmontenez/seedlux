import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/calibration.dart';
import '../core/conversion.dart';
import '../core/dli.dart';
import '../core/light_source.dart';
import '../core/smoothing.dart';
import '../update/update_ui.dart';
import '../update/updater.dart';
import 'calibrate_screen.dart';
import 'settings_screen.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key, required this.prefs, required this.source});

  final AppPrefs prefs;
  final LightSource source;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  static const _autoCheckInterval = Duration(hours: 20);

  final _smoother = ExponentialSmoother();
  final _quantization = QuantizationDetector();
  final _updater = Updater();

  StreamSubscription<double>? _subscription;
  bool? _sensorAvailable;
  double _rawLux = 0;
  double _smoothedRawLux = 0;
  double _maxPpfd = 0;
  bool _hold = false;

  @override
  void initState() {
    super.initState();
    _start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheckUpdates());
  }

  Future<void> _start() async {
    final available = await widget.source.isAvailable();
    if (!mounted) return;
    setState(() => _sensorAvailable = available);
    if (!available) return;
    _subscription = widget.source.luxStream().listen((lux) {
      if (!mounted || _hold) return;
      _quantization.add(lux);
      setState(() {
        _rawLux = lux;
        _smoothedRawLux = _smoother.update(lux, DateTime.now());
        _maxPpfd = math.max(_maxPpfd, _currentPpfd);
      });
    });
  }

  Future<void> _autoCheckUpdates() async {
    final last = widget.prefs.lastUpdateCheck;
    final now = DateTime.now();
    if (last != null && now.difference(last) < _autoCheckInterval) return;
    await widget.prefs.setLastUpdateCheck(now);
    if (!mounted) return;
    await checkForUpdatesInteractive(context, updater: _updater);
  }

  double get _calibratedLux => _smoothedRawLux * widget.prefs.calibrationFactor;

  double get _currentPpfd => luxToPpfd(_calibratedLux, widget.prefs.preset);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _openCalibration() async {
    _subscription?.pause();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CalibrateScreen(prefs: widget.prefs, source: widget.source),
      ),
    );
    _subscription?.resume();
    if (mounted) setState(() => _maxPpfd = 0);
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SettingsScreen(prefs: widget.prefs, source: widget.source),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = widget.prefs.preset;
    final spectrum = spectra[preset]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seedlux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Calibrer',
            onPressed: _openCalibration,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Réglages',
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: _sensorAvailable == true
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _hold = !_hold),
              icon: Icon(_hold ? Icons.play_arrow : Icons.pause),
              label: Text(_hold ? 'Reprendre' : 'Figer'),
            )
          : null,
      body: switch (_sensorAvailable) {
        null => const Center(child: CircularProgressIndicator()),
        false => const _NoSensorMessage(),
        true => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PresetSelector(
              selected: preset,
              onChanged: (p) async {
                await widget.prefs.setPreset(p);
                if (mounted) setState(() => _maxPpfd = 0);
              },
            ),
            if (spectrum.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  spectrum.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            if (_quantization.isCoarse)
              Card(
                color: theme.colorScheme.errorContainer,
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Capteur peu précis détecté : votre téléphone remonte '
                    'la lumière par gros paliers. Les valeurs sont '
                    'indicatives.',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    _currentPpfd.round().toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 96,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _hold ? theme.colorScheme.tertiary : null,
                    ),
                  ),
                  Text('PPFD — µmol/m²/s', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${_calibratedLux.round()} lux'
                    '${widget.prefs.calibrationFactor == 1.0 ? ' (non calibré)' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    'brut : ${_rawLux.round()} lux',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Max session',
                    value: _maxPpfd.round().toString(),
                    unit: 'µmol/m²/s',
                    onReset: () => setState(() => _maxPpfd = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title:
                        'DLI (${_formatHours(widget.prefs.photoperiodHours)})',
                    value: dli(
                      _currentPpfd,
                      widget.prefs.photoperiodHours,
                    ).toStringAsFixed(1),
                    unit: 'mol/m²/j',
                  ),
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

String _formatHours(double hours) {
  final isRound = hours == hours.roundToDouble();
  return isRound ? '${hours.round()} h' : '${hours.toStringAsFixed(1)} h';
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({required this.selected, required this.onChanged});

  final SpectrumPreset selected;
  final ValueChanged<SpectrumPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in spectra.entries)
          ChoiceChip(
            label: Text(entry.value.label),
            selected: entry.key == selected,
            onSelected: (_) => onChanged(entry.key),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    this.onReset,
  });

  final String title;
  final String value;
  final String unit;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                if (onReset != null)
                  InkWell(
                    onTap: onReset,
                    child: Icon(
                      Icons.refresh,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSensorMessage extends StatelessWidget {
  const _NoSensorMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          "Aucun capteur de luminosité détecté sur cet appareil.\n\n"
          'Le mode caméra (sans capteur dédié) arrivera dans une '
          'prochaine version.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
