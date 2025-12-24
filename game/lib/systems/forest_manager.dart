import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/decoration.dart';

class ForestManager extends ChangeNotifier {
  double _mana = 100.0;
  final List<Decoration> _decorations = [];
  Timer? _productionTimer;

  // Placement State
  bool _isPlacementMode = false;
  Decoration? _selectedForPlacement;

  double get mana => _mana;
  List<Decoration> get decorations => List.unmodifiable(_decorations);
  bool get isPlacementMode => _isPlacementMode;

  ForestManager() {
    _startProduction();
  }

  void _startProduction() {
    _productionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _produceMana();
    });
  }

  void _produceMana() {
    double production = 0;
    for (final deco in _decorations) {
      production += deco.manaProduction;
    }
    if (production > 0) {
      _mana += production;
      notifyListeners();
    }
  }

  // --- Actions ---

  void startPlacement(Decoration prototype) {
    if (_mana >= prototype.cost) {
      _selectedForPlacement = prototype;
      _isPlacementMode = true;
      notifyListeners();
    }
  }

  void cancelPlacement() {
    _isPlacementMode = false;
    _selectedForPlacement = null;
    notifyListeners();
  }

  void confirmPlacement(double x, double y) {
    if (_selectedForPlacement != null && _mana >= _selectedForPlacement!.cost) {
      _mana -= _selectedForPlacement!.cost;

      // Create new instance at location
      final newDeco = _selectedForPlacement!.copyWith(x: x, y: y);
      _decorations.add(newDeco);

      _isPlacementMode = false;
      _selectedForPlacement = null;
      notifyListeners();
    }
  }
}
