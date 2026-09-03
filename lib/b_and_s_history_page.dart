import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'shared_bottom_nav.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

class BAndSHistoryPage extends StatelessWidget {
  const BAndSHistoryPage({super.key});

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
          
          final expiredBudgets = provider.budgets.where((b) {
            if (b.isFixed && b.targetDate != null) {
              return b.targetDate!.isBefore(now);
            }
            return false;
          }).toList();
          
          final expiredSavings = provider.savingsGoals.where((s) {
            if (s.isFixed && s.targetDate != null) {
              return s.targetDate!.isBefore(now);
            }
            return false;
          }).toList();
          
          final currency = Provider.of<SettingsProvider>(context).currencySymbol;

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
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2), // Index 2 for Budget/History context
    );
  }

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
              Text(budget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => provider.deleteBudget(budget),
              )
            ],
          ),
          Text(budget.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.spentText(currency, spent.toStringAsFixed(0)), style: TextStyle(color: isWarning ? Colors.red : null)),
              Text(AppLocalizations.of(context)!.limitText(currency, limit.toStringAsFixed(0)), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
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

  Widget _buildSavingCard(BuildContext context, SavingsGoal goal, TransactionProvider provider, String currency) {
    final saved = provider.getSavedAmountForGoal(goal);
    final target = goal.amount;
    final percent = (target > 0) ? (saved / target).clamp(0.0, 1.0) : 0.0;
    
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
              Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => provider.deleteSavingsGoal(goal),
              )
            ],
          ),
          Text(goal.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.savedText(currency, saved.toStringAsFixed(0))),
              Text(AppLocalizations.of(context)!.goalText(currency, target.toStringAsFixed(0)), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
