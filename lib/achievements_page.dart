import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'settings_provider.dart';
import 'guest_registration_dialog.dart';
import 'auto_translator.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  // Builds the main Achievements screen and listens to GamificationProvider
  // so the list updates automatically whenever achievement progress changes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light background
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.achievementsAndBadges,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // Subscribe to GamificationProvider to get the latest list of achievements.
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          final achievements = provider.achievements;
          
          // Render each achievement as a card in a scrollable list.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return _buildAchievementCard(context, ach);
            },
          );
        },
      ),
    );
  }

  // Builds a single achievement card, mapping its ID to localized strings (or directly
  // using the fields defined on the Achievement in GamificationProvider),
  // calculating completion percentage, and showing either a progress bar (locked)
  // or the reward badge and "Equip Frame" button (unlocked).
  Widget _buildAchievementCard(BuildContext context, Achievement ach) {
    final loc = AppLocalizations.of(context)!;
    String title = ach.title.isNotEmpty ? ach.title : ach.id;
    String description = ach.description;
    String rewardDescription = ach.rewardLabel;

    // Use localized text for built-in achievements; any new Achievement added in
    // GamificationProvider._achievements automatically uses ach.title, ach.description,
    // ach.rewardLabel, and ach.rewardFrameId without needing to edit this file!
    switch (ach.id) {
      case 'first_expense':
        title = loc.achTitleFirstStep;
        description = loc.achDescFirstStep;
        rewardDescription = loc.achRewardBronzeStarter;
        break;
      case 'receipt_master_10':
        title = loc.achTitleReceiptMaster;
        description = loc.achDescReceiptMaster;
        rewardDescription = loc.achRewardSilverScanner;
        break;
      case 'streak_7_days':
        title = loc.achTitleConsistency;
        description = loc.achDescConsistency;
        rewardDescription = loc.achRewardGoldenFlame;
        break;
    }

    // Automatically read the equippable frame ID from the Achievement model.
    final String frameToEquip = ach.rewardFrameId;

    // Calculate progress ratio clamped between 0.0 and 1.0 for the progress bar.
    final double progressPercent = ach.targetProgress > 0 
        ? (ach.currentProgress / ach.targetProgress).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      elevation: ach.isUnlocked ? 4 : 0,
      color: ach.isUnlocked ? Colors.white : Colors.grey.shade200,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: ach.isUnlocked 
            ? const BorderSide(color: Color(0xFF6366F1), width: 2) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon / Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ach.isUnlocked ? const Color(0xFFE0E7FF) : Colors.grey.shade300,
              ),
              child: Icon(
                ach.isUnlocked ? ach.iconData : Icons.lock,
                size: 32,
                color: ach.isUnlocked ? const Color(0xFF6366F1) : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 20),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ach.isUnlocked ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: ach.isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  if (!ach.isUnlocked) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ach.currentProgress} / ${ach.targetProgress}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${(progressPercent * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${loc.reward}: $rewardDescription',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (frameToEquip.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            final isEquipped = settings.profileFrame == frameToEquip;
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEquipped ? Colors.grey.shade300 : const Color(0xFF6366F1),
                                foregroundColor: isEquipped ? Colors.black54 : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: isEquipped
                                  ? null
                                  : () {
                                      if (settings.isGuestUser) {
                                        showGuestRegistrationDialog(context, featureName: 'achievement rewards');
                                        return;
                                      }
                                      settings.updateProfileFrame(frameToEquip);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            tr(
                                              context,
                                              'Avatar Frame Equipped!',
                                              'アバターフレームを装着しました！',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                isEquipped ? loc.equipped : loc.equipFrame,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
