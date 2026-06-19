import 'package:pixel_defender/systems/spawn_system.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Controla el avance de oleadas infinitas y la dificultad progresiva.
///
/// Cada [GameConstants.waveDuration] segundos avanza a la siguiente oleada,
/// lo que aumenta el multiplicador de dificultad y la frecuencia de spawn.
/// Cada [GameConstants.bossWaveInterval] oleadas aparece un jefe.
class WaveSystem {
  WaveSystem({required this.spawnSystem, this.onWaveChanged, this.onBossWave});

  final EnemySpawnSystem spawnSystem;

  void Function(int wave)? onWaveChanged;
  void Function(int wave)? onBossWave;

  int currentWave = 1;
  double _waveTimer = 0;
  double _spawnTimer = 0;
  bool _bossSpawnedThisWave = false;

  double get difficultyMultiplier =>
      1 + (currentWave - 1) * GameConstants.difficultyRampPerWave;

  /// Intervalo entre spawns individuales; baja a medida que sube la
  /// dificultad, hasta un piso para no saturar el dispositivo.
  double get _spawnInterval {
    final base = 1.1 - (currentWave * 0.04);
    return base.clamp(0.12, 1.1);
  }

  bool get _isBossWave =>
      currentWave > 0 && currentWave % GameConstants.bossWaveInterval == 0;

  void update(double dt) {
    _waveTimer += dt;
    _spawnTimer -= dt;

    if (_waveTimer >= GameConstants.waveDuration) {
      _advanceWave();
    }

    if (_spawnTimer <= 0) {
      spawnSystem.spawnRandomForWave(currentWave, difficultyMultiplier);
      _spawnTimer = _spawnInterval;
    }

    if (_isBossWave && !_bossSpawnedThisWave) {
      spawnSystem.spawnBoss(currentWave, difficultyMultiplier);
      _bossSpawnedThisWave = true;
      onBossWave?.call(currentWave);
    }
  }

  void _advanceWave() {
    _waveTimer = 0;
    currentWave++;
    _bossSpawnedThisWave = false;
    onWaveChanged?.call(currentWave);
  }

  void reset() {
    currentWave = 1;
    _waveTimer = 0;
    _spawnTimer = 0;
    _bossSpawnedThisWave = false;
  }

  double get waveProgress =>
      (_waveTimer / GameConstants.waveDuration).clamp(0.0, 1.0);
}
