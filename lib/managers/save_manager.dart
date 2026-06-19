import 'package:pixel_defender/models/upgrade_data.dart';
import 'package:pixel_defender/services/storage_service.dart';

/// Encapsula las operaciones de guardado que ocurren al finalizar una
/// partida o al modificar la meta-progresión (mejoras permanentes, logros).
///
/// Mantiene [permanentUpgrades] en memoria sincronizado con el storage,
/// para que la UI pueda leer/escribir sin tener que await en cada frame.
class SaveManager {
  SaveManager._();
  static final SaveManager instance = SaveManager._();

  late List<PermanentUpgrade> permanentUpgrades;

  void loadPermanentUpgrades() {
    final levels = StorageService.instance.permanentUpgradeLevels;
    permanentUpgrades = PermanentUpgrade.defaultCatalog().map((upgrade) {
      upgrade.currentLevel = levels[upgrade.id] ?? 0;
      return upgrade;
    }).toList();
  }

  Future<bool> purchasePermanentUpgrade(String id) async {
    final upgrade = permanentUpgrades.firstWhere((u) => u.id == id);
    if (upgrade.isMaxed) return false;

    final cost = upgrade.nextCost;
    final coins = StorageService.instance.coins;
    if (coins < cost) return false;

    await StorageService.instance.addCoins(-cost);
    upgrade.currentLevel++;
    await StorageService.instance.setPermanentUpgradeLevel(
      id,
      upgrade.currentLevel,
    );
    return true;
  }

  /// Calcula el bonus acumulado de todas las mejoras permanentes para un id dado.
  double getPermanentBonus(String id) {
    final upgrade = permanentUpgrades.firstWhere(
      (u) => u.id == id,
      orElse: () => PermanentUpgrade(
        id: id,
        name: '',
        description: '',
        costPerLevel: 0,
        maxLevel: 0,
        effectPerLevel: 0,
      ),
    );
    return upgrade.totalEffect;
  }

  /// Persiste los resultados de una partida finalizada.
  Future<void> saveRunResults({
    required int coinsEarned,
    required int survivalScore,
  }) async {
    await StorageService.instance.addCoins(coinsEarned);
    await StorageService.instance.setHighScoreIfHigher(survivalScore);
  }
}
