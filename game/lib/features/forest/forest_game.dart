import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'components/fairy_component.dart';
import 'components/structure_component.dart';
import 'components/heart_effect_component.dart';
import 'game_manager.dart';

class ForestGame extends FlameGame with TapCallbacks {
  final GameManager gameManager;

  ForestGame({required this.gameManager});

  Color backgroundColor() => const Color(0xFFC8E6C9);

  @override
  Future<void> onLoad() async {
    // Background
    add(SpriteComponent()
      ..sprite = await loadSprite('bg_forest.png')
      ..size = size);

    // Load Data
    await gameManager.loadState();

    // Restore Structures
    for (final data in gameManager.placedStructures) {
      add(StructureComponent(
        type: data.type,
        position: Vector2(data.x, data.y),
      ));
    }

    // Add some initial fairies
    for (int i = 0; i < 5; i++) {
      // Simple random movement or just static for now
      add(FairyComponent(position: Vector2(100.0 * (i + 1), 300)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    gameManager.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameManager.isBuildMode && gameManager.selectedStructure != null) {
      // Build Mode: Place structure
      if (gameManager.placeStructure(gameManager.selectedStructure!,
          event.localPosition.x, event.localPosition.y)) {
        add(StructureComponent(
          type: gameManager.selectedStructure!,
          position: event.localPosition,
        ));
      } else {
        debugPrint("Not enough Mana!");
      }
    } else {
      // Normal Mode: Tap to earn mana (Manual Harvest)
      gameManager.addMana(1);
      _playSfx('sfx_coin.wav');
      add(HeartEffectComponent(position: event.localPosition));
    }
  }

  void _playSfx(String sound) {
    try {
      GetIt.I<AudioManager>().playSfx(sound);
    } catch (_) {}
  }
}
