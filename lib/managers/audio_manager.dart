import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_defender/services/storage_service.dart';

/// Centraliza toda la reproducción de audio del juego.
///
/// IMPORTANTE sobre rutas: `flame_audio` resuelve todos los nombres de
/// archivo de forma relativa a `assets/audio/` (su prefijo interno fijo).
/// Como nuestros assets están organizados en subcarpetas (`sfx/`, `music/`)
/// para mantener el proyecto ordenado, cada nombre referenciado aquí debe
/// incluir esa subcarpeta explícitamente (p. ej. `'sfx/shoot.wav'`), o
/// `flame_audio` no encontrará el archivo.
enum SfxType { shoot, hit, explosion, levelUp, pickup, uiClick, gameOver }

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool _initialized = false;
  bool _musicPlaying = false;

  bool get musicEnabled => StorageService.instance.musicEnabled;
  bool get sfxEnabled => StorageService.instance.sfxEnabled;
  double get musicVolume => StorageService.instance.musicVolume;
  double get sfxVolume => StorageService.instance.sfxVolume;

  static const Map<SfxType, String> _sfxFiles = {
    SfxType.shoot: 'sfx/shoot.wav',
    SfxType.hit: 'sfx/hit.wav',
    SfxType.explosion: 'sfx/explosion.wav',
    SfxType.levelUp: 'sfx/level_up.wav',
    SfxType.pickup: 'sfx/pickup.wav',
    SfxType.uiClick: 'sfx/ui_click.wav',
    SfxType.gameOver: 'sfx/game_over.wav',
  };

  static const String _backgroundMusicFile = 'music/background_theme.mp3';
  static const String _menuMusicFile = 'music/menu_theme.mp3';

  /// Precarga los assets de audio en memoria. Llamar una vez al inicio.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        ..._sfxFiles.values,
        _backgroundMusicFile,
        _menuMusicFile,
      ]);
    } catch (e) {
      // En desarrollo es común que falten archivos de audio reales todavía;
      // no queremos que esto tumbe el juego, solo lo registramos.
      // ignore: avoid_print
      print('AudioManager: no se pudieron precargar algunos audios ($e)');
    }
    _initialized = true;
  }

  Future<void> playSfx(SfxType type) async {
    if (!sfxEnabled) return;
    final file = _sfxFiles[type];
    if (file == null) return;
    try {
      await FlameAudio.play(file, volume: sfxVolume);
    } catch (_) {
      // Silenciar errores de audio faltante para no interrumpir el gameplay.
    }
  }

  Future<void> playMenuMusic() async {
    if (!musicEnabled || _musicPlaying) return;
    try {
      await FlameAudio.bgm.play(_menuMusicFile, volume: musicVolume);
      _musicPlaying = true;
    } catch (_) {}
  }

  Future<void> playGameMusic() async {
    if (!musicEnabled) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(_backgroundMusicFile, volume: musicVolume);
      _musicPlaying = true;
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _musicPlaying = false;
  }

  Future<void> setMusicVolume(double value) async {
    await StorageService.instance.setMusicVolume(value);
    try {
      FlameAudio.bgm.audioPlayer.setVolume(value);
    } catch (_) {}
  }

  Future<void> setSfxVolumePersisted(double value) =>
      StorageService.instance.setSfxVolume(value);

  Future<void> toggleMusic(bool enabled) async {
    await StorageService.instance.setMusicEnabled(enabled);
    if (!enabled) {
      await stopMusic();
    }
  }

  Future<void> toggleSfx(bool enabled) =>
      StorageService.instance.setSfxEnabled(enabled);
}
