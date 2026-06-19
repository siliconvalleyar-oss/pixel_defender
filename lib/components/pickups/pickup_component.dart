import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_defender/components/effects/particle_effect.dart';
import 'package:pixel_defender/game/pixel_defender_game.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/utils/constants.dart';

enum PickupType { experience, coin }

/// Objeto recolectable que cae al morir un enemigo: gema de experiencia o
/// moneda. Implementa "recolección automática": cuando el jugador entra en
/// el radio de imán, el pickup se mueve hacia él; al entrar en el radio de
/// recolección directa, se consume.
///
/// Igual que balas y enemigos, estos componentes se reutilizan vía pool
/// (ver [PickupPool]) dado el alto volumen esperado en partidas largas.
class PickupComponent extends PositionComponent
    with HasGameReference<PixelDefenderGame> {
  PickupComponent() : super(size: Vector2.all(10), anchor: Anchor.center);

  PickupType type = PickupType.experience;
  int value = 1;
  bool active = false;
  bool _beingPulled = false;

  void spawn({
    required Vector2 position,
    required PickupType type,
    required int value,
  }) {
    this.position = position.clone();
    this.type = type;
    this.value = value;
    active = true;
    _beingPulled = false;
  }

  void deactivate() {
    active = false;
    position = Vector2(-9999, -9999);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;

    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    final magnetRadius =
        GameConstants.expGemMagnetRadius * player.data.stats.pickupRadiusMultiplier;
    final pickupRadius =
        GameConstants.expGemPickupRadius * player.data.stats.pickupRadiusMultiplier;

    if (distToPlayer <= pickupRadius) {
      _collect();
      return;
    }

    if (distToPlayer <= magnetRadius) {
      _beingPulled = true;
    }

    if (_beingPulled) {
      final dir = (player.position - position).normalized();
      position += dir * GameConstants.expGemMagnetSpeed * dt;
    }
  }

  void _collect() {
    if (type == PickupType.experience) {
      game.onExperienceCollected(value);
    } else {
      game.onCoinCollected(value);
    }
    AudioManager.instance.playSfx(SfxType.pickup);
    game.world.add(
      ParticleEffect.pickupSparkle(
        position: position.clone(),
        color: type == PickupType.experience ? Colors.lightGreenAccent : Colors.amber,
      ),
    );
    game.pickupPool.recycle(this);
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final color = type == PickupType.experience ? Colors.lightGreenAccent : Colors.amber;
    final paint = Paint()..color = color;

    if (type == PickupType.experience) {
      // Forma de diamante para gemas de experiencia.
      final path = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(size.x, size.y / 2)
        ..lineTo(size.x / 2, size.y)
        ..lineTo(0, size.y / 2)
        ..close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    }
  }
}

/// Pool de [PickupComponent], análogo a [BulletPool].
class PickupPool {
  PickupPool(this.world);

  final World world;
  final List<PickupComponent> _pool = [];

  PickupComponent obtain() {
    for (final pickup in _pool) {
      if (!pickup.active) return pickup;
    }
    final pickup = PickupComponent();
    _pool.add(pickup);
    world.add(pickup);
    return pickup;
  }

  void recycle(PickupComponent pickup) => pickup.deactivate();

  void spawnExperience(Vector2 position, int value) {
    obtain().spawn(position: position, type: PickupType.experience, value: value);
  }

  void spawnCoin(Vector2 position, int value) {
    obtain().spawn(position: position, type: PickupType.coin, value: value);
  }

  void reset() {
    for (final pickup in _pool) {
      pickup.deactivate();
    }
  }
}
