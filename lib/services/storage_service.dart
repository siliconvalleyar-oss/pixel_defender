import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Capa de acceso a la persistencia local del dispositivo.
///
/// Todo el código del juego debería pasar por aquí en lugar de usar
/// [SharedPreferences] directamente: esto centraliza las claves y permite
/// cambiar el backend de almacenamiento (por ejemplo a Hive o a un backend
/// remoto) sin tocar el resto de la app.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static StorageService? _instance;

  /// Debe llamarse una vez en `main()` antes de `runApp`.
  static Future<StorageService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  static StorageService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'StorageService no inicializado. Llama a StorageService.initialize() en main().',
      );
    }
    return inst;
  }

  // ---------------------------------------------------------------------
  // Monedas / Récord
  // ---------------------------------------------------------------------
  int get coins => _prefs.getInt(GameConstants.prefCoins) ?? 0;
  Future<void> setCoins(int value) =>
      _prefs.setInt(GameConstants.prefCoins, value);
  Future<void> addCoins(int amount) => setCoins(coins + amount);

  int get highScore => _prefs.getInt(GameConstants.prefHighScore) ?? 0;
  Future<void> setHighScoreIfHigher(int score) {
    if (score > highScore) {
      return _prefs.setInt(GameConstants.prefHighScore, score);
    }
    return Future.value();
  }

  // ---------------------------------------------------------------------
  // Audio
  // ---------------------------------------------------------------------
  bool get musicEnabled => _prefs.getBool(GameConstants.prefMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _prefs.setBool(GameConstants.prefMusicEnabled, value);

  bool get sfxEnabled => _prefs.getBool(GameConstants.prefSfxEnabled) ?? true;
  Future<void> setSfxEnabled(bool value) =>
      _prefs.setBool(GameConstants.prefSfxEnabled, value);

  double get musicVolume => _prefs.getDouble(GameConstants.prefMusicVolume) ?? 0.6;
  Future<void> setMusicVolume(double value) =>
      _prefs.setDouble(GameConstants.prefMusicVolume, value);

  double get sfxVolume => _prefs.getDouble(GameConstants.prefSfxVolume) ?? 0.8;
  Future<void> setSfxVolume(double value) =>
      _prefs.setDouble(GameConstants.prefSfxVolume, value);

  // ---------------------------------------------------------------------
  // Logros (almacenados como lista de IDs desbloqueados)
  // ---------------------------------------------------------------------
  Set<String> get unlockedAchievements =>
      (_prefs.getStringList(GameConstants.prefAchievements) ?? []).toSet();

  Future<void> unlockAchievement(String id) async {
    final current = unlockedAchievements;
    if (current.add(id)) {
      await _prefs.setStringList(
        GameConstants.prefAchievements,
        current.toList(),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Mejoras permanentes (meta-progresión), serializadas como JSON
  // {upgradeId: level}
  // ---------------------------------------------------------------------
  Map<String, int> get permanentUpgradeLevels {
    final raw = _prefs.getString(GameConstants.prefPermanentUpgrades);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> setPermanentUpgradeLevel(String id, int level) async {
    final current = permanentUpgradeLevels;
    current[id] = level;
    await _prefs.setString(
      GameConstants.prefPermanentUpgrades,
      jsonEncode(current),
    );
  }

  /// Borra todos los datos guardados. Útil para "reiniciar progreso" en Ajustes.
  Future<void> clearAll() => _prefs.clear();
}
