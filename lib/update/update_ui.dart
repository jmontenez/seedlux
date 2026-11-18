import 'package:material_ui/material_ui.dart';
import 'package:ota_update/ota_update.dart';

import 'updater.dart';

/// Vérifie les mises à jour et propose l'installation le cas échéant.
///
/// [silentIfNone] : en check automatique, ne rien afficher si l'app est à
/// jour ; en check manuel (réglages), confirmer que tout est à jour.
Future<void> checkForUpdatesInteractive(
  BuildContext context, {
  required Updater updater,
  bool silentIfNone = true,
}) async {
  final info = await updater.check();
  if (!context.mounted) return;

  if (info == null) {
    if (!silentIfNone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seedlux est à jour.')));
    }
    return;
  }

  final install = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mise à jour disponible'),
      content: SingleChildScrollView(
        child: Text(
          'Seedlux ${info.version} est disponible.'
          '${info.notes == null || info.notes!.trim().isEmpty ? '' : '\n\n${info.notes!.trim()}'}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Installer'),
        ),
      ],
    ),
  );
  if (install != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateProgressDialog(stream: updater.install(info)),
  );
}

class _UpdateProgressDialog extends StatelessWidget {
  const _UpdateProgressDialog({required this.stream});

  final Stream<OtaEvent> stream;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mise à jour'),
      content: StreamBuilder<OtaEvent>(
        stream: stream,
        builder: (context, snapshot) {
          final event = snapshot.data;
          if (snapshot.hasError) {
            return Text('Erreur : ${snapshot.error}');
          }
          switch (event?.status) {
            case OtaStatus.DOWNLOADING:
              final percent = int.tryParse(event?.value ?? '');
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Téléchargement… ${percent ?? 0} %'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percent == null ? null : percent / 100,
                  ),
                ],
              );
            case OtaStatus.INSTALLING:
              return const Text(
                "Installation… Android va demander confirmation.",
              );
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              return const Text(
                "Permission refusée : autorisez l'installation d'apps "
                'inconnues pour Seedlux dans les réglages Android.',
              );
            case OtaStatus.DOWNLOAD_ERROR:
              return const Text('Échec du téléchargement.');
            case OtaStatus.CHECKSUM_ERROR:
              return const Text(
                'Vérification SHA-256 échouée — installation annulée.',
              );
            case OtaStatus.INSTALLATION_DONE:
              return const Text('Installation terminée.');
            case OtaStatus.CANCELED:
              return const Text('Téléchargement annulé.');
            case OtaStatus.INSTALLATION_ERROR:
              return Text(
                "Échec de l'installation (${event?.value ?? 'inconnu'}).",
              );
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.ALREADY_RUNNING_ERROR:
              return Text('Erreur interne (${event?.value ?? 'inconnue'}).');
            case null:
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [LinearProgressIndicator()],
              );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
