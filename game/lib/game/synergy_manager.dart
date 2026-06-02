import 'dart:async';
import 'package:flutter/foundation.dart';
import 'garden_manager.dart';
import 'healing_manager.dart';
import 'combo_manager.dart';

/// Manages cross-system synergies for MG-0011.
///
/// Creates positive feedback loops between garden, healing, and combo systems:
/// - Harvesting herbs grants temporary healing boosts
/// - Completing healing charges combo meter
/// - Active combos increase garden yield
class SynergyManager extends ChangeNotifier {
  /// Duration of healing boost after harvest (seconds).
  static const int kHealingBoostDuration = 30;

  /// Combo charge gained per patient healed.
  static const double kComboChargePerHeal = 0.15;

  /// Yield bonus per combo multiplier level.
  static const double kYieldBonusPerCombo = 0.1;

  /// Max stacked healing boost charges.
  static const int kMaxHealingBoostCharges = 3;

  // Synergy state
  int _healingBoostCharges = 0;
  Timer? _healingBoostTimer;
  double _currentYieldBonus = 0.0;
  int _totalSynergyActivations = 0;
  int _totalBoostsConsumed = 0;

  // Statistics
  int _herbsHarvested = 0;
  int _patientsHealedWithBoost = 0;
  double _totalYieldBonus = 0.0;

  // ── Getters ────────────────────────────────────────────────

  int get healingBoostCharges => _healingBoostCharges;
  bool get hasHealingBoost => _healingBoostCharges > 0;
  double get currentYieldBonus => _currentYieldBonus;
  int get totalSynergyActivations => _totalSynergyActivations;
  int get totalBoostsConsumed => _totalBoostsConsumed;
  int get herbsHarvested => _herbsHarvested;
  int get patientsHealedWithBoost => _patientsHealedWithBoost;
  double get totalYieldBonus => _totalYieldBonus;

  /// Active boost multiplier for healing (1.0 + 0.5 per charge).
  double get healingBoostMultiplier =>
      1.0 + (_healingBoostCharges * 0.5);

  // ── Core Logic ─────────────────────────────────────────────

  /// Called when herbs are harvested. Grants healing boost charges.
  void onHerbHarvested({required double amount, required String herbType}) {
    _herbsHarvested++;
    if (_healingBoostCharges < kMaxHealingBoostCharges) {
      _healingBoostCharges++;
      _totalSynergyActivations++;
      _startHealingBoostTimer();
      notifyListeners();
    }
  }

  /// Called when a patient is healed. Charges combo meter.
  void onPatientHealed({
    required HealingManager healingManager,
    required ComboManager comboManager,
  }) {
    if (hasHealingBoost) {
      _patientsHealedWithBoost++;
      _healingBoostCharges--;
      _totalBoostsConsumed++;
      if (_healingBoostCharges == 0) {
        _healingBoostTimer?.cancel();
        _healingBoostTimer = null;
      }
    }

    // Charge combo meter based on healing activity
    final charge = kComboChargePerHeal * (hasHealingBoost ? 2.0 : 1.0);
    if (comboManager.currentChain > 0) {
      comboManager.registerMatch();
    }

    notifyListeners();
  }

  /// Called when combo changes. Updates garden yield bonus.
  void onComboChanged({required ComboManager comboManager}) {
    final chainLevel = (comboManager.currentChain / 5).floor();
    _currentYieldBonus = chainLevel * kYieldBonusPerCombo;
    notifyListeners();
  }

  /// Calculate final harvest yield including combo bonus.
  double calculateHarvestYield(double baseYield) {
    final bonus = baseYield * _currentYieldBonus;
    _totalYieldBonus += bonus;
    return baseYield + bonus;
  }

  /// Calculate final healing amount including boost multiplier.
  double calculateHealingAmount(double baseHealing) {
    return baseHealing * healingBoostMultiplier;
  }

  void _startHealingBoostTimer() {
    if (_healingBoostTimer != null) return;

    _healingBoostTimer = Timer(
      const Duration(seconds: kHealingBoostDuration),
      () {
        if (_healingBoostCharges > 0) {
          _healingBoostCharges--;
          if (_healingBoostCharges > 0) {
            _startHealingBoostTimer();
          } else {
            _healingBoostTimer = null;
          }
          notifyListeners();
        }
      },
    );
  }

  /// Reset all synergy state (for prestige / new session).
  void reset() {
    _healingBoostCharges = 0;
    _healingBoostTimer?.cancel();
    _healingBoostTimer = null;
    _currentYieldBonus = 0.0;
    _totalSynergyActivations = 0;
    _totalBoostsConsumed = 0;
    _herbsHarvested = 0;
    _patientsHealedWithBoost = 0;
    _totalYieldBonus = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _healingBoostTimer?.cancel();
    super.dispose();
  }
}

/// Enhancement types that can be activated via synergies.
enum SynergyEnhancement {
  /// Instant growth boost for all garden plots.
  instantGrowth,

  /// Reduced recovery time for all patients.
  speedyRecovery,

  /// Extended combo window duration.
  comboExtension,

  /// Double harvest yield for next harvest.
  doubleHarvest,

  /// Heal all patients instantly.
  massHeal,
}

/// Active enhancement with duration and effect.
class ActiveEnhancement {
  final SynergyEnhancement type;
  final int remainingTicks;
  final double potency;

  ActiveEnhancement({
    required this.type,
    required this.remainingTicks,
    required this.potency,
  });

  /// Create copy with decremented ticks.
  ActiveEnhancement tick() {
    return ActiveEnhancement(
      type: type,
      remainingTicks: remainingTicks - 1,
      potency: potency,
    );
  }

  /// Check if enhancement is still active.
  bool get isActive => remainingTicks > 0;
}
