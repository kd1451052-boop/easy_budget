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

class GamificationProvider with ChangeNotifier {
  int _currentStreak = 0;
  DateTime? _lastActiveDate;

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

  int get currentStreak => _currentStreak;
  List<Achievement> get achievements => _achievements;

  // Function to call when we want to trigger confetti
  Function()? onAchievementUnlocked;

  GamificationProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load streak data
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    final lastActiveString = prefs.getString('lastActiveDate');
    if (lastActiveString != null) {
      _lastActiveDate = DateTime.parse(lastActiveString);
    }
    
    // Load achievements data
    for (var achievement in _achievements) {
      achievement.currentProgress = prefs.getInt('ach_prog_${achievement.id}') ?? 0;
      achievement.isUnlocked = prefs.getBool('ach_unlocked_${achievement.id}') ?? false;
    }
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('currentStreak', _currentStreak);
    if (_lastActiveDate != null) {
      await prefs.setString('lastActiveDate', _lastActiveDate!.toIso8601String());
    }
    
    for (var achievement in _achievements) {
      await prefs.setInt('ach_prog_${achievement.id}', achievement.currentProgress);
      await prefs.setBool('ach_unlocked_${achievement.id}', achievement.isUnlocked);
    }
  }

  Future<void> checkAppOpened() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastActiveDate == null) {
      _currentStreak = 1;
      _lastActiveDate = today;
      await _saveData();
      notifyListeners();
      return;
    }

    final lastActiveDay = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
    final difference = today.difference(lastActiveDay).inDays;

    if (difference == 1) {
      // Consecutive day
      _currentStreak++;
      _lastActiveDate = today;
      _checkStreakAchievements();
      await _saveData();
      notifyListeners();
    } else if (difference > 1) {
      // Streak broken
      _currentStreak = 1;
      _lastActiveDate = today;
      await _saveData();
      notifyListeners();
    }
    // If difference == 0, already opened today, do nothing.
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
