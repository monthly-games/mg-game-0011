import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'package:mg_common_game/core/ui/theme/app_text_styles.dart';
import 'package:mg_common_game/core/ui/overlays/pause_game_overlay.dart';
import 'package:mg_common_game/core/ui/overlays/settings_game_overlay.dart';
import 'package:mg_common_game/core/ui/overlays/tutorial_game_overlay.dart';
import '../features/forest/forest_game.dart';
import '../features/forest/game_manager.dart';
import '../features/forest/components/structure_component.dart';
import 'fairy_collection_dialog.dart';
import 'hud/mg_forest_hud.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameManager(),
      child: const MainScreenContent(),
    );
  }
}

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  State<MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  late final ForestGame _game;

  @override
  void initState() {
    super.initState();
    _game = ForestGame(gameManager: context.read<GameManager>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background: Forest Game
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'PauseGame': (context, ForestGame game) => PauseGameOverlay(
                    game: game,
                    onResume: () {
                      game.resumeEngine();
                      game.overlays.remove('PauseGame');
                    },
                    onSettings: () {
                      game.overlays.add('SettingsGame');
                    },
                    onQuit: () {
                      game.resumeEngine();
                      // Auto-save happens via SaveManagerHelper on app pause/exit generally,
                      // but we can trigger a manual save in future.
                      game.overlays.remove('PauseGame');
                    },
                  ),
              'SettingsGame': (context, ForestGame game) => SettingsGameOverlay(
                    game: game,
                    onBack: () {
                      game.overlays.remove('SettingsGame');
                    },
                  ),
              'TutorialGame': (context, ForestGame game) => TutorialGameOverlay(
                    game: game,
                    pages: const [
                      TutorialPage(
                        title: 'FAIRY FOREST',
                        content:
                            'Welcome to your magical forest!\n\nFairies collect hearts over time.',
                      ),
                      TutorialPage(
                        title: 'BUILD & GROW',
                        content:
                            'Use hearts to plant Flowers and build Houses.\n\nDecorations boost fairy happiness!',
                      ),
                      TutorialPage(
                        title: 'SOCIAL',
                        content:
                            'Visit friends to see their forests and get bonus hearts!',
                      ),
                    ],
                    onComplete: () {
                      game.overlays.remove('TutorialGame');
                      game.resumeEngine();
                    },
                  ),
            },
          ),

          // MG Forest HUD
          Consumer<GameManager>(
            builder: (context, gm, child) {
              return MGForestHud(
                mana: gm.mana,
                happiness: gm.happiness,
                fairyCount: 0, // fairies는 game 컴포넌트에서 관리
                isBuildMode: gm.isBuildMode,
                onPause: () {
                  _game.pauseEngine();
                  _game.overlays.add('PauseGame');
                },
              );
            },
          ),

          // Foreground: Bottom UI Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // HUD 공간

                const Spacer(),

                // Build Mode Selection Menu
                Consumer<GameManager>(
                  builder: (context, gm, child) {
                    if (gm.isBuildMode) {
                      return Container(
                        height: 90,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStructureOption(context, gm,
                                StructureType.tree, Icons.park, "Tree", 10),
                            _buildStructureOption(
                                context,
                                gm,
                                StructureType.flower,
                                Icons.local_florist,
                                "Flower",
                                5),
                            _buildStructureOption(
                                context,
                                gm,
                                StructureType.mushroomHouse,
                                Icons.home,
                                "House",
                                50),
                            _buildStructureOption(context, gm,
                                StructureType.rock, Icons.landscape, "Rock", 2),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Bottom Menu
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.panel.withValues(alpha: 0.9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMenuButton(context, Icons.construction, "Build",
                          () => context.read<GameManager>().toggleBuildMode()),
                      _buildMenuButton(context, Icons.people, "Social",
                          () => _showSocialDialog(context)),
                      _buildMenuButton(
                          context,
                          Icons.book,
                          "Book",
                          () => showDialog(
                              context: context,
                              builder: (_) => FairyCollectionDialog(
                                  gameManager: context.read<GameManager>()))),
                      _buildMenuButton(context, Icons.settings, "Settings", () {
                        _game.overlays.add('SettingsGame');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureOption(BuildContext context, GameManager gm,
      StructureType type, IconData icon, String label, int cost) {
    final isSelected = gm.selectedStructure == type;
    final canAfford = gm.mana >= cost;

    return GestureDetector(
      onTap: () => gm.selectStructure(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon,
                  color: canAfford ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHighEmphasis,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop,
                    size: 12, color: Colors.blueAccent),
                const SizedBox(width: 4),
                Text("$cost",
                    style: AppTextStyles.caption.copyWith(
                        color: canAfford ? Colors.blueAccent : Colors.grey,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHighEmphasis,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSocialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friend Forest Visit'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(child: Text('A')),
              title: Text('Alice\'s Garden'),
              subtitle: Text('Last active: 5m ago'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('B')),
              title: Text('Bob\'s Woods'),
              subtitle: Text('Last active: 1h ago'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
