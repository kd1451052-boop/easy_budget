import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String id;
  final IconData iconData;
  final int targetProgress;
  int currentProgress;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.iconData,
    required this.targetProgress,
    this.currentProgress = 0,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentProgress': currentProgress,
        'isUnlocked': isUnlocked,
      };
}

class StreakMilestone {
  final String id;
  final int targetDays;
  final String title;
  final String subtitle;
  final String rewardLabel;
  final IconData icon;
  final Color accentColor;
  bool isRewardClaimed;

  StreakMilestone({
    required this.id,
    required this.targetDays,
    required this.title,
    required this.subtitle,
    required this.rewardLabel,
    required this.icon,
    required this.accentColor,
    this.isRewardClaimed = false,
  });
}

class GamificationProvider with ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate;
  final Set<String> _activeDates = {};
  Future<void>? _loadFuture;

  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_expense',
      iconData: Icons.monetization_on,
      targetProgress: 1,
    ),
    Achievement(
      id: 'receipt_master_10',
      iconData: Icons.receipt_long,
      targetProgress: 10,
    ),
    Achievement(
      id: 'streak_7_days',
      iconData: Icons.local_fire_department,
      targetProgress: 7,
    ),
  ];

  // Streak goals/milestones for the Duolingo-style Streak Page.
  // TODO(reward-system): Connect each milestone to actual unlockable rewards
  // (e.g., Streak Freeze items, bonus XP/coins, exclusive avatar frames, or themes).
  final List<StreakMilestone> _streakMilestones = [
    StreakMilestone(
      id: 'streak_goal_3',
      targetDays: 3,
      title: '3-Day Spark',
      subtitle: 'Build the daily budgeting habit',
      rewardLabel: 'Spark Badge (Coming Soon)',
      icon: Icons.bolt_rounded,
      accentColor: const Color(0xFFF59E0B),
    ),
    StreakMilestone(
      id: 'streak_goal_7',
      targetDays: 7,
      title: '1-Week Warrior',
      subtitle: 'Complete a full week of tracking',
      rewardLabel: 'Golden Flame Frame (Coming Soon)',
      icon: Icons.local_fire_department_rounded,
      accentColor: const Color(0xFFFF6B00),
    ),
    StreakMilestone(
      id: 'streak_goal_14',
      targetDays: 14,
      title: '2-Week Consistency',
      subtitle: 'Two weeks of unstoppable momentum',
      rewardLabel: '1x Streak Freeze (Coming Soon)',
      icon: Icons.ac_unit_rounded,
      accentColor: const Color(0xFF3B82F6),
    ),
    StreakMilestone(
      id: 'streak_goal_30',
      targetDays: 30,
      title: '30-Day Master',
      subtitle: 'A full month of financial mindfulness',
      rewardLabel: 'Emerald Crown (Coming Soon)',
      icon: Icons.workspace_premium_rounded,
      accentColor: const Color(0xFF10B981),
    ),
    StreakMilestone(
      id: 'streak_goal_60',
      targetDays: 60,
      title: '60-Day Champion',
      subtitle: 'Two months of streak mastery',
      rewardLabel: 'Diamond Theme (Coming Soon)',
      icon: Icons.diamond_rounded,
      accentColor: const Color(0xFF8B5CF6),
    ),
    StreakMilestone(
      id: 'streak_goal_100',
      targetDays: 100,
      title: '100-Day Legend',
      subtitle: 'Join the 100-Day Streak Society',
      rewardLabel: 'Legendary Chest (Coming Soon)',
      icon: Icons.emoji_events_rounded,
      accentColor: const Color(0xFFEC4899),
    ),
  ];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastActiveDate => _lastActiveDate;
  Set<String> get activeDates => Set.unmodifiable(_activeDates);
  List<Achievement> get achievements => _achievements;
  List<StreakMilestone> get streakMilestones => _streakMilestones;

  // Function to call when we want to trigger confetti
  Function()? onAchievementUnlocked;

  GamificationProvider() {
    _loadFuture = _loadData();
  }

  static String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isDayActive(DateTime date) {
    final key = _formatDateKey(date);
    if (_activeDates.contains(key)) return true;

    // Fallback: if _lastActiveDate and _currentStreak cover this date, treat as active
    if (_lastActiveDate != null && _currentStreak > 0) {
      final targetDay = DateTime(date.year, date.month, date.day);
      final lastDay = DateTime(
        _lastActiveDate!.year,
        _lastActiveDate!.month,
        _lastActiveDate!.day,
      );
      final diff = lastDay.difference(targetDay).inDays;
      if (diff >= 0 && diff < _currentStreak) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load streak data
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    _longestStreak = prefs.getInt('longestStreak') ?? _currentStreak;
    final lastActiveString = prefs.getString('lastActiveDate');
    if (lastActiveString != null) {
      _lastActiveDate = DateTime.tryParse(lastActiveString);
    }

    final savedDates = prefs.getStringList('activeDates') ?? const <String>[];
    _activeDates
      ..clear()
      ..addAll(savedDates);

    // Load achievements data
    for (var achievement in _achievements) {
      achievement.currentProgress =
          prefs.getInt('ach_prog_${achievement.id}') ?? 0;
      achievement.isUnlocked =
          prefs.getBool('ach_unlocked_${achievement.id}') ?? false;
    }

    // TODO(reward-system): Load claimed status for each streak milestone reward
    for (var milestone in _streakMilestones) {
      milestone.isRewardClaimed =
          prefs.getBool('streak_reward_claimed_${milestone.id}') ?? false;
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('longestStreak', _longestStreak);
    if (_lastActiveDate != null) {
      await prefs.setString(
        'lastActiveDate',
        _lastActiveDate!.toIso8601String(),
      );
    }
    await prefs.setStringList('activeDates', _activeDates.toList());

    for (var achievement in _achievements) {
      await prefs.setInt(
        'ach_prog_${achievement.id}',
        achievement.currentProgress,
      );
      await prefs.setBool(
        'ach_unlocked_${achievement.id}',
        achievement.isUnlocked,
      );
    }

    // TODO(reward-system): Persist claimed milestone rewards in SharedPreferences/Firestore
    for (var milestone in _streakMilestones) {
      await prefs.setBool(
        'streak_reward_claimed_${milestone.id}',
        milestone.isRewardClaimed,
      );
    }
  }

  Future<void> checkAppOpened() async {
    // Wait for initial SharedPreferences load to finish so we don't race with _loadData()
    if (_loadFuture != null) {
      await _loadFuture;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _formatDateKey(today);
    bool changed = false;

    if (!_activeDates.contains(todayKey)) {
      _activeDates.add(todayKey);
      changed = true;
    }

    if (_lastActiveDate == null) {
      _currentStreak = 1;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
      _lastActiveDate = today;
      _checkStreakAchievements();
      await _saveData();
      notifyListeners();
      return;
    }

    final lastActiveDay = DateTime(
      _lastActiveDate!.year,
      _lastActiveDate!.month,
      _lastActiveDate!.day,
    );
    final difference = today.difference(lastActiveDay).inDays;

    if (difference == 1) {
      // Consecutive day
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
      _lastActiveDate = today;
      _checkStreakAchievements();
      await _saveData();
      notifyListeners();
    } else if (difference > 1 || difference < 0) {
      // Streak broken (or clock adjusted backwards)
      _currentStreak = 1;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
      _lastActiveDate = today;
      _checkStreakAchievements();
      await _saveData();
      notifyListeners();
    } else if (difference == 0) {
      // Already opened today — recover if streak was previously 0 due to load race
      if (_currentStreak < 1) {
        _currentStreak = 1;
        changed = true;
      }
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
        changed = true;
      }
      if (changed) {
        _checkStreakAchievements();
        await _saveData();
        notifyListeners();
      }
    }
  }

  /// Placeholder for claiming a streak milestone reward.
  /// TODO(reward-system): Implement reward granting logic here
  /// (e.g., add coins/gems, grant a Streak Freeze item, or unlock profile cosmetics).
  Future<void> claimMilestoneReward(String milestoneId) async {
    final index = _streakMilestones.indexWhere((m) => m.id == milestoneId);
    if (index == -1) return;
    final milestone = _streakMilestones[index];
    if (_currentStreak < milestone.targetDays || milestone.isRewardClaimed) {
      return;
    }

    // TODO(reward-system): Grant actual reward items to user inventory / profile here.
    milestone.isRewardClaimed = true;
    await _saveData();
    notifyListeners();
  }

  void _unlockAchievement(Achievement achievement) {
    if (!achievement.isUnlocked) {
      achievement.isUnlocked = true;
      achievement.currentProgress = achievement.targetProgress;
      _saveData();
      notifyListeners();
      if (onAchievementUnlocked != null) {
        onAchievementUnlocked!();
      }
    }
  }

  void _checkStreakAchievements() {
    final streakAch = _achievements.firstWhere((a) => a.id == 'streak_7_days');
    if (!streakAch.isUnlocked) {
      streakAch.currentProgress = _currentStreak;
      if (streakAch.currentProgress >= streakAch.targetProgress) {
        _unlockAchievement(streakAch);
      } else {
        _saveData();
        notifyListeners();
      }
    }
  }

  void addTransactionEvent() {
    checkAppOpened();
    final ach = _achievements.firstWhere((a) => a.id == 'first_expense');
    if (!ach.isUnlocked) {
      ach.currentProgress++;
      if (ach.currentProgress >= ach.targetProgress) {
        _unlockAchievement(ach);
      } else {
        _saveData();
        notifyListeners();
      }
    }
  }

  void addReceiptScannedEvent() {
    checkAppOpened();
    final ach = _achievements.firstWhere((a) => a.id == 'receipt_master_10');
    if (!ach.isUnlocked) {
      ach.currentProgress++;
      if (ach.currentProgress >= ach.targetProgress) {
        _unlockAchievement(ach);
      } else {
        _saveData();
        notifyListeners();
      }
    }
  }
}
