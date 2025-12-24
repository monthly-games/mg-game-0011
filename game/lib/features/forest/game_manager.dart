import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'components/structure_component.dart';

class StructureData {
  final StructureType type;
  final double x;
  final double y;

  StructureData({required this.type, required this.x, required this.y});

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'x': x,
        'y': y,
      };

  factory StructureData.fromJson(Map<String, dynamic> json) {
    return StructureData(
      type: StructureType.values[json['type'] as int],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

enum FairyType { basic, nature, fire, water, light }

class GameManager extends ChangeNotifier {
  static const String _prefsKeyMana = 'forest_mana';
  static const String _prefsKeyTotalMana = 'forest_total_mana';
  static const String _prefsKeyStructures = 'forest_structures';
  static const String _prefsKeyFairies = 'forest_fairies';

  bool _isBuildMode = false;
  bool get isBuildMode => _isBuildMode;

  StructureType? _selectedStructure;
  StructureType? get selectedStructure => _selectedStructure;

  // Mana (Currency)
  int _mana = 100;
  int get mana => _mana;

  int _totalManaEarned = 100;
  int get totalManaEarned => _totalManaEarned;

  // Passive Income Logic
  final List<StructureData> _placedStructures = [];
  List<StructureData> get placedStructures =>
      List.unmodifiable(_placedStructures);

  double _accumulator = 0.0;

  // Fairy Collection
  final Set<FairyType> _collectedFairies = {};
  Set<FairyType> get collectedFairies => Set.unmodifiable(_collectedFairies);

  // Happiness Logic
  double get happiness {
    double multiplier = 1.0;
    // Variety Bonus
    final uniqueTypes = _placedStructures.map((e) => e.type).toSet().length;
    multiplier += uniqueTypes * 0.05; // 5% per unique type
    // Density Bonus
    multiplier += _placedStructures.length * 0.01; // 1% per structure

    // Fairy Collection Bonus
    multiplier +=
        _collectedFairies.length * 0.1; // 10% per Fairy Type discovered!

    return multiplier;
  }

  double get passiveIncomeRate {
    double baseRate = 0;
    for (final s in _placedStructures) {
      switch (s.type) {
        case StructureType.tree:
          baseRate += 1;
          break;
        case StructureType.flower:
          baseRate += 0.5;
          break;
        case StructureType.mushroomHouse:
          baseRate += 5;
          break;
        case StructureType.rock:
          baseRate += 0.2;
          break;
      }
    }
    return baseRate * happiness;
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _mana = prefs.getInt(_prefsKeyMana) ?? 100;
    _totalManaEarned = prefs.getInt(_prefsKeyTotalMana) ?? 100;

    final structuresJson = prefs.getStringList(_prefsKeyStructures);
    if (structuresJson != null) {
      _placedStructures.clear();
      for (final str in structuresJson) {
        try {
          _placedStructures.add(StructureData.fromJson(jsonDecode(str)));
        } catch (e) {
          debugPrint("Error parsing structure: $e");
        }
      }
    }

    final fairiesJson = prefs.getStringList(_prefsKeyFairies);
    if (fairiesJson != null) {
      _collectedFairies.clear();
      for (final fIndex in fairiesJson) {
        _collectedFairies.add(FairyType.values[int.parse(fIndex)]);
      }
    }

    notifyListeners();
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyMana, _mana);
    await prefs.setInt(_prefsKeyTotalMana, _totalManaEarned);

    final structuresJson =
        _placedStructures.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKeyStructures, structuresJson);

    final fairiesJson =
        _collectedFairies.map((e) => e.index.toString()).toList();
    await prefs.setStringList(_prefsKeyFairies, fairiesJson);
  }

  void update(double dt) {
    if (passiveIncomeRate > 0) {
      _accumulator += dt * passiveIncomeRate;
      if (_accumulator >= 1.0) {
        final amount = _accumulator.floor();
        _accumulator -= amount;
        addMana(amount);
      }
    }
  }

  void addMana(int amount) {
    _mana += amount;
    _totalManaEarned += amount;
    // Debounce save?
    // For now we assume call frequency isn't insane or SharedPrefs handles it well enough for prototype.
    // Ideally we save periodically in update().
    notifyListeners();
  }

  // Fairy Interaction
  void collectFairy(FairyType type) {
    bool isNew = !_collectedFairies.contains(type);
    if (isNew) {
      _collectedFairies.add(type);
      saveState(); // Save on meaningful event
    }

    // Instant Reward
    int reward = 50 * (type.index + 1); // Basic=50, Nature=100...
    addMana(reward);
    _playSfx('sfx_success.wav'); // or chime

    notifyListeners();
  }

  bool isStructureUnlocked(StructureType type) {
    switch (type) {
      case StructureType.flower:
        return true;
      case StructureType.rock:
        return _totalManaEarned >= 0;
      case StructureType.tree:
        return _totalManaEarned >= 50;
      case StructureType.mushroomHouse:
        return _totalManaEarned >= 500;
    }
  }

  int getUnlockRequirement(StructureType type) {
    switch (type) {
      case StructureType.flower:
        return 0;
      case StructureType.rock:
        return 0;
      case StructureType.tree:
        return 50;
      case StructureType.mushroomHouse:
        return 500;
    }
  }

  bool placeStructure(StructureType type, double x, double y) {
    if (!isStructureUnlocked(type)) return false;

    final cost = getStructureCost(type);
    if (_mana >= cost) {
      _mana -= cost;
      _placedStructures.add(StructureData(type: type, x: x, y: y));
      _playSfx('sfx_plant.wav');
      saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  int getStructureCost(StructureType type) {
    switch (type) {
      case StructureType.tree:
        return 10;
      case StructureType.flower:
        return 5;
      case StructureType.mushroomHouse:
        return 50;
      case StructureType.rock:
        return 2;
    }
  }

  void toggleBuildMode() {
    _isBuildMode = !_isBuildMode;
    if (!_isBuildMode) {
      _selectedStructure = null;
    } else {
      _selectedStructure = StructureType.flower;
    }
    _playSfx('sfx_click.wav');
    notifyListeners();
  }

  void selectStructure(StructureType type) {
    if (isStructureUnlocked(type)) {
      _selectedStructure = type;
      _playSfx('sfx_click.wav');
      notifyListeners();
    }
  }

  void _playSfx(String sound) {
    try {
      GetIt.I<AudioManager>().playSfx(sound);
    } catch (_) {}
  }
}
