# Pixel Defender — Instructivo

## ¿Qué es Pixel Defender?

Juego arcade 2D estilo *Vampire Survivors*. Controlás un personaje vista superior que dispara automáticamente. Sobreviví oleadas infinitas de enemigos, subí de nivel, mejorá tus armas y batí tu récord.

## Controles

| Plataforma | Control                          |
|------------|----------------------------------|
| **Táctil** | Joystick virtual (esquina inf. izq.) |
| **Teclado**| WASD / Flechas → Movimiento      |
| **Teclado**| Esc → Pausa                      |

El **disparo es automático**: tus armas apuntan al enemigo más cercano dentro del rango.

## Pantallas

### Splash
Logo del juego, carga de assets.

### Menú principal
- **Jugar** → comienza una partida
- **Mejoras** → mejoras permanentes (comprar con monedas)
- **Logros** → desafíos desbloqueables
- **Ajustes** → volumen, controles

### Juego (HUD)
- Barra de vida (verde)
- Barra de escudo (celeste)
- Barra de XP (morada)
- Contador de monedas
- Número de oleada actual
- Armas equipadas

### Pausa (ESC o botón)
- Reanudar
- Ajustes rápidos
- Salir al menú

### Mejora (al subir nivel)
Aparece una pantalla con 3 opciones aleatorias:
- **Aumentar vida máxima**
- **Aumentar velocidad**
- **Aumentar daño**
- **Reducir cooldown**
- **Aumentar rango de armas**
- **Nueva arma** (si hay slot libre)
- **Recuperar vida**

### Game Over
- Puntaje final
- Oleada alcanzada
- Monedas obtenidas (dependiendo del rendimiento)
- Botones: Reintentar / Menú principal

## Sistema de juego

### Progresión
- Matá enemigos → obtenés XP (gemas) y monedas
- Subís de nivel → elegís una mejora
- Cada 5 oleadas → jefe
- Dificultad escala: más enemigos, más rápidos, más vida

### Armas
- **Espada cuerpo a cuerpo** — corto alcance, daño alto
- **Pistola** — alcance medio, daño medio
- **Escopeta** — corto alcance, spread, daño alto por proyectil

Se pueden equipar hasta 3 armas simultáneamente.

### Enemigos
| Tipo      | Características                  |
|-----------|----------------------------------|
| Normal    | Persecución directa, velocidad media |
| Rápido    | Poca vida, muy veloz             |
| Grande    | Mucha vida, lento, daño alto     |
| Jefe      | Cada 5 oleadas, habilidades especiales |

### Logros
- Sobrevivir 10 oleadas
- Matar 1000 enemigos
- Conseguir 3 armas en una partida
- Vencer al primer jefe
- Llegar a nivel 20
- Juntar 500 monedas en total

### Persistencia
Todo se guarda automáticamente:
- Récord de oleada
- Monedas acumuladas
- Mejoras permanentes compradas
- Logros desbloqueados

## Consejos
1. Movete constantemente — no te quedés quieto
2. Priorizá esquivas sobre daño al principio
3. La escopeta es excelente contra grupos
4. Los jefes anuncian su llegada — preparate
5. Las mejoras de velocidad y vida ayudan más de lo que parece

## Solución de problemas

| Problema                  | Solución                               |
|---------------------------|----------------------------------------|
| No compila                | `flutter pub get` / `flutter clean`    |
| No se escucha audio       | Verificar volumen, en web requiere click |
| Bajo FPS                  | Reducir `maxConcurrentEnemies` en constants.dart |
| Joystick no responde      | Verificar que no haya otro input activo |
