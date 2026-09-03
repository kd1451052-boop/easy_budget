import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'shared_bottom_nav.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'scanner.dart';

void _showDeleteConfirmation(BuildContext context, String title, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $title?'),
      content: Text('Are you sure you want to delete this $title? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const Scanner())),
        backgroundColor: const Color(0xFF5442F5),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const SharedBottomNav(currentIndex: 3), // Index 3 for Budget/History context
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
                onPressed: () => _showDeleteConfirmation(context, 'Budget', () {
                  provider.deleteBudget(budget);
                }),
              )
            ],
          ),
          Text(budget.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.spentText(currency, NumberFormat("#,##0", "en_US").format(spent)), style: TextStyle(color: isWarning ? Colors.red : null)),
              Text(AppLocalizations.of(context)!.limitText(currency, NumberFormat("#,##0", "en_US").format(limit)), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () => _showDeleteConfirmation(context, 'Saving Goal', () {
                  provider.deleteSavingsGoal(goal);
                }),
              )
            ],
          ),
          Text(goal.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.savedText(currency, NumberFormat("#,##0", "en_US").format(saved))),
              Text(AppLocalizations.of(context)!.goalText(currency, NumberFormat("#,##0", "en_US").format(target)), style: const TextStyle(fontWeight: FontWeight.bold)),
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
