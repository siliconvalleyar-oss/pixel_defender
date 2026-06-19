import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/utils/constants.dart';

/// Joystick virtual táctil, posicionado típicamente en la esquina inferior
/// izquierda de la pantalla. Reporta un vector normalizado (-1..1) a
/// [onChanged] cada vez que el dedo se mueve.
///
/// Implementado como widget Flutter puro (no componente Flame) para que
/// pueda dibujarse sobre el [GameWidget] como overlay, recibiendo gestos
/// directamente sin competir con el sistema de input del motor.
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({super.key, required this.onChanged});

  final ValueChanged<Vector2> onChanged;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobOffset = Offset.zero;
  Offset? _dragStart;

  static const double _baseRadius = GameConstants.joystickBaseRadius;
  static const double _knobRadius = GameConstants.joystickKnobRadius;

  void _handleDrag(Offset localPosition) {
    final delta = localPosition - Offset(_baseRadius, _baseRadius);
    final clamped = delta.distance > _baseRadius
        ? delta * (_baseRadius / delta.distance)
        : delta;

    setState(() => _knobOffset = clamped);

    final normalized = Vector2(
      clamped.dx / _baseRadius,
      clamped.dy / _baseRadius,
    );

    if (normalized.length2 < GameConstants.joystickDeadZone * GameConstants.joystickDeadZone) {
      widget.onChanged(Vector2.zero());
    } else {
      widget.onChanged(normalized);
    }
  }

  void _reset() {
    setState(() => _knobOffset = Offset.zero);
    widget.onChanged(Vector2.zero());
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _dragStart = details.localPosition;
        _handleDrag(details.localPosition);
      },
      onPanUpdate: (details) => _handleDrag(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: _baseRadius * 2,
        height: _baseRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: _knobOffset,
            child: Container(
              width: _knobRadius * 2,
              height: _knobRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
                border: Border.all(color: Colors.white54, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
