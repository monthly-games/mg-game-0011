import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages garden mechanics for Healing Garden (MG-0011).
///
/// Garden system: players plant healing herbs in garden plots.
/// Plants grow over time and can be harvested for healing resources.
/// Upgrades improve growth speed, harvest yield, and plot capacity.
class GardenManager extends ChangeNotifier {
  /// Default garden plots before upgrades.
  static const int kBasePlots = 4;

  /// Base growth ticks for a plant to mature.
  static const int kBaseGrowthTicks = 20;

  /// Base harvest amount per plant.
  static const double kBaseHarvestYield = 5.0;

  double _growthMultiplier = 1.0;
  double _yieldMultiplier = 1.0;
  int _maxPlots = kBasePlots;

  // Garden state
  final List<GardenPlot> _plots = [];
  double _totalHarvested = 0.0;
  int _harvestCount = 0;
  Timer? _growthTimer;

  // ── Getters ────────────────────────────────────────────────

  double get growthMultiplier => _growthMultiplier;
  double get yieldMultiplier => _yieldMultiplier;
  int get maxPlots => _maxPlots;
  int get usedPlots => _plots.length;
  int get availablePlots => _maxPlots - _plots.length;
  double get totalHarvested => _totalHarvested;
  int get harvestCount => _harvestCount;
  List<GardenPlot> get plots => List.unmodifiable(_plots);

  /// Effective growth ticks factoring in growth speed upgrade.
  int get effectiveGrowthTicks =>
      (kBaseGrowthTicks / _growthMultiplier).ceil();

  /// Effective harvest yield factoring in yield upgrade.
  double get effectiveHarvestYield => kBaseHarvestYield * _yieldMultiplier;

  /// Number of plants ready for harvest.
  int get readyCount => _plots.where((p) => p.isReady).length;

  GardenManager() {
    _startGrowthLoop();
  }

  void _startGrowthLoop() {
    _growthTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processGrowth();
    });
  }

  // ── Upgrade Setters (called from main.dart _applyUpgradeEffects) ───

  void setGrowthMultiplier(double value) {
    _growthMultiplier = value;
    notifyListeners();
  }

  void setYieldMultiplier(double value) {
    _yieldMultiplier = value;
    notifyListeners();
  }

  void setMaxPlots(int value) {
    _maxPlots = value;
    notifyListeners();
  }

  // ── Core Logic ─────────────────────────────────────────────

  /// Plant a healing herb in an available plot.
  /// Returns true if planting was successful.
  bool plantHerb({required String herbType}) {
    if (_plots.length >= _maxPlots) return false;

    _plots.add(GardenPlot(
      herbType: herbType,
      growthTicks: 0,
      maxGrowthTicks: effectiveGrowthTicks,
      isReady: false,
    ));
    notifyListeners();
    return true;
  }

  /// Process one growth tick for all planted herbs.
  void _processGrowth() {
    if (_plots.isEmpty) return;

    bool changed = false;
    for (final plot in _plots) {
      if (!plot.isReady) {
        plot.growthTicks++;
        if (plot.growthTicks >= plot.maxGrowthTicks) {
          plot.isReady = true;
        }
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  /// Harvest a ready plant from a specific plot index.
  /// Returns the harvest amount, or 0.0 if not harvestable.
  double harvestPlot(int plotIndex) {
    if (plotIndex < 0 || plotIndex >= _plots.length) return 0.0;
    if (!_plots[plotIndex].isReady) return 0.0;

    final harvestAmount = effectiveHarvestYield;
    _plots.removeAt(plotIndex);
    _totalHarvested += harvestAmount;
    _harvestCount++;
    notifyListeners();
    return harvestAmount;
  }

  /// Harvest all ready plants. Returns total harvest amount.
  double harvestAll() {
    double total = 0.0;
    // Iterate in reverse to safely remove
    for (int i = _plots.length - 1; i >= 0; i--) {
      if (_plots[i].isReady) {
        total += effectiveHarvestYield;
        _plots.removeAt(i);
        _harvestCount++;
      }
    }
    _totalHarvested += total;
    if (total > 0) notifyListeners();
    return total;
  }

  /// Reset garden state (for prestige / new session).
  void reset() {
    _plots.clear();
    _totalHarvested = 0.0;
    _harvestCount = 0;
    _growthMultiplier = 1.0;
    _yieldMultiplier = 1.0;
    _maxPlots = kBasePlots;
    notifyListeners();
  }

  @override
  void dispose() {
    _growthTimer?.cancel();
    super.dispose();
  }
}

/// Represents a single garden plot with a planted herb.
class GardenPlot {
  final String herbType;
  int growthTicks;
  final int maxGrowthTicks;
  bool isReady;

  GardenPlot({
    required this.herbType,
    required this.growthTicks,
    required this.maxGrowthTicks,
    required this.isReady,
  });

  /// Growth progress from 0.0 (just planted) to 1.0 (ready to harvest).
  double get growthProgress =>
      (growthTicks / maxGrowthTicks).clamp(0.0, 1.0);
}
