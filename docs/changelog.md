# Changelog

## [0.1.0] — 2026-06-19

### Added
- Proyecto inicial Flutter + Flame
- Jugador con joystick virtual + teclado
- 3 tipos de enemigos (normal, rápido, grande)
- 2 jefes (cada 5 oleadas)
- 3 armas: espada, pistola, escopeta
- Sistema de oleadas infinitas con dificultad progresiva
- Object Pooling (balas, enemigos, pickups)
- Sistema RPG: XP, niveles, mejoras aleatorias
- 7 pantallas: splash, menú, juego, HUD, pausa, mejoras, game over, ajustes
- Audio: música de fondo + FX
- Persistencia: récord, monedas, mejoras, logros
- 6 logros desbloqueables
- Efectos visuales: partículas, explosiones, shake de cámara
- Documentación completa en `docs/`

### Technical
- Flutter 3.44 / Dart 3.12
- Flame 1.18 / flame_audio 2.10
- shared_preferences 2.3
- Object pooling para rendimiento
- Arquitectura desacoplada: systems, managers, models
