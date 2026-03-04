import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages healing mechanics for Healing Garden (MG-0011).
///
/// Healing system: patients arrive and occupy treatment slots.
/// Each slot heals over time based on healing power and recovery rate.
/// Upgrades improve healing efficiency and add treatment capacity.
class HealingManager extends ChangeNotifier {
  /// Default treatment slots before upgrades.
  static const int kBaseSlots = 2;

  /// Base healing points per tick.
  static const double kBaseHealingPower = 10.0;

  /// Base recovery ticks required per patient.
  static const int kBaseRecoveryTicks = 10;

  double _healingMultiplier = 1.0;
  double _recoveryMultiplier = 1.0;
  int _maxSlots = kBaseSlots;

  // Patient tracking
  final List<PatientSlot> _patients = [];
  int _totalHealed = 0;
  double _totalHealingDone = 0.0;
  Timer? _healingTimer;

  // ── Getters ────────────────────────────────────────────────

  double get healingMultiplier => _healingMultiplier;
  double get recoveryMultiplier => _recoveryMultiplier;
  int get maxSlots => _maxSlots;
  int get occupiedSlots => _patients.length;
  int get availableSlots => _maxSlots - _patients.length;
  int get totalHealed => _totalHealed;
  double get totalHealingDone => _totalHealingDone;
  List<PatientSlot> get patients => List.unmodifiable(_patients);

  /// Effective healing power factoring in upgrade multiplier.
  double get effectiveHealingPower => kBaseHealingPower * _healingMultiplier;

  /// Effective recovery ticks factoring in recovery upgrade.
  int get effectiveRecoveryTicks =>
      (kBaseRecoveryTicks / _recoveryMultiplier).ceil();

  HealingManager() {
    _startHealingLoop();
  }

  void _startHealingLoop() {
    _healingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processHealing();
    });
  }

  // ── Upgrade Setters (called from main.dart _applyUpgradeEffects) ───

  void setHealingMultiplier(double value) {
    _healingMultiplier = value;
    notifyListeners();
  }

  void setRecoveryMultiplier(double value) {
    _recoveryMultiplier = value;
    notifyListeners();
  }

  void setMaxSlots(int value) {
    _maxSlots = value;
    notifyListeners();
  }

  // ── Core Logic ─────────────────────────────────────────────

  /// Admit a new patient if slots available.
  /// Returns true if patient was admitted successfully.
  bool admitPatient({required String name, required double severity}) {
    if (_patients.length >= _maxSlots) return false;

    _patients.add(PatientSlot(
      name: name,
      severity: severity,
      healthRemaining: severity,
      ticksElapsed: 0,
    ));
    notifyListeners();
    return true;
  }

  /// Process one healing tick across all occupied slots.
  void _processHealing() {
    if (_patients.isEmpty) return;

    bool changed = false;
    final completed = <int>[];

    for (int i = 0; i < _patients.length; i++) {
      final patient = _patients[i];
      final healAmount = effectiveHealingPower;
      patient.healthRemaining -= healAmount;
      patient.ticksElapsed++;
      _totalHealingDone += healAmount;

      if (patient.healthRemaining <= 0 ||
          patient.ticksElapsed >= effectiveRecoveryTicks) {
        completed.add(i);
      }
      changed = true;
    }

    // Remove completed patients (reverse to maintain indices)
    for (int i = completed.length - 1; i >= 0; i--) {
      _patients.removeAt(completed[i]);
      _totalHealed++;
    }

    if (changed) notifyListeners();
  }

  /// Reset healing state (for prestige / new session).
  void reset() {
    _patients.clear();
    _totalHealed = 0;
    _totalHealingDone = 0.0;
    _healingMultiplier = 1.0;
    _recoveryMultiplier = 1.0;
    _maxSlots = kBaseSlots;
    notifyListeners();
  }

  @override
  void dispose() {
    _healingTimer?.cancel();
    super.dispose();
  }
}

/// Data class representing a patient in a treatment slot.
class PatientSlot {
  final String name;
  final double severity;
  double healthRemaining;
  int ticksElapsed;

  PatientSlot({
    required this.name,
    required this.severity,
    required this.healthRemaining,
    required this.ticksElapsed,
  });

  /// Progress from 0.0 (just admitted) to 1.0 (fully healed).
  double get healingProgress =>
      1.0 - (healthRemaining / severity).clamp(0.0, 1.0);
}
