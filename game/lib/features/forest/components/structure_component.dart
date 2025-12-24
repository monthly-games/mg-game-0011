import 'package:flame/components.dart';

enum StructureType {
  tree,
  flower,
  mushroomHouse,
  rock, // NEW
}

class StructureComponent extends SpriteComponent {
  final StructureType type;

  StructureComponent({required this.type, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case StructureType.tree:
        sprite = await findGame()!.loadSprite('structure_tree.png');
        size = Vector2(80, 80);
        break;
      case StructureType.flower:
        sprite = await findGame()!.loadSprite('structure_flower.png');
        size = Vector2(40, 40);
        break;
      case StructureType.rock: // NEW
        // Fallback to tree if rock png missing, or use house if available.
        // Assuming we rely on placeholders.
        try {
          sprite = await findGame()!.loadSprite('structure_rock.png');
        } catch (_) {
          // Invisible or placeholder
          sprite = await findGame()!.loadSprite('structure_tree.png');
        }
        size = Vector2(50, 50);
        break;
      case StructureType.mushroomHouse:
        try {
          sprite = await findGame()!.loadSprite('structure_house.png');
        } catch (e) {
          sprite =
              await findGame()!.loadSprite('structure_tree.png'); // Placeholder
        }
        size = Vector2(100, 100);
        break;
    }
  }
}
