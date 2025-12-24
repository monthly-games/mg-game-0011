import 'package:flutter/material.dart';
import '../systems/forest_manager.dart';
import '../core/models/decoration.dart';

class ForestView extends StatefulWidget {
  final ForestManager forestManager;
  final Function(TapUpDetails, double, double) onForestTap;

  const ForestView({
    super.key,
    required this.forestManager,
    required this.onForestTap,
  });

  @override
  State<ForestView> createState() => _ForestViewState();
}

class _ForestViewState extends State<ForestView> {
  final TransformationController _transformController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    // Forest Size (Virtual Canvas)
    const double forestWidth = 2000.0;
    const double forestHeight = 2000.0;

    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: 0.2,
      maxScale: 2.0,
      constrained: false, // Allow infinite canvas inside
      onInteractionEnd: (_) {
        // Could save camera position here
      },
      child: GestureDetector(
        onTapUp: (details) {
          // Convert viewport tap to local coordinate
          // Actually GestureDetector is inside InteractiveViewer, so 'details.localPosition'
          // is effectively relative to the child (Container).
          widget.onForestTap(
              details, details.localPosition.dx, details.localPosition.dy);
        },
        child: Container(
          width: forestWidth,
          height: forestHeight,
          decoration: BoxDecoration(
            color: Colors.green[100], // Grass
            image: const DecorationImage(
              image: NetworkImage(
                  'https://placeholder.com/grass.png'), // Helper or solid color
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Stack(
            children: [
              // Grid lines (Optional, for debug)

              // Render Decorations
              ...widget.forestManager.decorations.map((deco) {
                return Positioned(
                  left: deco.x - 32, // Center anchor
                  top: deco.y - 64, // Bottom anchor
                  child: _buildDecorationWidget(deco),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorationWidget(Decoration deco) {
    Color color;
    IconData icon;

    switch (deco.type) {
      case DecorationType.tree:
        color = Colors.green[800]!;
        icon = Icons.park;
        break;
      case DecorationType.flower:
        color = Colors.pink;
        icon = Icons.local_florist;
        break;
      case DecorationType.rock:
        color = Colors.grey;
        icon = Icons.landscape;
        break;
      case DecorationType.house:
        color = Colors.brown;
        icon = Icons.house;
        break;
    }

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        // Shadow
        Container(
          width: 40,
          height: 10,
          decoration: BoxDecoration(
              color: Colors.black26, borderRadius: BorderRadius.circular(10)),
        )
      ],
    );
  }
}
