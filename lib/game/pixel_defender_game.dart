import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_defender/components/effects/explosion_effect.dart';
import 'package:pixel_defender/components/enemy/enemy_component.dart';
import 'package:pixel_defender/components/pickups/pickup_component.dart';
import 'package:pixel_defender/components/player/player_component.dart';
import 'package:pixel_defender/components/weapons/weapon_component.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/managers/save_manager.dart';
import 'package:pixel_defender/models/upgrade_data.dart';
import 'package:pixel_defender/models/weapon_data.dart';
import 'package:pixel_defender/models/player_data.dart';
import 'package:pixel_defender/systems/achievement_system.dart';
import 'package:pixel_defender/systems/collision_system.dart';
import 'package:pixel_defender/systems/experience_system.dart';
import 'package:pixel_defender/systems/spawn_system.dart';
import 'package:pixel_defender/systems/upgrade_system.dart';
import 'package:pixel_defender/systems/wave_system.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Estado de alto nivel de la partida en curso, observado por la UI (HUD,
/// pantalla de mejoras, game over) a través de callbacks expuestos en
/// [PixelDefenderGame].
enum GameRunState { running, paused, leveling, gameOver }

/// Clase principal del juego, construida sobre [FlameGame].
///
/// Actúa como "game manager" técnico: posee el mundo, la cámara, el
/// jugador, y todos los sistemas (spawn, oleadas, colisiones, experiencia,
/// logros). La UI de Flutter (HUD, menús) se comunica con esta clase a
/// través de callbacks y de los getters de estado expuestos aquí, en lugar
/// de acceder directamente a los componentes internos.
class PixelDefenderGame extends FlameGame with KeyboardEvents {
  PixelDefenderGame({PlayerData? initialPlayerData})
      : _initialPlayerData = initialPlayerData;

  final PlayerData? _initialPlayerData;
  final Random random = Random();

  late final PlayerComponent player;
  late final BulletPool bulletPool;
  late final PickupPool pickupPool;
  late final EnemySpawnSystem enemySpawnSystem;
  late final WaveSystem waveSystem;
  late final CollisionSystem collisionSystem;
  late final ExperienceSystem experienceSystem;
  late final AchievementSystem achievementSystem;
  late final UpgradeSystem upgradeSystem;
  late final DamageFlashEffect damageFlash;

  GameRunState runState = GameRunState.running;

  // --- Callbacks consumidos por la capa de UI (Flutter widgets) ---
  VoidCallback? onStateChanged; // refresco genérico del HUD
  VoidCallback? onPlayerDeath;
  void Function(List<UpgradeOption> options)? onLevelUpReady;
  void Function(Achievement achievement)? onAchievementUnlocked;
  void Function(int wave)? onBossWaveStarted;

  int _bossKillsThisRun = 0;

  /// Cuenta cuántas pantallas de mejora quedan pendientes de mostrar.
  /// Necesario porque una sola gema de experiencia grande (o un jefe)
  /// puede otorgar suficiente XP para subir varios niveles de golpe;
  /// en ese caso mostramos una pantalla de mejora a la vez, en lugar de
  /// sobrescribir las opciones pendientes con cada nivel ganado.
  int _queuedLevelUps = 0;

