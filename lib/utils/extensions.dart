import 'dart:math';
import 'dart:ui';

/// Extensiones sobre [Vector2]-like (usamos Offset/Point matemáticamente)
/// y utilidades numéricas reutilizadas en múltiples sistemas.
extension DoubleClamp on double {
  double clampMin0() => this < 0 ? 0 : this;
}

extension RandomRange on Random {
  /// Devuelve un double aleatorio entre [min] y [max] (inclusive min, exclusive max).
  double nextDoubleRange(double min, double max) {
    return min + nextDouble() * (max - min);
  }

  /// Devuelve true con probabilidad [chance] (0.0 a 1.0).
  bool chance(double chance) => nextDouble() < chance;
}

extension OffsetUtils on Offset {
  Offset clampMagnitude(double maxLength) {
    final length = distance;
    if (length <= maxLength || length == 0) return this;
    final scale = maxLength / length;
    return Offset(dx * scale, dy * scale);
  }
}
