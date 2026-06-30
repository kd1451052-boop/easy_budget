import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'customize_budget_page.dart';
import 'saving_page.dart';
import 'b_and_s_history_page.dart';
import 'shared_bottom_nav.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF5442F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final activeBudgets = provider.budgets.where((b) {
            if (b.isFixed && b.targetDate != null) return !b.targetDate!.isBefore(now);
            return true;
          }).toList();
          final activeSavings = provider.savingsGoals.where((s) {
            if (s.isFixed && s.targetDate != null) return !s.targetDate!.isBefore(now);
            return true;
          }).toList();
          final currency = Provider.of<SettingsProvider>(context).currencySymbol;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUDGET SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Budgets',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomizeBudgetPage()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Budget'),
                      style: TextButton.styleFrom(foregroundColor: headerColor),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (activeBudgets.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active budgets.', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...activeBudgets.map((b) => _buildBudgetCard(context, b, provider, currency)),

                const SizedBox(height: 32),

                // SAVING SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saving Goals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingPage()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Saving'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (activeSavings.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active savings goals.', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...activeSavings.map((s) => _buildSavingCard(context, s, provider, currency)),

                const SizedBox(height: 32),

                // HISTORY BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BAndSHistoryPage()));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Budget and Saving History'),
                  ),
                ),
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2), // Index 2 for Budget
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
        color: Theme.of(context).cardColor,
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
              Text('$currency${spent.toStringAsFixed(0)} spent', style: TextStyle(color: isWarning ? Colors.red : null)),
              Text('$currency${limit.toStringAsFixed(0)} limit', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSavingCard(BuildContext context, SavingsGoal goal, TransactionProvider provider, String currency) {
    final saved = provider.getSavedAmountForGoal(goal);
    final target = goal.amount;
    final percent = (target > 0) ? (saved / target).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              Text('$currency${saved.toStringAsFixed(0)} saved'),
              Text('$currency${target.toStringAsFixed(0)} goal', style: const TextStyle(fontWeight: FontWeight.bold)),
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
