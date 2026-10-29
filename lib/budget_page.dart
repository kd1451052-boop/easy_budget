import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'customize_budget_page.dart';
import 'saving_page.dart';
import 'b_and_s_history_page.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // Displays a confirmation dialog before deleting a budget or saving goal.
  void _showDeleteConfirmation(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $title?'),
        content: Text(
          'Are you sure you want to delete this $title? This action cannot be undone.',
        ),
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

  // Builds the Budget & Saving screen, filtering out expired items and rendering
  // active budgets, active savings goals, and the navigation button to history.
  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF5442F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.budgetPageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          // Keep only recurring budgets or fixed-date budgets whose targetDate has not passed.
          final activeBudgets = provider.budgets.where((b) {
            if (b.isFixed && b.targetDate != null)
              return !b.targetDate!.isBefore(now);
            return true;
          }).toList();
          // Keep only recurring savings goals or fixed-date goals whose targetDate has not passed.
          final activeSavings = provider.savingsGoals.where((s) {
            if (s.isFixed && s.targetDate != null)
              return !s.targetDate!.isBefore(now);
            return true;
          }).toList();
          final currency = Provider.of<SettingsProvider>(
            context,
          ).currencySymbol;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUDGET SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.activeBudgets,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomizeBudgetPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addBudget),
                      style: TextButton.styleFrom(foregroundColor: headerColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeBudgets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(context)!.noActiveBudgets,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...activeBudgets.map(
                    (b) => _buildBudgetCard(context, b, provider, currency),
                  ),

                const SizedBox(height: 32),

                // SAVING SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.savingGoals,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SavingPage()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.newSaving),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeSavings.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(context)!.noActiveSavings,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...activeSavings.map(
                    (s) => _buildSavingCard(context, s, provider, currency),
                  ),

                const SizedBox(height: 32),

                // HISTORY BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BAndSHistoryPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.budgetAndSavingHistory,
                    ),
                  ),
                ),
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  // Builds an active budget card, calculating the spent amount from TransactionProvider,
  // coloring the progress bar red if spending reaches >= 90%, and providing a delete button.
  Widget _buildBudgetCard(
    BuildContext context,
    Budget budget,
    TransactionProvider provider,
    String currency,
  ) {
    final spent = provider.getSpentAmountForBudget(budget);
    final limit = budget.amount;
    final percent = (limit > 0) ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isWarning = percent >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, 'Budget', () {
                  provider.deleteBudget(budget);
                }),
              ),
            ],
          ),
          Text(
            budget.category,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.spentText(
                  currency,
                  NumberFormat("#,##0", "en_US").format(spent),
                ),
                style: TextStyle(color: isWarning ? Colors.red : null),
              ),
              Text(
                AppLocalizations.of(context)!.limitText(
                  currency,
                  NumberFormat("#,##0", "en_US").format(limit),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: isWarning ? Colors.red : const Color(0xFF5442F5),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // Builds an active savings goal card, calculating the saved amount toward the target
  // from TransactionProvider and rendering an emerald progress bar.
  Widget _buildSavingCard(
    BuildContext context,
    SavingsGoal goal,
    TransactionProvider provider,
    String currency,
  ) {
    final saved = provider.getSavedAmountForGoal(goal);
    final target = goal.amount;
    final percent = (target > 0) ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    _showDeleteConfirmation(context, 'Saving Goal', () {
                      provider.deleteSavingsGoal(goal);
                    }),
              ),
            ],
          ),
          Text(
            goal.category,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.savedText(
                  currency,
                  NumberFormat("#,##0", "en_US").format(saved),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.goalText(
                  currency,
                  NumberFormat("#,##0", "en_US").format(target),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF10B981),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
