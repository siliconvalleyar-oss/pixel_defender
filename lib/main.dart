import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/services/storage_service.dart';
import 'package:pixel_defender/ui/game_scene.dart';
import 'package:pixel_defender/ui/main_menu.dart';
import 'package:pixel_defender/ui/settings_screen.dart';
import 'package:pixel_defender/ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura global de errores para debug
  FlutterError.onError = (details) {
    // ignore: avoid_print
    print('[PD_ERROR] ${details.exception}');
    // ignore: avoid_print
    print('[PD_ERROR] ${details.stack}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('[PD_PLATFORM_ERROR] $error');
    return true;
  };

  // Orientación y modo de pantalla recomendados para un arcade 2D.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await StorageService.initialize();
  await AudioManager.instance.initialize();

  runApp(const PixelDefenderApp());
}

/// Widget raíz de la aplicación.
///
/// Implementa una navegación simple basada en un enum de pantallas en
/// lugar de Navigator/rutas con nombre: dado que el juego tiene un flujo
/// lineal (splash -> menú -> juego -> menú), un `switch` sobre el estado
/// actual es más simple y predecible que gestionar una pila de rutas.
class PixelDefenderApp extends StatelessWidget {
  const PixelDefenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Defender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const _RootNavigator(),
    );
  }
}

enum _AppScreen { splash, menu, game, settings }

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  _AppScreen _screen = _AppScreen.splash;

  void _go(_AppScreen screen) => setState(() => _screen = screen);

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _AppScreen.splash:
        return SplashScreen(onFinished: () => _go(_AppScreen.menu));
      case _AppScreen.menu:
        return MainMenu(
          onPlay: () => _go(_AppScreen.game),
          onSettings: () => _go(_AppScreen.settings),
        );
      case _AppScreen.game:
        return GameScene(onExitToMenu: () => _go(_AppScreen.menu));
      case _AppScreen.settings:
        return SettingsScreen(onBack: () => _go(_AppScreen.menu));
    }
  }
}
