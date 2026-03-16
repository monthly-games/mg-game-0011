import 'package:mg_common_game/mg_common_game.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'systems/forest_manager.dart';
import 'game/healing_manager.dart';
import 'game/garden_manager.dart';
import 'game/combo_manager.dart';
import 'ui/main_screen.dart';
import 'screens/daily_quest_screen.dart';
import 'screens/achievement_screen.dart';
import 'screens/collection_screen.dart';
import 'game/tutorial_config.dart';
import 'game/balancing_config.dart';

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
  // DailyQuest 시스템
  GetIt.I.registerSingleton(DailyQuestManager());
  // Achievement 시스템
  GetIt.I.registerSingleton(AchievementManager());
  // Collection 시스템
  if (!GetIt.I.isRegistered<CollectionManager>()) {
    GetIt.I.registerSingleton(CollectionManager());
  // ── P3 Engine Systems ─────────────────────────────────────
  if (!GetIt.I.isRegistered<GuildWarManager>()) {
    GetIt.I.registerSingleton(GuildWarManager());
  }
  if (!GetIt.I.isRegistered<TournamentManager>()) {
    GetIt.I.registerSingleton(TournamentManager());
  }
  if (!GetIt.I.isRegistered<SeasonalContentManager>()) {
    GetIt.I.registerSingleton(SeasonalContentManager());
  }
_registerCollections();
  }
  _registerAchievements();
  _registerDailyQuests();
  // ── Tutorial & Balancing ──────────────────────────────────
  if (!GetIt.I.isRegistered<TutorialManager>()) {
    final tutorialManager = TutorialManager();
    await tutorialManager.initialize();
    tutorialManager.registerTutorial(
      kOnboardingTutorial.id,
      kOnboardingTutorial.steps,
    );
    GetIt.I.registerSingleton<TutorialManager>(tutorialManager);
  }
  if (!GetIt.I.isRegistered<BalancingManager>()) {
    GetIt.I.registerSingleton<BalancingManager>(
      BalancingManager(defaultConfig: kDefaultBalancingConfig),
    );
  }
  // ── Q7 DI Fix: Missing Systems ──────────────────────────
  if (!GetIt.I.isRegistered<BattlePassManager>()) {
    GetIt.I.registerSingleton<BattlePassManager>(BattlePassManager());
  }
  if (!GetIt.I.isRegistered<GachaManager>()) {
    GetIt.I.registerSingleton<GachaManager>(GachaManager());
  }

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

  // Prestige 시스템 (mg_common_game)
  if (!GetIt.I.isRegistered<PrestigeManager>()) {
    final prestigeManager = PrestigeManager();
    GetIt.I.registerSingleton(prestigeManager);
  // ── Retention Systems for DailyHub ────────────────────────
  if (!GetIt.I.isRegistered<LoginRewardsManager>()) {
    GetIt.I.registerSingleton(LoginRewardsManager());
  }
  if (!GetIt.I.isRegistered<StreakManager>()) {
    GetIt.I.registerSingleton(StreakManager());
  }
  if (!GetIt.I.isRegistered<DailyChallengeManager>()) {
    GetIt.I.registerSingleton(DailyChallengeManager());
  }
    _setupPrestige(prestigeManager);
    await prestigeManager.loadPrestigeData();
  }
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
        routes: {
          '/daily-quest': (_) => const DailyQuestScreen(),
          '/achievements': (_) => const AchievementScreen(),
        '/daily-hub': (context) => DailyHubScreen(
          questManager: GetIt.I<DailyQuestManager>(),
          loginRewardsManager: GetIt.I<LoginRewardsManager>(),
          streakManager: GetIt.I<StreakManager>(),
          challengeManager: GetIt.I<DailyChallengeManager>(),
          accentColor: MGColors.primaryAction,
          onClose: () => Navigator.pop(context),
        ),
        
          '/collection': (context) => CollectionScreen(
            collectionManager: GetIt.I<CollectionManager>(),
          ),
          '/guild-war': (context) => GuildWarScreen(
            guildWarManager: GetIt.I<GuildWarManager>(),
            accentColor: MGColors.primaryAction,
            onClose: () => Navigator.pop(context),
            ),
          '/tournament': (context) => TournamentScreen(
            tournamentManager: GetIt.I<TournamentManager>(),
            accentColor: MGColors.primaryAction,
            onClose: () => Navigator.pop(context),
            ),
          '/seasonal-event': (context) => SeasonalEventScreen(
            seasonalContentManager: GetIt.I<SeasonalContentManager>(),
            accentColor: MGColors.primaryAction,
            onClose: () => Navigator.pop(context),
            ),
},
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


