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
import 'category_localization.dart';
import 'auto_translator.dart';

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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr(
            context,
            'Delete $title?',
            '$titleを削除しますか？',
            '$title ကို ဖျက်မည်လား?',
          ),
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
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.white),
            ),
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
            if (b.isFixed && b.targetDate != null) {
              return !b.targetDate!.isBefore(now);
            }
            return true;
          }).toList();
          // Keep only non-completed savings goals that have not yet met their target amount.
          final activeSavings = provider.savingsGoals.where((s) {
            if (s.isCompleted) return false;
            if (s.amount > 0 && provider.getSavedAmountForGoal(s) >= s.amount) {
              return false;
            }
            if (s.isFixed && s.targetDate != null) {
              return !s.targetDate!.isBefore(now) || s.isAiProductGoal;
            }
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
              Expanded(
                child: AutoLocalizedText(
                  budget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
              ),
            ],
          ),
          Text(
            getLocalizedCategory(context, budget.category),
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

  // Builds an active savings goal card, showing the product picture on the left,
  // dynamic days left (which increases if the main balance drops or goes negative),
  // how much is saved so far, and an emerald progress bar.
  Widget _buildSavingCard(
    BuildContext context,
    SavingsGoal goal,
    TransactionProvider provider,
    String currency,
  ) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final rawSaved = provider.getSavedAmountForGoal(goal);
    final saved = rawSaved.isFinite ? rawSaved : 0.0;
    final target =
        (goal.amount.isFinite && goal.amount > 0) ? goal.amount : 0.0;
    final rawPercent = (target > 0) ? (saved / target) : 0.0;
    final percent = rawPercent.isFinite ? rawPercent.clamp(0.0, 1.0) : 0.0;
    final daysLeft = provider.getDynamicDaysLeftForGoal(goal);
    final extraDays = provider.getExtraDaysAddedFromBalance(goal);
    final isNegativeSaved = saved < 0;
    final savedSign = isNegativeSaved ? '-' : '';
    final formattedSaved =
        '$savedSign$currency${settings.formatAmount(saved.abs())}';

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Picture on the Left
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildGoalThumbnail(
              goal.productImageUrl,
              size: 68,
              fallback: _buildFallbackGoalImage(),
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
                            goal.productSite != null &&
                                    goal.productSite!.isNotEmpty
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
                // Days Left Badge + Extra Days Warning when main balance is negative
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        daysLeft == 0
                            ? AppLocalizations.of(context)!.goalReached
                            : AppLocalizations.of(
                                context,
                              )!.daysLeftCount(daysLeft),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    if (extraDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.extraDaysNegativeBalance(extraDays),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.savedSoFar(formattedSaved),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isNegativeSaved ? Colors.redAccent : null,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.goalText(currency, settings.formatAmount(target)),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF10B981),
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

  // Safely renders a saving goal thumbnail using SafeProductImage.
  Widget _buildGoalThumbnail(
    String? url, {
    required double size,
    required Widget fallback,
  }) {
    return SafeProductImage(
      imageUrl: url,
      width: size,
      height: size,
      cacheWidth: 140,
      fallback: fallback,
    );
  }

  // Builds a fallback icon thumbnail when a saving goal does not have a network product image.
  Widget _buildFallbackGoalImage() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.savings_rounded,
        color: Color(0xFF10B981),
        size: 32,
      ),
    );
  }
}
