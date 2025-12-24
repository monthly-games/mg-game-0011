import 'package:flame/events.dart';
import '../forest_game.dart';
import '../game_manager.dart'; // Ensure valid import for FairyType

enum FairyState { moving, resting }

class FairyComponent extends SpriteComponent
    with HasGameRef<ForestGame>, TapCallbacks {
  static final _rng = Random();
  Vector2 _targetPos = Vector2.zero();
  final double _speed = 50.0;

  FairyState _state = FairyState.moving;
  double _restTimer = 0.0;
  bool _isHidden = false;

  FairyComponent({required Vector2 position})
      : super(
            position: position, size: Vector2(30, 30), anchor: Anchor.center) {
    _setNewTarget();
  }

  @override
  Future<void> onLoad() async {
    try {
      sprite = await gameRef.loadSprite('fairy.png');
    } catch (_) {
      // Fallback to heart icon if fairy not ready
      sprite = await gameRef.loadSprite('item_heart.png');
    }
  }

  void _setNewTarget() {
    // Initial handled in update
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.size.x == 0) return;

    if (_state == FairyState.resting) {
      _restTimer -= dt;
      if (_restTimer <= 0) {
        _state = FairyState.moving;
        _pickRandomTarget();
      }
      return;
    }

    if (_targetPos == Vector2.zero() || position.distanceTo(_targetPos) < 5) {
      if (_isNearStructure()) {
        _state = FairyState.resting;
        final structure = _findNearestStructure();
        if (structure != null) {
          if (structure.type == StructureType.mushroomHouse) {
            _restTimer = 5.0;
            _isHidden = true;
            // Simple opacity hide
            paint.color = const Color(0x00FFFFFF);
          } else {
            _restTimer = 3.0;
          }
        }
      } else {
        _pickRandomTarget();
      }
    } else {
      final direction = (_targetPos - position).normalized();
      position += direction * _speed * dt;

      // Flip sprite based on direction
      if (direction.x > 0) {
        scale.x = -1.0 *
            (scale.x
                .abs()); // Face right (assuming sprite faces left or vice versa?)
        // Usually sprites face right. If sprite faces right:
        // if moving right (dir.x > 0), scale.x = 1.
        // if moving left (dir.x < 0), scale.x = -1.
        scale.x = 1.0;
      } else {
        scale.x = -1.0;
      }
    }

    // Unhide if moving
    if (_state == FairyState.moving && _isHidden) {
      _isHidden = false;
      paint.color = const Color(0xFFFFFFFF);
    }
  }

  // ... keep _findNearestStructure, _isNearStructure, _pickRandomTarget ...
  StructureComponent? _findNearestStructure() {
    try {
      final structures = gameRef.children.whereType<StructureComponent>();
      if (structures.isEmpty) return null;
      return structures.cast<StructureComponent>().firstWhere(
            (s) => s.position.distanceTo(position) < 50,
            orElse: () => structures.first,
          );
    } catch (e) {
      return null;
    }
  }

  bool _isNearStructure() {
    final s = _findNearestStructure();
    if (s == null) return false;
    return s.position.distanceTo(position) < 50;
  }

  void _pickRandomTarget() {
    final structures =
        gameRef.children.whereType<StructureComponent>().toList();

    if (structures.isNotEmpty && _rng.nextDouble() < 0.3) {
      final targetStructure = structures[_rng.nextInt(structures.length)];
      _targetPos = targetStructure.position - Vector2(0, 20);
    } else {
      final x = _rng.nextDouble() * (gameRef.size.x - 50) + 25;
      final y = _rng.nextDouble() * (gameRef.size.y - 150) + 100;
      _targetPos = Vector2(x, y);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Collection Logic
    gameRef.gameManager.collectFairy(FairyType.basic); // For now just basic

    // Feedback: Teleport to new random spot immediately
    _pickRandomTarget();
    position = _targetPos;
    // Ideally play a particle effect here
    event.handled = true;
  }
}
