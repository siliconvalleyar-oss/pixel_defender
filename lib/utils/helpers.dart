import 'dart:math';
import 'package:flame/components.dart';

/// Funciones de utilidad pura, sin estado, reutilizadas por varios sistemas.
class Helpers {
  Helpers._();

  static final Random _random = Random();

  /// Genera una posición aleatoria en un anillo alrededor de [center],
  /// entre [minRadius] y [maxRadius]. Útil para hacer spawn de enemigos
  /// fuera de la vista del jugador pero no demasiado lejos.
  static Vector2 randomPointInRing(
    Vector2 center, {
    required double minRadius,
    required double maxRadius,
  }) {
    final angle = _random.nextDouble() * 2 * pi;
    final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    return Vector2(
      center.x + cos(angle) * radius,
      center.y + sin(angle) * radius,
    );
  }

  /// Curva de experiencia necesaria para subir de nivel [level] -> [level + 1].
  static int expRequiredForLevel(int level, int base, double multiplier) {
    return (base * pow(multiplier, level - 1)).round();
  }

  /// Interpolación lineal simple.
  static double lerp(double a, double b, double t) => a + (b - a) * t;

  /// Devuelve un valor aleatorio con sesgo, usado para drops de loot.
  static T weightedPick<T>(Map<T, double> weights) {
    final total = weights.values.fold<double>(0, (a, b) => a + b);
    final roll = _random.nextDouble() * total;
    double cumulative = 0;
    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) return entry.key;
    }
    return weights.keys.first;
  }

  static double formatTimeSeconds(double seconds) => seconds;

  static String formatDuration(double seconds) {
    final totalSeconds = seconds.floor();
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
