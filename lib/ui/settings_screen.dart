import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/calibration.dart';
import '../core/conversion.dart';
import '../core/light_source.dart';
import '../update/update_ui.dart';
import '../update/updater.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.prefs, required this.source});

  final AppPrefs prefs;
  final LightSource source;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _updater = Updater();
  String _version = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoperiod = widget.prefs.photoperiodHours;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Photopériode (calcul du DLI)'),
            subtitle: Text(
              '${photoperiod.toStringAsFixed(1)} h de lumière par jour',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: photoperiod,
              min: 1,
              max: 24,
              divisions: 46,
              label: '${photoperiod.toStringAsFixed(1)} h',
              onChanged: (v) async {
                await widget.prefs.setPhotoperiodHours(v);
                if (mounted) setState(() {});
              },
            ),
          ),
          const Divider(),
          FutureBuilder<SensorInfo?>(
            future: widget.source.info(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return ListTile(
                leading: const Icon(Icons.sensors),
                title: const Text('Capteur de luminosité'),
                subtitle: Text(
                  info == null
                      ? 'informations indisponibles'
                      : '${info.name} (${info.vendor})'
                            '${info.resolution == null ? '' : '\nrésolution : ${info.resolution} lux'}'
                            '${info.maxRange == null ? '' : ' — max : ${info.maxRange!.round()} lux'}',
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Vérifier les mises à jour'),
            subtitle: Text('Version actuelle : $_version'),
            onTap: () => checkForUpdatesInteractive(
              context,
              updater: _updater,
              silentIfNone: false,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À propos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Seedlux estime le PPFD (µmol/m²/s) à partir du capteur de '
                  'luminosité du téléphone. La conversion lux → PPFD dépend '
                  'du spectre : sélectionnez le préset correspondant à votre '
                  'source.\n',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Facteurs utilisés (lux par µmol/m²/s) :',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                for (final s in spectra.values)
                  Text(
                    '• ${s.label} : ${s.luxPerUmol.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                Text(
                  'Sources : notes techniques Apogee Instruments ; méthode de '
                  'calibration solaire du whitepaper Photone.\n\n'
                  'Précision attendue avec un ALS de téléphone : ±20–30 % '
                  'après calibration, davantage sans. Pour des décisions '
                  'fines, utilisez un quantum meter.\n\n'
                  'Code source : github.com/jmontenez/seedlux (MIT)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
