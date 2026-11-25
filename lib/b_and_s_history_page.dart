import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'category_localization.dart';
import 'auto_translator.dart';

// Shows a confirmation dialog before permanently deleting an expired budget or saving goal.
void _showDeleteConfirmation(BuildContext context, String title, VoidCallback onConfirm) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        tr(context, 'Delete $title?', '$titleを削除しますか？', '$title ကို ဖျက်မည်လား?'),
      ),
      content: Text(
        tr(
          context,
          'Are you sure you want to delete this $title? This action cannot be undone.',
          'この$titleを削除してもよろしいですか？この操作は元に戻せません。',
          'ဤ $title ကို ဖျက်ရန် သေချာပါသလား? ဤလုပ်ဆောင်ချက်ကို ပြန်လည်ပြင်ဆင်၍ မရပါ။',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

class BAndSHistoryPage extends StatelessWidget {
  const BAndSHistoryPage({super.key});

  // Builds the history screen by filtering TransactionProvider for fixed-date
  // budgets and savings goals whose targetDate has already passed.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.history, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          
          // Filter budgets to only include fixed-date budgets with a targetDate before now.
          final expiredBudgets = provider.budgets.where((b) {
            if (b.isFixed && b.targetDate != null) {
              return b.targetDate!.isBefore(now);
            }
            return false;
          }).toList();
          
          // Filter savings goals to include reached/completed goals as well as fixed-date goals whose targetDate has passed.
          final expiredSavings = provider.savingsGoals.where((s) {
            if (s.isCompleted) return true;
            if (s.amount > 0 && provider.getSavedAmountForGoal(s) >= s.amount) {
              return true;
            }
            if (s.isFixed && s.targetDate != null) {
              return s.targetDate!.isBefore(now);
            }
            return false;
          }).toList();
          
          final currency = Provider.of<SettingsProvider>(context).currencySymbol;

          // Render expired budgets section followed by expired savings goals section.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.pastBudgets,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (expiredBudgets.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(AppLocalizations.of(context)!.noPastBudgets, style: const TextStyle(color: Colors.grey)),
                  ))
                else
                  ...expiredBudgets.map((b) => _buildBudgetCard(context, b, provider, currency)),

                const SizedBox(height: 32),

                Text(
                  AppLocalizations.of(context)!.pastSavingGoals,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (expiredSavings.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(AppLocalizations.of(context)!.noPastSavingsGoals, style: const TextStyle(color: Colors.grey)),
                  ))
                else
                  ...expiredSavings.map((s) => _buildSavingCard(context, s, provider, currency)),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  // Builds a dimmed card for an expired budget, calculating how much was spent
  // compared to its limit and allowing the user to delete it from history.
  Widget _buildBudgetCard(BuildContext context, Budget budget, TransactionProvider provider, String currency) {
    final spent = provider.getSpentAmountForBudget(budget);
    final limit = budget.amount;
    final percent = (limit > 0) ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isWarning = percent >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1), // Dimmed for history
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoLocalizedText(
                  budget.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(
                  context,
                  AppLocalizations.of(context)!.budgetPageTitle,
                  () {
                    provider.deleteBudget(budget);
                  },
                ),
              )
            ],
          ),
          Text(getLocalizedCategory(context, budget.category), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(AppLocalizations.of(context)!.spentText(currency, NumberFormat("#,##0", "en_US").format(spent)), style: TextStyle(color: isWarning ? Colors.red : null)),
                Text(AppLocalizations.of(context)!.limitText(currency, NumberFormat("#,##0", "en_US").format(limit)), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade300,
            color: isWarning ? Colors.red.withValues(alpha: 0.5) : const Color(0xFF5442F5).withValues(alpha: 0.5),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // Builds a card for a reached/completed or expired savings goal in B&S History,
  // showing the product thumbnail, "Goal Reached!" badge, saved vs target amount, and delete button.
  Widget _buildSavingCard(BuildContext context, SavingsGoal goal, TransactionProvider provider, String currency) {
    final rawSaved = provider.getSavedAmountForGoal(goal);
    final saved = rawSaved.isFinite ? rawSaved : 0.0;
    final target = (goal.amount.isFinite && goal.amount > 0) ? goal.amount : 0.0;
    final isReached = goal.isCompleted || (target > 0 && saved >= target);
    final displaySaved = isReached && saved < target ? target : saved;
    final rawPercent = (target > 0) ? (displaySaved / target) : 0.0;
    final percent = rawPercent.isFinite ? rawPercent.clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReached
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReached
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SafeProductImage(
              imageUrl: goal.productImageUrl,
              width: 60,
              height: 60,
              cacheWidth: 140,
              fallback: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoLocalizedText(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.productSite != null && goal.productSite!.isNotEmpty
                                ? '${AutoTranslator.localizeSync(context, goal.productSite!)} • ${getLocalizedCategory(context, goal.category)}'
                                : getLocalizedCategory(context, goal.category),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        AppLocalizations.of(context)!.savingGoals,
                        () {
                          provider.deleteSavingsGoal(goal);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isReached
                        ? const Color(0xFF10B981).withValues(alpha: 0.16)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isReached
                        ? '${AppLocalizations.of(context)!.goalReached} 🎉'
                        : AppLocalizations.of(context)!.expired,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isReached
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.savedText(
                          currency,
                          NumberFormat("#,##0", "en_US").format(displaySaved),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isReached ? const Color(0xFF10B981) : null,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.goalText(
                          currency,
                          NumberFormat("#,##0", "en_US").format(target),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey.shade300,
                  color: isReached
                      ? const Color(0xFF10B981)
                      : const Color(0xFF10B981).withValues(alpha: 0.5),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
