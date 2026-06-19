import 'package:pixel_defender/services/storage_service.dart';

/// Definición estática de un logro.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
  });

  final String id;
  final String title;
  final String description;

  /// Función que evalúa, dado el estado actual de una partida (pasado como
  /// mapa de métricas), si el logro debe desbloquearse.
  final bool Function(Map<String, num> metrics) condition;
}

/// Evalúa logros contra las métricas de la partida en curso y persiste
/// los que se desbloquean.
///
/// Las métricas esperadas en el mapa son, por convención:
/// 'kills', 'survivalTime', 'level', 'coins', 'wave'.
class AchievementSystem {
  AchievementSystem({this.onUnlocked});

  /// Callback disparado cuando se desbloquea un logro nuevo (para mostrar
  /// un toast/notificación en la UI).
  void Function(Achievement achievement)? onUnlocked;

  static final List<Achievement> catalog = [
    Achievement(
      id: 'first_blood',
      title: 'Primera Sangre',
      description: 'Elimina a tu primer enemigo',
      condition: (m) => (m['kills'] ?? 0) >= 1,
    ),
    Achievement(
      id: 'survivor_5min',
      title: 'Superviviente',
      description: 'Sobrevive 5 minutos en una partida',
      condition: (m) => (m['survivalTime'] ?? 0) >= 300,
    ),
    Achievement(
      id: 'slayer_100',
      title: 'Cazador',
      description: 'Elimina 100 enemigos en una partida',
      condition: (m) => (m['kills'] ?? 0) >= 100,
    ),
    Achievement(
      id: 'slayer_500',
      title: 'Exterminador',
      description: 'Elimina 500 enemigos en una partida',
      condition: (m) => (m['kills'] ?? 0) >= 500,
    ),
    Achievement(
      id: 'level_10',
      title: 'Veterano',
      description: 'Alcanza el nivel 10',
      condition: (m) => (m['level'] ?? 0) >= 10,
    ),
    Achievement(
      id: 'level_25',
      title: 'Leyenda',
      description: 'Alcanza el nivel 25',
      condition: (m) => (m['level'] ?? 0) >= 25,
    ),
    Achievement(
      id: 'boss_slayer',
      title: 'Cazador de Jefes',
      description: 'Derrota a tu primer jefe',
      condition: (m) => (m['bossKills'] ?? 0) >= 1,
    ),
    Achievement(
      id: 'rich_500',
      title: 'Acaudalado',
      description: 'Acumula 500 monedas en total',
      condition: (m) => (m['totalCoins'] ?? 0) >= 500,
    ),
  ];

  /// Revisa todos los logros aún no desbloqueados contra [metrics] y
  /// desbloquea los que correspondan.
  Future<void> evaluate(Map<String, num> metrics) async {
    final unlocked = StorageService.instance.unlockedAchievements;
    for (final achievement in catalog) {
      if (unlocked.contains(achievement.id)) continue;
      if (achievement.condition(metrics)) {
        await StorageService.instance.unlockAchievement(achievement.id);
        onUnlocked?.call(achievement);
      }
    }
  }

  List<Achievement> get unlockedAchievements {
    final unlocked = StorageService.instance.unlockedAchievements;
    return catalog.where((a) => unlocked.contains(a.id)).toList();
  }

  List<Achievement> get lockedAchievements {
    final unlocked = StorageService.instance.unlockedAchievements;
    return catalog.where((a) => !unlocked.contains(a.id)).toList();
  }
}
