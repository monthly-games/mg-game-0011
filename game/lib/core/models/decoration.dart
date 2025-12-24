enum DecorationType { tree, flower, rock, house }

class Decoration {
  final String id;
  final DecorationType type;
  final String name;
  final double x;
  final double y;
  final int manaProduction; // Per second
  final int cost;
  final String
      assetPath; // Ideally we use an ID/Enum map, but string path is easy for prototyping

  Decoration({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
    this.manaProduction = 1,
    this.cost = 10,
    this.assetPath = '',
  });

  Decoration copyWith({double? x, double? y}) {
    return Decoration(
      id: id,
      type: type,
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      manaProduction: manaProduction,
      cost: cost,
      assetPath: assetPath,
    );
  }
}
