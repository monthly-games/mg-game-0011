import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// MG UI 기반 페어리 포레스트 HUD
/// mg_common_game의 공통 UI 컴포넌트 활용
class MGForestHud extends StatelessWidget {
  final int mana;
  final double happiness;
  final int fairyCount;
  final bool isBuildMode;
  final VoidCallback? onPause;
  final VoidCallback? onBuildToggle;

  const MGForestHud({
    super.key,
    required this.mana,
    this.happiness = 1.0,
    this.fairyCount = 0,
    this.isBuildMode = false,
    this.onPause,
    this.onBuildToggle,
  });

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return Positioned.fill(
      child: Column(
        children: [
          // 상단 HUD: 마나 + 행복도 + 일시정지
          Container(
            padding: EdgeInsets.only(
              top: safeArea.top + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 마나 표시
                _buildManaDisplay(),

                // 행복도 표시
                _buildHappinessDisplay(),

                // 요정 수 표시
                _buildFairyCount(),

                // 일시정지 버튼
                MGIconButton(
                  icon: Icons.pause,
                  onPressed: onPause,
                  size: 44,
                  backgroundColor: Colors.black54,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // 중앙 영역 확장 (게임 영역)
          const Expanded(child: SizedBox()),

          // 빌드 모드 표시
          if (isBuildMode)
            Container(
              padding: EdgeInsets.only(
                bottom: safeArea.bottom + MGSpacing.hudMargin,
                left: safeArea.left + MGSpacing.hudMargin,
                right: safeArea.right + MGSpacing.hudMargin,
              ),
              child: _buildModeIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildManaDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.water_drop,
            color: Colors.blueAccent,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            _formatNumber(mana),
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHappinessDisplay() {
    final happinessPercent = (happiness * 100).toInt();
    final isLow = happiness < 0.5;
    final isMedium = happiness >= 0.5 && happiness < 0.8;

    Color color;
    IconData icon;
    if (isLow) {
      color = Colors.red;
      icon = Icons.sentiment_dissatisfied;
    } else if (isMedium) {
      color = Colors.orange;
      icon = Icons.sentiment_neutral;
    } else {
      color = Colors.pinkAccent;
      icon = Icons.sentiment_satisfied_alt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            '$happinessPercent%',
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFairyCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.purple,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            '$fairyCount',
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.construction,
            color: Colors.white,
            size: 24,
          ),
          MGSpacing.hSm,
          Text(
            'BUILD MODE',
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
