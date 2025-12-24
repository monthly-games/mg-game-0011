import 'package:flutter/material.dart';
import '../features/forest/game_manager.dart';

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
                    ? Colors.pinkAccent.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDiscovered ? Colors.pinkAccent : Colors.grey),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDiscovered ? Icons.star : Icons.question_mark,
                    color: isDiscovered ? Colors.pinkAccent : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: isDiscovered ? Colors.black : Colors.grey),
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
