import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'package:mg_common_game/core/systems/save_manager_helper.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'systems/forest_manager.dart';
import 'game/healing_manager.dart';
import 'game/garden_manager.dart';
import 'game/combo_manager.dart';
import 'ui/main_screen.dart';

// ============================================================
// Healing Garden — MG-0011
// Phase 1 Week 4: Mechanic Enhancement (Puzzle)
//
// Genre: Puzzle (match-3 + garden management hybrid)
// Region: Africa (Gold theme)
//
// Core loop: Match-3 → Heal Patients → Grow Garden → Combo Chains
// Subsystems:
//   - Healing: Patient treatment with power/recovery/slots
//   - Garden: Herb planting with growth/yield/expansion
//   - Combo: Match chains with multiplier/bonus scaling
//   - Upgrades: 8 registered via UpgradeManager
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSystems();
  runApp(const FairyForestApp());
}

/// Initialize all DI-registered systems in correct dependency order.
/// mg_common_game systems first, then game-specific managers.
Future<void> _initializeSystems() async {
  final di = GetIt.I;

  // ── mg_common_game core systems ──────────────────────────
  if (!di.isRegistered<AudioManager>()) {
    di.registerSingleton<AudioManager>(AudioManager());
  }
  await di<AudioManager>().initialize();

  // Unified Persistence
  await SaveManagerHelper.setupSaveManager(
    autoSaveEnabled: true,
    autoSaveIntervalSeconds: 30,
  );
  await SaveManagerHelper.legacyLoadAll();

  // ── Existing game managers ──────────────────────────────
  if (!di.isRegistered<ForestManager>()) {
    di.registerSingleton<ForestManager>(ForestManager());
  }

  // ── Healing Garden managers ─────────────────────────────
  if (!di.isRegistered<HealingManager>()) {
    di.registerSingleton<HealingManager>(HealingManager());
  }

  if (!di.isRegistered<GardenManager>()) {
    di.registerSingleton<GardenManager>(GardenManager());
  }

  if (!di.isRegistered<ComboManager>()) {
    di.registerSingleton<ComboManager>(ComboManager());
  }

  // ── Upgrade system ──────────────────────────────────────
  if (!di.isRegistered<UpgradeManager>()) {
    final upgrades = UpgradeManager();
    di.registerSingleton<UpgradeManager>(upgrades);
    _registerUpgrades(upgrades);
    await upgrades.loadUpgrades();
  }

  // Apply saved upgrade levels to runtime managers
  _applyUpgradeEffects();

  // Listen for future upgrade purchases to re-apply effects
  _setupUpgradeListener();
}

// ============================================================
// Upgrade Registration — 8 healing-garden upgrades
// Categories: Healing (3), Garden (3), Combo (2)
// ============================================================

void _registerUpgrades(UpgradeManager manager) {
  // ── Healing upgrades (3) ────────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: 'healing_power',
    name: 'Healing Power',
    description: 'Increase base healing strength by 15% per level.',
    maxLevel: 15,
    baseCost: 50,
    costMultiplier: 1.4,
    valuePerLevel: 0.15,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'recovery_rate',
    name: 'Recovery Rate',
    description: 'Speed up patient recovery by 10% per level.',
    maxLevel: 12,
    baseCost: 80,
    costMultiplier: 1.45,
    valuePerLevel: 0.1,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'treatment_slots',
    name: 'Treatment Slots',
    description: 'Add 1 concurrent treatment slot per level.',
    maxLevel: 5,
    baseCost: 200,
    costMultiplier: 2.0,
    valuePerLevel: 1.0,
  ));

  // ── Garden upgrades (3) ─────────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: 'growth_speed',
    name: 'Growth Speed',
    description: 'Increase plant growth speed by 12% per level.',
    maxLevel: 15,
    baseCost: 40,
    costMultiplier: 1.35,
    valuePerLevel: 0.12,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'harvest_yield',
    name: 'Harvest Yield',
    description: 'Boost harvest output by 20% per level.',
    maxLevel: 10,
    baseCost: 100,
    costMultiplier: 1.5,
    valuePerLevel: 0.2,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'garden_expansion',
    name: 'Garden Expansion',
    description: 'Expand garden capacity by 2 plots per level.',
    maxLevel: 8,
    baseCost: 150,
    costMultiplier: 1.6,
    valuePerLevel: 2.0,
  ));

  // ── Combo upgrades (2) ──────────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: 'combo_multiplier',
    name: 'Combo Multiplier',
    description: 'Increase combo score multiplier by 0.1x per level.',
    maxLevel: 10,
    baseCost: 120,
    costMultiplier: 1.5,
    valuePerLevel: 0.1,
  ));

  manager.registerUpgrade(Upgrade(
    id: 'chain_bonus',
    name: 'Chain Bonus',
    description: 'Add 25% bonus reward for chain combos per level.',
    maxLevel: 8,
    baseCost: 180,
    costMultiplier: 1.55,
    valuePerLevel: 0.25,
  ));
}

