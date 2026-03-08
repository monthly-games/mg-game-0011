import 'package:flutter/material.dart';
import '../features/forest/game_manager.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';

class FairyCollectionDialog extends StatelessWidget {
  final GameManager gameManager;

  const FairyCollectionDialog({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Fairy Collection"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: FairyType.values.length,
          itemBuilder: (context, index) {
            final type = FairyType.values[index];
            final isDiscovered = gameManager.collectedFairies.contains(type);

            return Container(
              decoration: BoxDecoration(
                color: isDiscovered
                    ? Colors.pinkAccent.withValues(alpha: 0.1)
                    : MGColors.common.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDiscovered ? Colors.pinkAccent : MGColors.common),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDiscovered ? Icons.star : Icons.question_mark,
                    color: isDiscovered ? Colors.pinkAccent : MGColors.common,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isDiscovered ? Colors.black : MGColors.common),
                  )
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        )
      ],
    );
  }
}
