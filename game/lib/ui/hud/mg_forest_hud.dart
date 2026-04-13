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
  final VoidCallback? onDailyHub;
  final VoidCallback? onGuildWar;
  final VoidCallback? onTournament;
  final VoidCallback? onSeasonalEvent;

  const MGForestHud({
    super.key,
    required this.mana,
    this.happiness = 1.0,
    this.fairyCount = 0,
    this.isBuildMode = false,
    this.onPause,
    this.onBuildToggle,
    this.onDailyHub,
    this.onGuildWar,
    this.onTournament,
    this.onSeasonalEvent,
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 마나 표시
                  _buildManaDisplay(),

                  MGSpacing.hSm,

                  // 행복도 표시
                  _buildHappinessDisplay(),

                  MGSpacing.hSm,

                  // 요정 수 표시
                  _buildFairyCount(),

                  const Spacer(),

                  // 일시정지 버튼
          if (onGuildWar != null)
            MGIconButton(
              icon: Icons.shield,
              onPressed: onGuildWar,
              size: 40,
              backgroundColor: MGColors.info.withValues(alpha: 0.8),
              color: MGColors.textHighEmphasis,
              tooltip: 'Guild War',
            ),
          if (onTournament != null)
            MGIconButton(
              icon: Icons.emoji_events,
              onPressed: onTournament,
              size: 40,
              backgroundColor: MGColors.info.withValues(alpha: 0.8),
              color: MGColors.textHighEmphasis,
              tooltip: 'Tournament',
            ),
          if (onSeasonalEvent != null)
            MGIconButton(
              icon: Icons.celebration,
              onPressed: onSeasonalEvent,
              size: 40,
              backgroundColor: MGColors.info.withValues(alpha: 0.8),
              color: MGColors.textHighEmphasis,
              tooltip: 'Seasonal Event',
            ),
          if (onDailyHub != null)
            MGIconButton(
              icon: Icons.calendar_today,
              onPressed: onDailyHub,
              size: 40,
              backgroundColor: MGColors.info.withValues(alpha: 0.8),
              color: MGColors.textHighEmphasis,
              tooltip: 'Daily Hub',
            ),
                  MGIconButton(
                    icon: Icons.pause,
                    onPressed: onPause,
                    size: 40,
                    backgroundColor: Colors.black54,
                    color: MGColors.textHighEmphasis,
                  ),
                ],
              ),
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
              color: MGColors.textHighEmphasis,
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
      color = MGColors.error;
      icon = Icons.sentiment_dissatisfied;
    } else if (isMedium) {
      color = MGColors.warning;
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
              color: MGColors.textHighEmphasis,
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
              color: MGColors.textHighEmphasis,
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
        color: MGColors.success.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MGColors.success.withValues(alpha: 0.4),
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
            color: MGColors.textHighEmphasis,
            size: 24,
          ),
          MGSpacing.hSm,
          Text(
            'BUILD MODE',
            style: MGTextStyles.hud.copyWith(
              color: MGColors.textHighEmphasis,
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