void _registerDailyQuests() {
  final dailyQuest = GetIt.I<DailyQuestManager>();
  
  dailyQuest.registerQuest(DailyQuest(
    id: 'collect_gold',
    title: '골드 모으기',
    description: '골드 1000 획득',
    targetValue: 1000,
    goldReward: 500,
    xpReward: 10,
  ));
  
  dailyQuest.registerQuest(DailyQuest(
    id: 'play_games',
    title: '게임 플레이',
    description: '게임 5판 플레이',
    targetValue: 5,
    goldReward: 300,
    xpReward: 5,
  ));
  
  dailyQuest.registerQuest(DailyQuest(
    id: 'level_up',
    title: '레벨업',
    description: '레벨 1 상승',
    targetValue: 1,
    goldReward: 200,
    xpReward: 3,
  ));
}


void _registerAchievements() {
  final achievement = GetIt.I<AchievementManager>();
  
  achievement.registerAchievement(Achievement(
    id: 'gold_1000',
    title: '골드 1000 달성',
    description: '총 골드 1000을 모으세요',
    iconAsset: 'assets/achievements/gold_1000.png',
  ));
  
  achievement.registerAchievement(Achievement(
    id: 'level_10',
    title: '레벨 10 달성',
    description: '레벨 10에 도달하세요',
    iconAsset: 'assets/achievements/level_10.png',
  ));
  
  achievement.registerAchievement(Achievement(
    id: 'play_100',
    title: '100판 플레이',
    description: '게임을 100판 플레이하세요',
    iconAsset: 'assets/achievements/play_100.png',
  ));
}

void _setupPrestige(PrestigeManager manager) {
  // ── Prestige Upgrades (idle game defaults) ──────────────────
  // Five core upgrades for idle games
  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'gold_multiplier',
    name: '골드 배수',
    description: '골드 획득량 +10%',
    maxLevel: 50,
    costPerLevel: 1,
    bonusPerLevel: 0.1,
  ));

  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'xp_boost',
    name: 'XP 부스트',
    description: 'XP 획득량 +15%',
    maxLevel: 40,
    costPerLevel: 2,
    bonusPerLevel: 0.15,
  ));

  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'production_speed',
    name: '생산 속도',
    description: '생산 속도 +20%',
    maxLevel: 30,
    costPerLevel: 2,
    bonusPerLevel: 0.2,
  ));

  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'starting_resources',
    name: '초기 자원',
    description: '초기 자원 +5%',
    maxLevel: 60,
    costPerLevel: 1,
    bonusPerLevel: 0.05,
  ));

  manager.registerPrestigeUpgrade(PrestigeUpgrade(
    id: 'offline_income',
    name: '오프라인 수익',
    description: '오프라인 수익 +20%',
    maxLevel: 30,
    costPerLevel: 3,
    bonusPerLevel: 0.2,
  ));

  // ── Prestige Reset Callbacks ────────────────────────────────
  // TODO: Add game-specific reset callbacks:
  // manager.registerResetCallback(() {
  //   if (GetIt.I.isRegistered<ProgressionManager>()) {
  //     GetIt.I<ProgressionManager>().reset();
  //   }
  //   if (GetIt.I.isRegistered<UpgradeManager>()) {
  //     GetIt.I<UpgradeManager>().reset();
  //   }
  // });
}

void _registerCollections() {
  final collection = GetIt.I<CollectionManager>();

  // Characters 컬렉션
  collection.registerCollection(Collection(
    id: 'characters',
    name: '캐릭터',
    description: '모든 캐릭터를 수집하세요',
    items: [
      CollectionItem(
        id: 'char_warrior',
        name: '전사',
        description: '강인한 근접 전투 캐릭터',
        rarity: CollectionRarity.common,
      ),
      CollectionItem(
        id: 'char_mage',
        name: '마법사',
        description: '강력한 마법 공격 캐릭터',
        rarity: CollectionRarity.rare,
      ),
      CollectionItem(
        id: 'char_archer',
        name: '궁수',
        description: '원거리 정밀 공격 캐릭터',
        rarity: CollectionRarity.rare,
      ),
      CollectionItem(
        id: 'char_assassin',
        name: '암살자',
        description: '치명적인 은신 공격 캐릭터',
        rarity: CollectionRarity.epic,
      ),
      CollectionItem(
        id: 'char_healer',
        name: '힐러',
        description: '팀을 치유하는 지원 캐릭터',
        rarity: CollectionRarity.legendary,
      ),
    ],
    completionReward: CollectionReward(type: RewardType.gold, amount: 10000),
    milestoneRewards: {
      25: CollectionReward(type: RewardType.gold, amount: 1000),
      50: CollectionReward(type: RewardType.gold, amount: 3000),
      75: CollectionReward(type: RewardType.gold, amount: 5000),
    },
  ));

  // 아이템 해제 콜백 (햅틱 피드백)
  collection.onItemUnlocked = (collectionId, itemId) {
    // SettingsManager가 등록되어 있으면 햅틱 피드백
    debugPrint('Collection item unlocked: $collectionId / $itemId');
  };
}
