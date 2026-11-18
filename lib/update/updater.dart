import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Une mise à jour publiée sur GitHub Releases.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    this.sha256,
    this.notes,
  });

  final String version;
  final String apkUrl;
  final String? sha256;
  final String? notes;
}

/// Vérifie et installe les mises à jour depuis les releases GitHub du repo.
///
/// Android uniquement : sur iOS, TestFlight gère les mises à jour.
/// La signature APK est vérifiée par Android lui-même (même keystore requis) ;
/// le SHA-256 de l'asset est contrôlé avant installation quand GitHub le
/// fournit (champ `digest`).
class Updater {
  Updater({this.repo = 'jmontenez/seedlux', http.Client? client})
    : _client = client ?? http.Client();

  final String repo;
  final http.Client _client;

  /// Retourne la mise à jour disponible, ou null si l'app est à jour,
  /// hors Android, ou si le check échoue (offline, rate-limit…).
  Future<UpdateInfo?> check() async {
    if (!Platform.isAndroid) return null;
    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final response = await _client
          .get(
            Uri.https('api.github.com', '/repos/$repo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (release['tag_name'] as String?) ?? '';
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      if (latest.isEmpty || !isNewerVersion(latest, current)) return null;

      final assets = (release['assets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final apk = assets.firstWhere(
        (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        orElse: () => const {},
      );
      final url = apk['browser_download_url'] as String?;
      if (url == null) return null;

      // GitHub publie le digest des assets sous la forme « sha256:<hex> ».
      final digest = apk['digest'] as String?;
      final sha256 = (digest != null && digest.startsWith('sha256:'))
          ? digest.substring('sha256:'.length)
          : null;

      return UpdateInfo(
        version: latest,
        apkUrl: url,
        sha256: sha256,
        notes: release['body'] as String?,
      );
    } on Exception {
      return null;
    }
  }

  /// Télécharge et lance l'installation (les événements remontent la
  /// progression : DOWNLOADING percent, INSTALLING…).
  Stream<OtaEvent> install(UpdateInfo update) => OtaUpdate().execute(
    update.apkUrl,
    destinationFilename: 'seedlux-${update.version}.apk',
    sha256checksum: update.sha256,
  );
}

/// Compare deux versions « x.y.z » (préfixe `v`, suffixes `-…`/`+…` ignorés).
bool isNewerVersion(String candidate, String current) {
  List<int> parse(String v) {
    final core = v.split('+').first.split('-').first;
    final parts = core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }

  final a = parse(candidate);
  final b = parse(current);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}
