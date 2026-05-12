// ============================================================
// Daily Quest Screen -- MG-0011 Healing Forest
// Genre: Idle · Retention System UI
//
// Firebase Analytics Events:
//   - daily_quest_screen_viewed: Screen view tracking
//   - daily_quest_completed:  {quest_id, reward_claimed} on completion
//   - daily_quest_reward_claimed: {quest_id, quest_title, gold_reward, xp_reward}
//   - daily_quest_all_completed: All quests done
//
// Template: Based on MG-0010 canonical template.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/systems/quests/daily_quest.dart';

/// Daily Quest screen for MG-0011 Healing Forest.
///
/// Displays daily quests with progress tracking, reward claiming,
/// and reset timer countdown.
class DailyQuestScreen extends StatefulWidget {
  const DailyQuestScreen({super.key});

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  late final DailyQuestManager _questManager;
  late Timer _resetTimer;
  Duration _timeUntilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _questManager = GetIt.I<DailyQuestManager>();
    _questManager.addListener(_onQuestUpdate);
    _questManager.checkAndResetIfNeeded();
    _startResetTimer();

    FirebaseAnalytics.instance.logEvent(
      name: 'daily_quest_screen_viewed',
    );
  }

  @override
  void dispose() {
    _resetTimer.cancel();
    _questManager.removeListener(_onQuestUpdate);
    super.dispose();
  }

  void _onQuestUpdate() {
    if (mounted) setState(() {});
  }

  void _startResetTimer() {
    _updateTimeUntilReset();
    _resetTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeUntilReset(),
    );
  }

  void _updateTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (mounted) {
      setState(() {
        _timeUntilReset = tomorrow.difference(now);
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _claimReward(DailyQuest quest) {
    final claimed = _questManager.claimQuestReward(quest.id);
    if (!claimed) return;

    FirebaseAnalytics.instance.logEvent(
      name: 'daily_quest_completed',
      parameters: {
        'quest_id': quest.id,
        'reward_claimed': true,
      },
    );

    FirebaseAnalytics.instance.logEvent(
      name: 'daily_quest_reward_claimed',
      parameters: {
        'quest_id': quest.id,
        'quest_title': quest.title,
        'gold_reward': quest.goldReward,
        'xp_reward': quest.xpReward,
      },
    );

    if (_questManager.completedQuestCount ==
        _questManager.totalQuestCount) {
      FirebaseAnalytics.instance.logEvent(
        name: 'daily_quest_all_completed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quests = _questManager.allQuests;
    final completedCount = _questManager.completedQuestCount;
    final totalCount = _questManager.totalQuestCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Quests',
          style: MGTextStyles.h2.copyWith(
            color: MGColors.textHighEmphasis,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: quests.isEmpty
          ? _buildEmptyState()
          : _buildQuestList(quests, completedCount, totalCount),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_late_rounded,
            size: MGSpacing.xxl,
            color: MGColors.textDisabled,
          ),
          MGSpacing.vMd,
          Text(
            'No quests available',
            style: MGTextStyles.h3.copyWith(
              color: MGColors.textDisabled,
            ),
          ),
          MGSpacing.vXs,
          Text(
            'Check back tomorrow!',
            style: MGTextStyles.bodySmall.copyWith(
              color: MGColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestList(
    List<DailyQuest> quests,
    int completedCount,
    int totalCount,
  ) {
    return Padding(
      padding: MGSpacing.horizontal(MGSpacing.md),
      child: Column(
        children: [
          MGSpacing.vMd,
          _buildHeader(completedCount, totalCount),
          MGSpacing.vLg,
          Expanded(
            child: ListView.builder(
              itemCount: quests.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < quests.length - 1
                        ? MGSpacing.sm
                        : 0,
                  ),
                  child: _buildQuestCard(quests[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int completedCount, int totalCount) {
    return MGCard(
      backgroundColor: MGColors.surfaceDark,
      borderColor: MGColors.border,
      borderWidth: 1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: MGTextStyles.caption.copyWith(
                    color: MGColors.textMediumEmphasis,
                  ),
                ),
                MGSpacing.vXxs,
                Text(
                  '$completedCount / $totalCount completed',
                  style: MGTextStyles.h3.copyWith(
                    color: completedCount == totalCount
                        ? MGColors.success
                        : MGColors.textHighEmphasis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: MGSpacing.symmetric(
              horizontal: MGSpacing.sm,
              vertical: MGSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: MGColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(MGSpacing.xs),
            ),
            child: Column(
              children: [
                Text(
                  'RESETS IN',
                  style: MGTextStyles.caption.copyWith(
                    color: MGColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MGSpacing.vXxs,
                Text(
                  _formatDuration(_timeUntilReset),
                  style: MGTextStyles.hud.copyWith(
                    color: MGColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(DailyQuest quest) {
    final isClaimable = quest.isCompleted && !quest.isClaimedReward;
    final isClaimed = quest.isClaimedReward;

    return MGCard(
      backgroundColor: MGColors.cardDark,
      borderColor: isClaimable
          ? MGColors.success.withValues(alpha: 0.6)
          : MGColors.border,
      borderWidth: isClaimable ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildQuestIcon(isClaimed),
              MGSpacing.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: MGTextStyles.body.copyWith(
                        color: isClaimed
                            ? MGColors.textDisabled
                            : MGColors.textHighEmphasis,
                        fontWeight: FontWeight.w600,
                        decoration: isClaimed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      quest.description,
                      style: MGTextStyles.caption.copyWith(
                        color: MGColors.textMediumEmphasis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRewardBadge(quest),
            ],
          ),
          MGSpacing.vSm,
          MGLinearProgress(
            value: quest.progressPercentage,
            valueColor: isClaimed || isClaimable
                ? MGColors.success
                : MGColors.primaryAction,
            height: 6,
            borderRadius: 3,
          ),
          MGSpacing.vXxs,
          Row(
            children: [
              Text(
                '${quest.currentProgress} / ${quest.targetValue}',
                style: MGTextStyles.caption.copyWith(
                  color: MGColors.textMediumEmphasis,
                ),
              ),
              const Spacer(),
              if (isClaimable)
                MGButton(
                  label: 'Claim ${quest.goldReward} gold',
                  size: MGButtonSize.small,
                  icon: Icons.card_giftcard_rounded,
                  backgroundColor: MGColors.success,
                  foregroundColor: MGColors.textHighEmphasis,
                  onPressed: () => _claimReward(quest),
                )
              else if (isClaimed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: MGIcons.badgeSize,
                      color: MGColors.success,
                    ),
                    MGSpacing.hXxs,
                    Text(
                      'Claimed',
                      style: MGTextStyles.caption.copyWith(
                        color: MGColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestIcon(bool isClaimed) {
    return Container(
      width: MGSpacing.xl,
      height: MGSpacing.xl,
      decoration: BoxDecoration(
        color: isClaimed
            ? MGColors.success.withValues(alpha: 0.2)
            : MGColors.primaryAction.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(MGSpacing.xs),
      ),
      child: Icon(
        isClaimed
            ? Icons.check_circle_rounded
            : MGIcons.navQuest,
        color: isClaimed ? MGColors.success : MGColors.primaryAction,
        size: MGIcons.listItemSize,
      ),
    );
  }

  Widget _buildRewardBadge(DailyQuest quest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              size: MGIcons.badgeSize,
              color: MGColors.gold,
            ),
            MGSpacing.hXxs,
            Text(
              '${quest.goldReward}',
              style: MGTextStyles.hudSmall.copyWith(
                color: MGColors.gold,
              ),
            ),
          ],
        ),
        MGSpacing.vXxs,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: MGIcons.badgeSize,
              color: MGColors.exp,
            ),
            MGSpacing.hXxs,
            Text(
              '${quest.xpReward} XP',
              style: MGTextStyles.hudSmall.copyWith(
                color: MGColors.exp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