// ============================================================
// Apply saved upgrade levels to runtime managers
// Called on init and whenever an upgrade is purchased.
// ============================================================

void _applyUpgradeEffects() {
  final di = GetIt.I;
  final upgradeManager = di<UpgradeManager>();
  final healingManager = di<HealingManager>();
  final gardenManager = di<GardenManager>();
  final comboManager = di<ComboManager>();

  // ── Healing effects ─────────────────────────────────────
  final healingPower = upgradeManager.getUpgrade('healing_power');
  if (healingPower != null) {
    healingManager.setHealingMultiplier(
      1.0 + healingPower.currentValue,
    );
  }

  final recoveryRate = upgradeManager.getUpgrade('recovery_rate');
  if (recoveryRate != null) {
    healingManager.setRecoveryMultiplier(
      1.0 + recoveryRate.currentValue,
    );
  }

  final treatmentSlots = upgradeManager.getUpgrade('treatment_slots');
  if (treatmentSlots != null) {
    healingManager.setMaxSlots(
      HealingManager.kBaseSlots + treatmentSlots.currentValue.toInt(),
    );
  }

  // ── Garden effects ──────────────────────────────────────
  final growthSpeed = upgradeManager.getUpgrade('growth_speed');
  if (growthSpeed != null) {
    gardenManager.setGrowthMultiplier(
      1.0 + growthSpeed.currentValue,
    );
  }

  final harvestYield = upgradeManager.getUpgrade('harvest_yield');
  if (harvestYield != null) {
    gardenManager.setYieldMultiplier(
      1.0 + harvestYield.currentValue,
    );
  }

  final gardenExpansion = upgradeManager.getUpgrade('garden_expansion');
  if (gardenExpansion != null) {
    gardenManager.setMaxPlots(
      GardenManager.kBasePlots + gardenExpansion.currentValue.toInt(),
    );
  }

  // ── Combo effects ───────────────────────────────────────
  final comboMult = upgradeManager.getUpgrade('combo_multiplier');
  if (comboMult != null) {
    comboManager.setBaseMultiplier(
      1.0 + comboMult.currentValue,
    );
  }

  final chainBonus = upgradeManager.getUpgrade('chain_bonus');
  if (chainBonus != null) {
    comboManager.setChainBonusRate(chainBonus.currentValue);
  }
}

/// Register listener to auto-apply upgrade effects when purchased.
void _setupUpgradeListener() {
  final upgradeManager = GetIt.I<UpgradeManager>();
  upgradeManager.addListener(_applyUpgradeEffects);
}

// ============================================================
// Game Constants — Healing Garden balancing parameters
// ============================================================

/// Central balancing constants for the Healing Garden game.
/// All game systems reference these instead of hardcoded values.
abstract class HealingGardenConstants {
  // ── Patient generation ──────────────────────────────────
  /// Minimum severity for generated patients.
  static const double kMinPatientSeverity = 20.0;

  /// Maximum severity for generated patients.
  static const double kMaxPatientSeverity = 100.0;

  /// Interval between automatic patient arrivals (seconds).
  static const int kPatientArrivalInterval = 15;

  // ── Garden herbs ────────────────────────────────────────
  /// Available herb types for planting.
  static const List<String> kHerbTypes = [
    'lavender',
    'chamomile',
    'aloe_vera',
    'mint',
    'sage',
    'rosemary',
  ];

  // ── Combo scoring ───────────────────────────────────────
  /// Base score per match-3 clear.
  static const double kBaseMatchScore = 10.0;

  /// Bonus score per additional tile beyond 3.
  static const double kExtraTileBonus = 5.0;

  // ── Economy ─────────────────────────────────────────────
  /// Mana reward per healed patient.
  static const double kManaPerHeal = 15.0;

  /// Mana reward per harvested herb.
  static const double kManaPerHarvest = 8.0;
}

// ============================================================
// App Root — MultiProvider wraps all game state
// ============================================================

class FairyForestApp extends StatelessWidget {
  const FairyForestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GetIt.I<ForestManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<HealingManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<GardenManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<ComboManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<UpgradeManager>()),
      ],
      child: MaterialApp(
        title: 'Healing Garden',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainScreen(),
      ),
    );
  }

  /// Africa-region garden theme with warm natural accents.
  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
