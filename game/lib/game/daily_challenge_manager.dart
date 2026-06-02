import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily challenges for MG-0011.
///
/// Provides rotating daily objectives across all game systems:
/// - Healing challenges (heal X patients)
/// - Garden challenges (harvest Y herbs)
/// - Combo challenges (reach Z combo chain)
/// Resets daily at midnight and rewards completion.
class DailyChallengeManager extends ChangeNotifier {
  static const String _kChallengesKey = 'daily_challenges';
  static const String _kLastResetDateKey = 'daily_challenges_last_reset';
  static const String _kCompletionCountKey = 'daily_challenges_completed';

  /// Daily reset hour (24-hour format).
  static const int kResetHour = 0;

  // Challenge state
  List<DailyChallenge> _challenges = [];
  DateTime? _lastResetDate;
  int _totalCompleted = 0;
  Timer? _resetTimer;

  // ── Getters ────────────────────────────────────────────────

  List<DailyChallenge> get challenges => List.unmodifiable(_challenges);
  int get completedCount =>
      _challenges.where((c) => c.isCompleted).length;
  int get totalCount => _challenges.length;
  double get completionProgress =>
      totalCount > 0 ? completedCount / totalCount : 0.0;
  int get totalCompleted => _totalCompleted;
  bool get allCompleted => completedCount == totalCount && totalCount > 0;

  /// Total gold reward available from unclaimed challenges.
  int get unclaimedGold {
    return _challenges
        .where((c) => c.isCompleted && !c.isClaimed)
        .fold(0, (sum, c) => sum + c.goldReward);
  }

  /// Total gem reward available from unclaimed challenges.
  int get unclaimedGems {
    return _challenges
        .where((c) => c.isCompleted && !c.isClaimed)
        .fold(0, (sum, c) => sum + c.gemReward);
  }

  DailyChallengeManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadState();
    _checkDailyReset();
    _scheduleNextReset();
  }

  // ── Challenge Generation ───────────────────────────────────

  /// Generate a new set of daily challenges.
  List<DailyChallenge> _generateDailyChallenges() {
    final now = DateTime.now();
    final seed = now.day + now.month * 31 + now.year * 372;
    final random = _SeededRandom(seed);

    return [
      // Healing challenge
      DailyChallenge(
        id: 'heal_patients_${now.millisecondsSinceEpoch}',
        type: ChallengeType.healing,
        title: 'Healer\'s Duty',
        description: 'Heal ${random.nextInt(5) + 5} patients',
        target: random.nextInt(5) + 5,
        current: 0,
        goldReward: 100,
        gemReward: 5,
      ),

      // Garden challenge
      DailyChallenge(
        id: 'harvest_herbs_${now.millisecondsSinceEpoch}',
        type: ChallengeType.garden,
        title: 'Bountiful Harvest',
        description: 'Harvest ${random.nextInt(8) + 8} herbs',
        target: random.nextInt(8) + 8,
        current: 0,
        goldReward: 80,
        gemReward: 3,
      ),

      // Combo challenge
      DailyChallenge(
        id: 'reach_combo_${now.millisecondsSinceEpoch}',
        type: ChallengeType.combo,
        title: 'Chain Master',
        description: 'Reach a ${random.nextInt(3) + 5}x combo',
        target: random.nextInt(3) + 5,
        current: 0,
        goldReward: 120,
        gemReward: 8,
      ),

      // Synergy challenge
      DailyChallenge(
        id: 'synergy_activations_${now.millisecondsSinceEpoch}',
        type: ChallengeType.synergy,
        title: 'Perfect Harmony',
        description: 'Activate ${random.nextInt(3) + 3} synergies',
        target: random.nextInt(3) + 3,
        current: 0,
        goldReward: 150,
        gemReward: 10,
      ),
    ];
  }

  // ── Progress Tracking ──────────────────────────────────────

  /// Update progress for a specific challenge type.
  void updateProgress(ChallengeType type, {required int amount}) {
    bool changed = false;
    for (final challenge in _challenges) {
      if (challenge.type == type && !challenge.isCompleted) {
        challenge.current = (challenge.current + amount).clamp(0, challenge.target);
        if (challenge.isCompleted) {
          _totalCompleted++;
        }
        changed = true;
      }
    }
    if (changed) {
      _saveState();
      notifyListeners();
    }
  }

  /// Track a patient being healed.
  void trackPatientHealed() {
    updateProgress(ChallengeType.healing, amount: 1);
  }

  /// Track a herb being harvested.
  void trackHerbHarvested() {
    updateProgress(ChallengeType.garden, amount: 1);
  }

  /// Track combo chain reached.
  void trackComboReached(int comboLevel) {
    for (final challenge in _challenges) {
      if (challenge.type == ChallengeType.combo && !challenge.isCompleted) {
        if (comboLevel >= challenge.target) {
          challenge.current = challenge.target;
          if (challenge.isCompleted) {
            _totalCompleted++;
          }
          _saveState();
          notifyListeners();
        }
      }
    }
  }

  /// Track synergy activation.
  void trackSynergyActivated() {
    updateProgress(ChallengeType.synergy, amount: 1);
  }

  /// Claim rewards for completed challenges.
  List<DailyChallenge> claimRewards() {
    final claimed = <DailyChallenge>[];
    for (final challenge in _challenges) {
      if (challenge.isCompleted && !challenge.isClaimed) {
        challenge.isClaimed = true;
        claimed.add(challenge);
      }
    }
    if (claimed.isNotEmpty) {
      _saveState();
      notifyListeners();
    }
    return claimed;
  }

  // ── Daily Reset ────────────────────────────────────────────

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _performDailyReset();
    }
  }

  void _performDailyReset() {
    final now = DateTime.now();
    _lastResetDate = DateTime(now.year, now.month, now.day);
    _challenges = _generateDailyChallenges();
    _saveState();
    notifyListeners();
  }

  void _scheduleNextReset() {
    final now = DateTime.now();
    final nextReset = DateTime(
      now.year,
      now.month,
      now.day,
      kResetHour,
      0,
      0,
    ).add(const Duration(days: 1));

    final duration = nextReset.difference(now);
    _resetTimer = Timer(duration, () {
      _performDailyReset();
      _scheduleNextReset();
    });
  }

  // ── Persistence ────────────────────────────────────────────

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final challengesJson = prefs.getString(_kChallengesKey);
    final lastResetMillis = prefs.getInt(_kLastResetDateKey);
    final completed = prefs.getInt(_kCompletionCountKey) ?? 0;

    if (challengesJson != null) {
      _challenges = (challengesJson as String)
          .split('|')
          .where((s) => s.isNotEmpty)
          .map((json) => DailyChallenge.fromString(json))
          .toList();
    }

    if (lastResetMillis != null) {
      _lastResetDate = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);
    }

    _totalCompleted = completed;
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final challengesJson = _challenges.map((c) => c.toString()).join('|');
    await prefs.setString(_kChallengesKey, challengesJson);
    if (_lastResetDate != null) {
      await prefs.setInt(
        _kLastResetDateKey,
        _lastResetDate!.millisecondsSinceEpoch,
      );
    }
    await prefs.setInt(_kCompletionCountKey, _totalCompleted);
  }

  /// Reset all challenge state (for testing).
  void reset() {
    _challenges.clear();
    _lastResetDate = null;
    _totalCompleted = 0;
    _resetTimer?.cancel();
    _resetTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}

/// Type of daily challenge objective.
enum ChallengeType {
  healing,
  garden,
  combo,
  synergy,
}

/// A single daily challenge with progress tracking.
class DailyChallenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final int target;
  int current;
  final int goldReward;
  final int gemReward;
  bool isClaimed;

  DailyChallenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.goldReward,
    required this.gemReward,
    this.isClaimed = false,
  });

  /// Progress from 0.0 to 1.0.
  double get progress => target > 0 ? current / target : 0.0;

  /// Check if challenge objective is met.
  bool get isCompleted => current >= target;

  /// Check if rewards can be claimed.
  bool get canClaim => isCompleted && !isClaimed;

  /// Serialize to string for persistence.
  String toString() {
    return '$id|${type.name}|$title|$description|$target|$current|$goldReward|$gemReward|${isClaimed ? 1 : 0}';
  }

  /// Deserialize from string.
  factory DailyChallenge.fromString(String data) {
    final parts = data.split('|');
    return DailyChallenge(
      id: parts[0],
      type: ChallengeType.values.firstWhere((e) => e.name == parts[1]),
      title: parts[2],
      description: parts[3],
      target: int.parse(parts[4]),
      current: int.parse(parts[5]),
      goldReward: int.parse(parts[6]),
      gemReward: int.parse(parts[7]),
      isClaimed: parts[8] == '1',
    );
  }
}

/// Simple seeded random for consistent daily challenges.
class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}
