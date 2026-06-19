/// Constantes globales usadas en todo el proyecto.
///
/// Mantener todos los "números mágicos" aquí facilita el balanceo del juego
/// sin tener que rastrear valores dispersos por el código.
library;

class GameConstants {
  GameConstants._();

  // ---------------------------------------------------------------------
  // Mundo / Cámara
  // ---------------------------------------------------------------------
  static const double worldWidth = 3000;
  static const double worldHeight = 3000;

  // ---------------------------------------------------------------------
  // Jugador
  // ---------------------------------------------------------------------
  static const double playerBaseSpeed = 180; // px/seg
  static const double playerBaseMaxHealth = 100;
  static const double playerSpriteSize = 48;
  static const double playerInvulnerabilityDuration = 0.6; // segundos

  // Joystick
  static const double joystickBaseRadius = 60;
  static const double joystickKnobRadius = 28;
  static const double joystickDeadZone = 0.08;

  // ---------------------------------------------------------------------
  // Experiencia / Niveles
  // ---------------------------------------------------------------------
  static const int baseExpToLevelUp = 10;
  static const double expCurveMultiplier = 1.35;
  static const double expGemPickupRadius = 28;
  static const double expGemMagnetRadius = 120;
  static const double expGemMagnetSpeed = 420;

  // ---------------------------------------------------------------------
  // Enemigos
  // ---------------------------------------------------------------------
  static const double enemyBaseSpeed = 60;
  static const double enemySpawnRadius = 520; // distancia desde el jugador
  static const double enemyDespawnRadius = 900;
  static const double enemyContactDamageCooldown = 0.5;

  // ---------------------------------------------------------------------
  // Oleadas
  // ---------------------------------------------------------------------
  static const double waveDuration = 30; // segundos por oleada
  static const int maxConcurrentEnemies = 220;
  static const double difficultyRampPerWave = 0.12;
  static const int bossWaveInterval = 5; // cada N oleadas aparece un jefe

  // ---------------------------------------------------------------------
  // Armas / Proyectiles
  // ---------------------------------------------------------------------
  static const double bulletDefaultSpeed = 480;
  static const double bulletDefaultLifetime = 1.6; // segundos
  static const int bulletPoolInitialSize = 64;
  static const double criticalHitChanceBase = 0.05;
  static const double criticalHitMultiplier = 2.0;
  static const double knockbackBaseForce = 90;

  // ---------------------------------------------------------------------
  // UI / HUD
  // ---------------------------------------------------------------------
  static const double hudPadding = 12;

  // ---------------------------------------------------------------------
  // Persistencia (claves de SharedPreferences)
  // ---------------------------------------------------------------------
  static const String prefCoins = 'pd_coins';
  static const String prefHighScore = 'pd_high_score';
  static const String prefMusicEnabled = 'pd_music_enabled';
  static const String prefSfxEnabled = 'pd_sfx_enabled';
  static const String prefMusicVolume = 'pd_music_volume';
  static const String prefSfxVolume = 'pd_sfx_volume';
  static const String prefAchievements = 'pd_achievements';
  static const String prefPermanentUpgrades = 'pd_permanent_upgrades';
}
