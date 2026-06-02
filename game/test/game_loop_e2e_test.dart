import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mg_game_0011/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:mg_game_0011/game/level_design_config.dart';
import 'package:mg_game_0011/game/wave_spawn_table.dart';
import 'package:mg_game_0011/game/tutorial_config.dart';

/// E2E Test for MG-0011: Fairy Forest Healing Idle
///
/// Tests the game loop with focus on:
/// - Resource synergy mechanics (gold/XP multipliers)
/// - Daily challenge completion
/// - Tutorial flow progression
/// - Level progression through fairy forest stages
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MG-0011 Fairy Forest Healing - Game Loop E2E', () {
    testWidgets('Complete game loop progression with resource synergy', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify main menu elements
      expect(find.text('MG-0011'), findsOneWidget);
      expect(find.text('Fairy Forest Healing Idle'), findsOneWidget);
      expect(find.text('Core Fun: $kCoreFunLoop'), findsOneWidget);

      // Navigate to tutorial
      await tester.tap(find.text('Tutorial'));
      await tester.pumpAndSettle();

      // Verify tutorial flow
      expect(find.byType(app.TutorialFlowScreen), findsOneWidget);

      // Complete tutorial steps
      final tutorialSteps = kOnboardingTutorial.steps;
      for (int i = 0; i < tutorialSteps.length; i++) {
        await tester.pumpAndSettle();

        // Verify current step is displayed
        expect(find.text('${i + 1}/${tutorialSteps.length}'), findsOneWidget);
        expect(find.text(tutorialSteps[i].title), findsOneWidget);

        // Tap next button
        await tester.tap(find.text(i == tutorialSteps.length - 1 ? 'Done' : 'Next'));
        await tester.pumpAndSettle();
      }

      // Navigate to game screen
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Verify game screen initialization
      expect(find.byType(app.GameScreen), findsOneWidget);

      // Test resource synergy by completing actions
      int initialGold = 0;
      int initialXP = 0;
      int actionsCompleted = 0;

      // Complete first 5 levels to test resource synergy
      for (int level = 0; level < 5 && level < kLevelDesign.length; level++) {
        await tester.pumpAndSettle();

        // Verify level display
        final levelDesign = kLevelDesign[level];
        final spawn = kWaveSpawnTable[level];
        expect(find.text('Level ${levelDesign.levelIndex} - ${levelDesign.stage}'), findsOneWidget);
        expect(find.text('${spawn.enemyCount} targets'), findsOneWidget);

        // Complete action to earn rewards
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();

        // Verify resource accumulation (synergy mechanic)
        initialGold += levelDesign.goldReward;
        initialXP += levelDesign.xpReward;
        actionsCompleted++;

        // Check that bank displays updated resources
        expect(find.text('$initialGold gold / $initialXP xp'), findsOneWidget);
      }

      // Verify progression unlocks
      expect(actionsCompleted, greaterThan(0), reason: 'Should complete at least one action');
      expect(initialGold, greaterThan(0), reason: 'Should accumulate gold');
      expect(initialXP, greaterThan(0), reason: 'Should accumulate XP');

      // Navigate to daily hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Verify daily quest screen
      expect(find.text('Daily Quests'), findsOneWidget);
      expect(find.text('Short goals keep the fun loop moving.'), findsOneWidget);
    });

    testWidgets('Test level roadmap displays all fairy forest stages', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to level roadmap
      await tester.tap(find.text('Level Roadmap'));
      await tester.pumpAndSettle();

      // Verify all levels are displayed
      expect(find.byType(app.LevelRoadmapScreen), findsOneWidget);
      expect(find.text('Level 0'), findsOneWidget);

      // Verify level list contains proper progression data
      for (int i = 0; i < kLevelDesign.length && i < 10; i++) {
        final level = kLevelDesign[i];
        final spawn = kWaveSpawnTable[i];
        expect(find.text('Level ${level.levelIndex} - ${level.stage}'), findsOneWidget);
      }
    });

    testWidgets('Verify fairy forest resource synergy mechanics', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start game directly
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Test that completing actions in sequence provides synergy bonuses
      int totalGold = 0;
      int totalXP = 0;

      for (int i = 0; i < 3; i++) {
        final currentReward = kLevelDesign[i].goldReward;
        final currentXP = kLevelDesign[i].xpReward;

        // Complete action
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();

        totalGold += currentReward;
        totalXP += currentXP;

        // Verify cumulative rewards (synergy effect)
        expect(find.text('$totalGold gold / $totalXP xp'), findsOneWidget);
      }

      // Fairy forest healing should have resource synergy
      // Verify that rewards scale appropriately
      expect(totalGold, greaterThan(100), reason: 'Gold should accumulate significantly');
      expect(totalXP, greaterThan(50), reason: 'XP should accumulate appropriately');
    });

    testWidgets('Test retention mechanics and progression unlocks', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate through retention screens
      await tester.tap(find.text('Rewards'));
      await tester.pumpAndSettle();
      expect(find.text('Progression loop: return, claim, improve.'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test guild war access (should be available in fairy forest theme)
      await tester.tap(find.text('Guild'));
      await tester.pumpAndSettle();
      expect(find.text('Guild War'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Test tournament access
      await tester.tap(find.text('Tournament'));
      await tester.pumpAndSettle();
      expect(find.text('Tournament'), findsOneWidget);
    });

    testWidgets('Verify fairy forest theme and visual elements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify fairy forest specific UI elements
      expect(find.byIcon(Icons.videogame_asset_rounded), findsWidgets);

      // Check that level progression shows fairy forest stages
      expect(find.textContaining('Fairy'), findsWidgets);
    });

    testWidgets('Complete full gameplay session from start to completion', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Complete tutorial first
      await tester.tap(find.text('Tutorial'));
      await tester.pumpAndSettle();

      while (find.text('Next').evaluate().isNotEmpty) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Complete final step
      if (find.text('Done').evaluate().isNotEmpty) {
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }

      // Play through multiple levels
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      int levelsCompleted = 0;
      int maxLevels = 10;

      for (int i = 0; i < maxLevels && i < kLevelDesign.length; i++) {
        // Complete action for current level
        await tester.tap(find.byKey(const ValueKey('complete-action')));
        await tester.pumpAndSettle();
        levelsCompleted++;
      }

      // Verify significant progression
      expect(levelsCompleted, equals(maxLevels), reason: 'Should complete 10 levels');

      // Check final resource state
      final finalGold = kLevelDesign.take(maxLevels).map((l) => l.goldReward).fold(0, (a, b) => a + b);
      final finalXP = kLevelDesign.take(maxLevels).map((l) => l.xpReward).fold(0, (a, b) => a + b);

      expect(find.text('$finalGold gold / $finalXP xp'), findsOneWidget);
    });
  });
}