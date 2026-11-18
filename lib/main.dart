import 'package:material_ui/material_ui.dart';

import 'core/als_light_source.dart';
import 'core/calibration.dart';
import 'ui/measure_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  runApp(SeedluxApp(prefs: prefs));
}

class SeedluxApp extends StatelessWidget {
  const SeedluxApp({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seedlux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7CB342),
          brightness: Brightness.dark,
        ),
      ),
      home: MeasureScreen(prefs: prefs, source: AlsLightSource()),
    );
  }
}
