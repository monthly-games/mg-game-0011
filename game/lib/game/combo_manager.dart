import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages combo/chain mechanics for Healing Garden (MG-0011).
///
/// Combo system: match-3 puzzle matches build combo chains.
/// Higher combos multiply healing and resource gains.
/// Upgrades improve multiplier strength and chain bonuses.
class ComboManager extends ChangeNotifier {
  /// Default combo multiplier start.
  static const double kBaseMultiplier = 1.0;

  /// Default combo window in seconds before decay.
  static const double kBaseComboWindow = 3.0;

  double _baseMultiplier = kBaseMultiplier;
  double _chainBonusRate = 0.0;

  // Active combo state
  int _currentChain = 0;
  double _currentMultiplier = kBaseMultiplier;
  Timer? _comboTimer;
  int _bestChain = 0;
  int _totalCombos = 0;

  // ── Getters ────────────────────────────────────────────────

  double get baseMultiplier => _baseMultiplier;
  double get chainBonusRate => _chainBonusRate;
  int get currentChain => _currentChain;
  double get currentMultiplier => _currentMultiplier;
  int get bestChain => _bestChain;
  int get totalCombos => _totalCombos;
  bool get isComboActive => _currentChain > 0;

  /// Effective multiplier including chain bonuses from upgrades.
  double get effectiveMultiplier {
    if (_currentChain <= 0) return _baseMultiplier;
    final chainBonus = _currentChain * _chainBonusRate;
    return _currentMultiplier + chainBonus;
  }

  // ── Upgrade Setters (called from main.dart _applyUpgradeEffects) ───

  void setBaseMultiplier(double value) {
    _baseMultiplier = value;
    _recalculateMultiplier();
    notifyListeners();
  }

  void setChainBonusRate(double value) {
    _chainBonusRate = value;
    notifyListeners();
  }

  // ── Core Logic ─────────────────────────────────────────────

  /// Register a successful match to build the combo chain.
  void registerMatch() {
    _currentChain++;
    _totalCombos++;
    if (_currentChain > _bestChain) {
      _bestChain = _currentChain;
    }
    _recalculateMultiplier();
    _resetComboTimer();
    notifyListeners();
  }

  /// Break the combo chain (miss or timeout).
  void breakCombo() {
    _currentChain = 0;
    _currentMultiplier = _baseMultiplier;
    _comboTimer?.cancel();
    _comboTimer = null;
    notifyListeners();
  }

  void _recalculateMultiplier() {
    // Multiplier grows with chain length:
    // base + (chain * 0.1 * base)
    _currentMultiplier =
        _baseMultiplier + (_currentChain * 0.1 * _baseMultiplier);
  }

  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(
      Duration(milliseconds: (kBaseComboWindow * 1000).toInt()),
      () {
        // Combo window expired — decay chain by 1
        if (_currentChain > 1) {
          _currentChain--;
          _recalculateMultiplier();
          _resetComboTimer();
        } else {
          breakCombo();
        }
        notifyListeners();
      },
    );
  }

  /// Calculate bonus score for a match given the current combo state.
  double calculateMatchScore(double baseScore) {
    return baseScore * effectiveMultiplier;
  }

  /// Reset combo state (for prestige / new round).
  void reset() {
    breakCombo();
    _bestChain = 0;
    _totalCombos = 0;
    _baseMultiplier = kBaseMultiplier;
    _chainBonusRate = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    super.dispose();
  }
}
