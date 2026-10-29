import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';

// ============================================================================
// FILE: streak_page.dart
// PURPOSE: Dedicated Duolingo-style Daily Streak screen showing current streak,
//          weekly activity calendar (Mon-Sun), Streak Freeze info, and streak
//          milestone goals with placeholders for future rewards.
//
// PROCESS OVERVIEW (For Debugging & Understanding):
// 1. Initialization (`initState`):
//    - Starts a repeating scale animation (`_flameController`) for the hero flame.
//    - Calls `GamificationProvider.checkAppOpened()` after the first frame to
//      ensure today's streak is recorded and synced with `SharedPreferences`.
// 2. Weekly Calendar Calculation (`_getCurrentWeekDays`):
//    - Computes the 7 dates (`Monday` through `Sunday`) of the current week.
//    - Checks `gamification.isDayActive(day)` for each day to render lit flame
//      badges for completed days and highlight today's date.
// 3. Milestone Goals & Future Rewards (`_buildMilestoneCard`):
//    - Iterates through `gamification.streakMilestones` (3, 7, 14, 30, 60, 100 days).
//    - Computes completion progress (`currentStreak / targetDays`) and provides
//      `TODO(reward-system)` hooks for claiming rewards in the future.
// ============================================================================

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flameController;
  late final Animation<double> _flameScale;

  // Initializes the pulsing flame animation and triggers a streak check
  // after the first frame so today's activity is recorded.
  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    // Sync streak state with GamificationProvider once the widget is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<GamificationProvider>(
        context,
        listen: false,
      ).checkAppOpened();
    });
  }

  // Disposes the flame animation controller to prevent memory leaks.
  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  // Computes the 7 dates (Monday through Sunday) of the current week
  // for displaying the weekly streak tracker bar.
  List<DateTime> _getCurrentWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // Builds the main Streak screen by listening to GamificationProvider for
  // current streak, longest streak, active dates, and milestone goals.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Daily Streak',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gamification, child) {
          final streak = gamification.currentStreak;
          final longestStreak = gamification.longestStreak;
          final totalActiveDays = gamification.activeDates.length;
          final weekDays = _getCurrentWeekDays();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final activeThisWeek = weekDays
              .where((d) => gamification.isDayActive(d))
              .length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroFlameHeader(
                  streak: streak,
                  longestStreak: longestStreak,
                  totalActiveDays: totalActiveDays,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeeklyStreakCard(
                        context: context,
                        weekDays: weekDays,
                        today: today,
                        gamification: gamification,
                        activeThisWeek: activeThisWeek,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildStreakFreezeBanner(context, isDark),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Streak Goals & Rewards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Rewards Soon',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...gamification.streakMilestones.map(
                        (milestone) => _buildMilestoneCard(
                          context: context,
                          milestone: milestone,
                          currentStreak: streak,
                          gamification: gamification,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Builds the top orange gradient header displaying the animated flame icon,
  // current day-streak counter, motivational text, and 3 summary stat pills.
  Widget _buildHeroFlameHeader({
    required int streak,
    required int longestStreak,
    required int totalActiveDays,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _flameScale,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streak == 1 ? 'DAY STREAK!' : 'DAYS STREAK!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            streak > 0
                ? 'You are on fire! Keep tracking your expenses every day.'
                : 'Open the app or log a transaction today to start your streak!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Current',
                  value: '$streak d',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatPill(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best Streak',
                  value: '$longestStreak d',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatPill(
                  icon: Icons.calendar_month_rounded,
                  label: 'Total Days',
                  value: '$totalActiveDays d',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a compact glassmorphic pill showing a streak statistic (Current, Best, Total).
  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the weekly calendar card (Monday to Sunday), lighting up active days
  // with an orange flame circle and showing a weekly completion progress bar.
  Widget _buildWeeklyStreakCard({
    required BuildContext context,
    required List<DateTime> weekDays,
    required DateTime today,
    required GamificationProvider gamification,
    required int activeThisWeek,
    required bool isDark,
  }) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$activeThisWeek / 7 days',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = weekDays[index];
              final isActive = gamification.isDayActive(day);
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isFuture = day.isAfter(today);

              return Column(
                children: [
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? const Color(0xFFFF6B00)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B00), Color(0xFFFFA000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActive
                          ? null
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                      border: isToday && !isActive
                          ? Border.all(
                              color: const Color(0xFFFF6B00),
                              width: 2,
                            )
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 22,
                            )
                          : Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isFuture
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.35)
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.65),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (activeThisWeek / 7.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6B00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder card for Duolingo-style "Streak Freeze" protection item.
  /// TODO(reward-system): Allow users to earn or equip Streak Freezes from milestone
  /// rewards so missing 1 day does not reset `_currentStreak`.
  Widget _buildStreakFreezeBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ac_unit_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Freeze',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Protect your streak if you miss a day. Earned via streak goal rewards (coming soon).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard({
    required BuildContext context,
    required StreakMilestone milestone,
    required int currentStreak,
    required GamificationProvider gamification,
    required bool isDark,
  }) {
    final isReached = currentStreak >= milestone.targetDays;
    final progress = (currentStreak / milestone.targetDays).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReached
              ? milestone.accentColor.withValues(alpha: 0.6)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isReached ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isReached
                      ? milestone.accentColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                ),
                child: Icon(
                  milestone.icon,
                  color: isReached ? milestone.accentColor : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isReached
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isReached
                                ? 'Goal Reached!'
                                : '${currentStreak.clamp(0, milestone.targetDays)} / ${milestone.targetDays} d',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isReached
                                  ? const Color(0xFF10B981)
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(milestone.accentColor),
            ),
          ),
          const SizedBox(height: 12),
          // Reward row (future implementation placeholder)
          // TODO(reward-system): Replace this preview bar with an interactive "Claim Reward"
          // button that calls `gamification.claimMilestoneReward(milestone.id)` and grants
          // the user their reward (e.g., profile frame, app theme, or Streak Freeze).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 16,
                    color: milestone.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reward: ${milestone.rewardLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              if (isReached)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // TODO(reward-system): Trigger reward unlock modal / animation and
                    // call `gamification.claimMilestoneReward(milestone.id)` once the
                    // reward inventory system is implemented.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Reward system coming soon! Your streak goal progress is saved.',
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.lock_clock_outlined,
                    size: 14,
                    color: milestone.accentColor,
                  ),
                  label: Text(
                    'Claim Soon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: milestone.accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

