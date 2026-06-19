# Pixel Defender 🛡️

Juego arcade 2D de oleadas (estilo *Vampire Survivors*) construido con **Flutter** + **Flame Engine**.

Vista superior, joystick virtual, disparo automático al enemigo más cercano, oleadas infinitas con dificultad progresiva, sistema RPG de niveles y mejoras, jefes, logros, y persistencia local.

---

## 📦 Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) estable (3.22+ recomendado, Dart ≥3.3).
- Un editor (VSCode con la extensión de Flutter/Dart, o Android Studio).
- Para compilar a dispositivo físico/emulador: Android Studio (Android) o Xcode (iOS, solo macOS).

Verifica tu instalación:

```bash
flutter doctor
```

## 🚀 Instalación

1. Descomprime/copia la carpeta `pixel_defender` donde prefieras.
2. Abre una terminal dentro de la carpeta del proyecto.
3. Instala las dependencias:

```bash
cd pixel_defender
flutter pub get
```

## ▶️ Ejecutar el juego

**Web (más rápido para probar):**
```bash
flutter run -d chrome
```

**Escritorio (Linux/macOS/Windows, si tienes el soporte habilitado):**
```bash
flutter run -d linux    # o -d macos / -d windows
```

**Android (con un emulador corriendo o dispositivo conectado por USB con depuración activada):**
```bash
flutter run -d android
```

**iOS (requiere macOS + Xcode):**
```bash
flutter run -d ios
```

Para ver todos los dispositivos disponibles:
```bash
flutter devices
```

## 🎮 Controles

- **Táctil:** joystick virtual en la esquina inferior izquierda.
- **Teclado:** flechas o `WASD` para moverse, `Esc` para pausar.
- El disparo es **automático**: apuntas moviéndote, las armas equipadas disparan solas al enemigo más cercano dentro de su rango.

## 🗂️ Estructura del proyecto

```
lib/
  main.dart                  # Punto de entrada, inicializa servicios y navegación
  game/
    pixel_defender_game.dart # FlameGame principal: orquesta todos los sistemas
  components/
    player/                  # Jugador: movimiento, vida, animación
    enemy/                   # Enemigos comunes y jefes, IA de persecución
    weapons/                 # Armas y balas (con object pooling)
    pickups/                 # Gemas de experiencia y monedas (con pooling)
    effects/                 # Partículas, flash de daño, shake de cámara
  systems/
    spawn_system.dart        # Pooling y generación de enemigos
    wave_system.dart         # Oleadas infinitas y dificultad progresiva
    collision_system.dart    # Resolución de impactos bala-enemigo
    experience_system.dart   # Progresión de nivel
    upgrade_system.dart      # Generación de mejoras aleatorias
    achievement_system.dart  # Logros
  managers/
    game_manager.dart        # Ciclo de vida de una partida
    audio_manager.dart       # Música y efectos de sonido
    save_manager.dart        # Mejoras permanentes (meta-progresión)
  models/                    # Datos puros (sin Flame): jugador, enemigos, armas, mejoras
  services/
    storage_service.dart     # Persistencia con SharedPreferences
  ui/                        # Pantallas Flutter: menú, HUD, pausa, mejoras, game over, ajustes
  utils/                     # Constantes, helpers, extensiones

assets/
  images/                    # Sprites (actualmente placeholders, ver nota abajo)
  audio/
    music/                   # Música de fondo (menu_theme.mp3, background_theme.mp3)
    sfx/                     # Efectos de sonido (.wav)
```

## ⚠️ Notas importantes sobre este entregable

Este proyecto es el **núcleo jugable completo**: jugador con joystick, combate automático con object pooling, enemigos con IA y spawn dinámico, oleadas infinitas con jefes, sistema RPG (experiencia/nivel/mejoras), HUD completo, audio, persistencia y las 7 pantallas principales. Compilará y se jugará de principio a fin tal cual está.

Quedan como **siguientes pasos** para llevarlo a calidad 100% comercial:

1. **Sprites reales:** las carpetas `assets/images/*` contienen placeholders PNG transparentes de 32×32. Todo el render actual usa formas geométricas dibujadas por código (`Canvas`), no sprites. `PlayerAnimationController` (`lib/components/player/player_animation.dart`) ya está diseñado para una migración directa a `SpriteAnimationComponent` cuando tengas los sprite sheets.
2. **Audio real:** los `.wav`/`.mp3` en `assets/audio/` son tonos sintéticos generados por código (placeholders audibles, no silenciosos) para que el proyecto compile y tengas feedback sonoro real desde ya. Reemplázalos por música y efectos definitivos del mismo nombre de archivo y todo seguirá funcionando sin tocar código.
3. **Gamepad:** el input combina joystick táctil + teclado (`WASD`/flechas). El soporte de gamepad físico requiere el paquete `gamepads` o el manejo de `RawKeyEvent`/`GameControllerEvent` adicional de Flutter, no incluido aún.
4. **Árbol de mejoras visual / más armas y enemigos:** el sistema (`upgrade_system.dart`, `weapon_data.dart`, `enemy_data.dart`) está hecho para escalar — añadir un nuevo `WeaponType` o `EnemyType` es agregar una entrada al catálogo correspondiente.
5. **`provider`** está en `pubspec.yaml` (como pedido) pero el estado actual se maneja con `setState` + callbacks simples, suficiente para este alcance; migrar a Provider/Riverpod es directo si el proyecto crece.

## 🔧 Balanceo rápido

Casi todos los números de diseño (vida, velocidad, daño, duración de oleada, etc.) viven en **un solo archivo**: `lib/utils/constants.dart`. Es el primer lugar para ajustar la dificultad.

## 🐛 Solución de problemas comunes

- **"Target of URI doesn't exist"**: ejecuta `flutter pub get` de nuevo.
- **No se escucha audio**: revisa que no esté silenciado el dispositivo/navegador; en Chrome, el audio puede requerir una primera interacción del usuario (click) antes de reproducirse — esto es una restricción del navegador, no un bug del proyecto.
- **Bajo FPS con muchos enemigos**: reduce `GameConstants.maxConcurrentEnemies` en `constants.dart`.