  Vector2 get keyboardInput => _keyboardInput;
  Vector2 _keyboardInput = Vector2.zero();
  Vector2 joystickInput = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF14141C);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    player = PlayerComponent(data: _initialPlayerData)
      ..position = Vector2(GameConstants.worldWidth / 2, GameConstants.worldHeight / 2);

    bulletPool = BulletPool(world);
    pickupPool = PickupPool(world);

    await world.add(player);
    camera.follow(player);

    bulletPool.preWarm(GameConstants.bulletPoolInitialSize);

    enemySpawnSystem = EnemySpawnSystem(game: this, random: random);
    waveSystem = WaveSystem(
      spawnSystem: enemySpawnSystem,
      onWaveChanged: (wave) => onStateChanged?.call(),
      onBossWave: (wave) => onBossWaveStarted?.call(wave),
    );
    collisionSystem = CollisionSystem(game: this);
    experienceSystem = ExperienceSystem(
      playerData: player.data,
      onLevelUp: _handleLevelUp,
    );
    achievementSystem = AchievementSystem(
      onUnlocked: (a) => onAchievementUnlocked?.call(a),
    );
    upgradeSystem = UpgradeSystem(random: random);

    damageFlash = DamageFlashEffect(size: size);
    camera.viewport.add(damageFlash);

    await AudioManager.instance.playGameMusic();
  }

  // -----------------------------------------------------------------
  // Bucle principal
  // -----------------------------------------------------------------
  @override
  void update(double dt) {
    if (runState != GameRunState.running) {
      super.update(dt);
      return;
    }

    // Combina joystick (táctil) y teclado en un único vector de entrada.
    final combined = joystickInput + _keyboardInput;
    player.inputDirection =
        combined.length > 1 ? combined.normalized() : combined;

    super.update(dt);

    waveSystem.update(dt);
    collisionSystem.update(dt);
    CameraShake.update(camera, dt);

    onStateChanged?.call();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final dx = (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
                keysPressed.contains(LogicalKeyboardKey.keyD)
            ? 1
            : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
                keysPressed.contains(LogicalKeyboardKey.keyA)
            ? 1
            : 0);
    final dy = (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
                keysPressed.contains(LogicalKeyboardKey.keyS)
            ? 1
            : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
                keysPressed.contains(LogicalKeyboardKey.keyW)
            ? 1
            : 0);

    _keyboardInput = Vector2(dx.toDouble(), dy.toDouble());

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      togglePause();
    }

    return KeyEventResult.handled;
  }

  // -----------------------------------------------------------------
  // Accesores usados por componentes (enemigos, armas, sistemas)
  // -----------------------------------------------------------------
  Iterable<EnemyComponent> get activeEnemies => enemySpawnSystem.active;

  void spawnDamageNumber(Vector2 position, double amount, {bool isCritical = false}) {
    world.add(
      DamageNumberComponent(position: position, damage: amount, isCritical: isCritical),
    );
  }

  // -----------------------------------------------------------------
  // Eventos de gameplay
  // -----------------------------------------------------------------
  void onEnemyKilled(EnemyComponent enemy) {
    player.data.kills++;
    if (enemy.archetype.isBoss) _bossKillsThisRun++;

    pickupPool.spawnExperience(enemy.position.clone(), enemy.archetype.expReward);
    if (random.nextDouble() < 0.6) {
      pickupPool.spawnCoin(enemy.position.clone(), enemy.archetype.coinReward);
    }

    _evaluateAchievements();
  }

  void onExperienceCollected(int amount) {
    experienceSystem.grantExperience(amount);
  }

  void onCoinCollected(int amount) {
    final bonus = 1 + SaveManager.instance.getPermanentBonus('perm_coins');
    player.data.coinsThisRun += (amount * bonus).round();
  }

  void onPlayerDamaged() {
    damageFlash.trigger();
    CameraShake.shake(camera, intensity: 4, duration: 0.15);
  }

  void onPlayerDied() {
    runState = GameRunState.gameOver;
    pauseEngine();
    AudioManager.instance.stopMusic();
    AudioManager.instance.playSfx(SfxType.gameOver);

    SaveManager.instance.saveRunResults(
      coinsEarned: player.data.coinsThisRun,
      survivalScore: player.data.survivalTime.round() * 10 + player.data.kills,
    );

    _evaluateAchievements();
    onPlayerDeath?.call();
  }

  void _handleLevelUp(int newLevel) {
    _queuedLevelUps++;
    _evaluateAchievements();

    // Si ya hay una pantalla de mejora visible (o a punto de mostrarse),
    // no disparamos otra superpuesta: se mostrará automáticamente la
    // siguiente cuando el jugador resuelva la actual (ver applyUpgradeChoice).
    if (runState == GameRunState.leveling) return;

    _presentNextLevelUp();
  }

  void _presentNextLevelUp() {
    if (_queuedLevelUps <= 0) return;

    AudioManager.instance.playSfx(SfxType.levelUp);
    CameraShake.shake(camera, intensity: 6, duration: 0.2);

    final options = upgradeSystem.generateOptions(
      equippedWeapons: player.weapons.map((w) => w.instance).toList(),
    );
    runState = GameRunState.leveling;
    pauseEngine();
    onLevelUpReady?.call(options);
  }

  /// Llamado por [UpgradeScreen] cuando el jugador elige una mejora.
  void applyUpgradeChoice(UpgradeOption option) {
    if (option.kind == UpgradeKind.newWeapon && option.weaponType != null) {
      player.equipWeapon(option.weaponType!);
    } else if (option.kind == UpgradeKind.weaponLevelUp && option.weaponType != null) {
      player.levelUpWeapon(option.weaponType!);
    } else {
      upgradeSystem.applyUpgrade(option, player.data);
      player.refreshWeaponStats();
    }

    _queuedLevelUps = (_queuedLevelUps - 1).clamp(0, 999);

    if (_queuedLevelUps > 0) {
      // Aún quedan niveles por resolver: mantenemos el engine pausado y
      // mostramos la siguiente pantalla de mejora inmediatamente.
      _presentNextLevelUp();
    } else {
      runState = GameRunState.running;
      resumeEngine();
    }
  }

  void _evaluateAchievements() {
    achievementSystem.evaluate({
      'kills': player.data.kills,
      'survivalTime': player.data.survivalTime,
      'level': player.data.level,
      'coins': player.data.coinsThisRun,
      'totalCoins': player.data.coinsThisRun, // se complementa con storage en pantalla de logros
      'wave': waveSystem.currentWave,
      'bossKills': _bossKillsThisRun,
    });
  }

  // -----------------------------------------------------------------
  // Control de partida
  // -----------------------------------------------------------------
  void togglePause() {
    if (runState == GameRunState.running) {
      runState = GameRunState.paused;
      pauseEngine();
    } else if (runState == GameRunState.paused) {
      runState = GameRunState.running;
      resumeEngine();
    }
  }

  void setJoystickInput(Vector2 direction) {
    joystickInput = direction;
  }
}
