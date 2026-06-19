# Pixel Defender — Arquitectura

## Stack tecnológico

| Capa          | Tecnología                         |
|---------------|------------------------------------|
| Lenguaje      | Dart 3.12+                         |
| Framework     | Flutter 3.44                       |
| Motor juego   | Flame 1.18                         |
| Audio         | flame_audio 2.10                   |
| Persistencia  | shared_preferences 2.3             |
| Estado        | setState + callbacks (Provider disponible) |

## Estructura del proyecto

```
lib/
  main.dart                          # Punto de entrada, inyección de servicios
  game/
    pixel_defender_game.dart         # FlameGame orquestador
  components/
    player/                          # PlayerComponent, PlayerAnimationController
    enemy/                           # EnemyComponent, BossComponent, catálogo
    weapons/                         # WeaponComponent, BulletComponent (pooling)
    pickups/                         # PickupComponent (pooling)
    effects/                         # Partículas, explosiones, shake
  systems/
    spawn_system.dart                # Pooling y generación de enemigos
    wave_system.dart                 # Oleadas progresivas
    collision_system.dart            # Colisiones bala-enemigo, jugador-enemigo
    experience_system.dart           # Experiencia, niveles, mejoras
    upgrade_system.dart              # Generación aleatoria de mejoras
    achievement_system.dart          # Logros y recompensas
  managers/
    game_manager.dart                # Ciclo de vida de partida (init/start/gameover)
    audio_manager.dart               # Música + SFX (cacheable)
    save_manager.dart                # Meta-progresión (monedas, unlocks)
  models/
    player_data.dart                 # Datos del jugador (stats base)
    enemy_data.dart                  # Catálogo de enemigos
    weapon_data.dart                 # Catálogo de armas
    upgrade_data.dart                # Catálogo de mejoras
  services/
    storage_service.dart             # Wrapper SharedPreferences
  ui/
    splash_screen.dart               # Splash con logo
    main_menu.dart                   # Menú principal
    game_scene.dart                  # Widget contenedor del FlameGame
    hud.dart                         # HUD superpuesto (vida, XP, oleada)
    pause_menu.dart                  # Menú de pausa
    upgrade_screen.dart              # Selección de mejora al subir nivel
    game_over_screen.dart            # Pantalla de derrota
    settings_screen.dart             # Ajustes (volumen, controles)
    virtual_joystick.dart            # Joystick táctil
  utils/
    constants.dart                   # Todas las constantes de balanceo
    extensions.dart                  # Extensiones útiles (Rect, Vector2, etc.)
    helpers.dart                     # Funciones helper (aleatorio, cálculo distancia)
```

## Flujo del juego

```
Splash → MainMenu → GameScene (FlameGame)
                        ├── SpawnSystem (enemigos con pooling)
                        ├── WaveSystem (dificultad progresiva)
                        ├── PlayerComponent (input → movimiento)
                        ├── WeaponComponent (auto-aim → BulletComponent)
                        ├── CollisionSystem (bullets → enemigos)
                        ├── ExperienceSystem (XP → nivel → upgrade)
                        └── HUD (vida, XP, oleada, monedas)
                             │
                        UpgradeScreen (elección de mejora)
                             │
                        GameOverScreen (estadísticas → main menu)
```

## Patrones clave

- **Object Pooling:** Balas, enemigos y pickups se reciclan (evitaallocaciones)
- **Catálogo de datos:** Enemigos, armas y mejoras viven en `models/*_data.dart` como mapas configurables
- **Constants-driven balance:** `constants.dart` centraliza todos los números de diseño
- **Sistema de logros desacoplado:** `AchievementSystem` escucha eventos del `GameManager`
