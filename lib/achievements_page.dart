import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'settings_provider.dart';
import 'guest_registration_dialog.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light background
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          final achievements = provider.achievements;
          
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

  Widget _buildAchievementCard(BuildContext context, Achievement ach) {
    final loc = AppLocalizations.of(context)!;
    String title = '';
    String description = '';
    String rewardDescription = '';

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
      default:
        title = ach.id;
        description = '';
        rewardDescription = '';
    }

    String frameToEquip = '';
    if (ach.id == 'first_expense') frameToEquip = 'bronze';
    if (ach.id == 'receipt_master_10') frameToEquip = 'silver';
    if (ach.id == 'streak_7_days') frameToEquip = 'gold';

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
                                        const SnackBar(content: Text('Avatar Frame Equipped!')),
                                      );
                                    },
                              child: Text(isEquipped ? 'Equipped' : 'Equip Frame', style: const TextStyle(fontSize: 12)),
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
