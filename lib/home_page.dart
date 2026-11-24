//Copyright 2026 THANT ZIN

// Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at

//http://www.apache.org/licenses/LICENSE-2.0

//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'transaction_provider.dart';
import 'history.dart'; // Assuming your model is here
import 'settings_provider.dart';
import 'gamification_provider.dart';
import 'streak_page.dart';
import 'category_localization.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'auto_translator.dart';

enum FilterPeriod { year, month, week }

// Holds aggregated income, expense, and computed netBalance for a single chart time bucket.
class TimeBucketData {
  double income = 0;
  double expense = 0;
  double get netBalance => income - expense;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color _primaryIndigo = const Color(
    0xFF5442F5,
  ); // Matches the Figma prototype
  FilterPeriod _selectedPeriod = FilterPeriod.year;

  // Checks and updates the user's daily streak in GamificationProvider once HomePage mounts.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<GamificationProvider>(
        context,
        listen: false,
      ).checkAppOpened();
    });
  }

  // Returns the localized display label for the currently selected FilterPeriod (Year, Month, or Week).
  String _getPeriodLabel() {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedPeriod) {
      case FilterPeriod.year:
        return '${now.year}';
      case FilterPeriod.month:
        final months = [
          l10n.monthJan,
          l10n.monthFeb,
          l10n.monthMar,
          l10n.monthApr,
          l10n.monthMay,
          l10n.monthJun,
          l10n.monthJul,
          l10n.monthAug,
          l10n.monthSep,
          l10n.monthOct,
          l10n.monthNov,
          l10n.monthDec,
        ];
        return months[now.month - 1];
      case FilterPeriod.week:
        return l10n.thisWeek;
    }
  }

  // Maps a bucket index to its X-axis label on the Income vs Expense chart ('Mon'-'Sun', 'W1'-'W5', or 'Jan'-'Dec').
  String _getBucketLabel(int index, AppLocalizations l10n) {
    final code = Localizations.localeOf(context).languageCode;
    if (_selectedPeriod == FilterPeriod.week) {
      const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const daysJa = ['月', '火', '水', '木', '金', '土', '日'];
      const daysMy = ['တနင်္လာ', 'အင်္ဂါ', 'ဗုဒ္ဓဟူး', 'ကြာသပတေး', 'သောကြာ', 'စနေ', 'တနင်္ဂနွေ'];
      if (code == 'ja') return daysJa[index % 7];
      if (code == 'my') return daysMy[index % 7];
      return daysEn[index % 7];
    } else if (_selectedPeriod == FilterPeriod.month) {
      if (code == 'ja') return '第${index + 1}週';
      if (code == 'my') return 'အပတ် ${index + 1}';
      return 'W${index + 1}';
    } else {
      final months = [
        l10n.monthJan,
        l10n.monthFeb,
        l10n.monthMar,
        l10n.monthApr,
        l10n.monthMay,
        l10n.monthJun,
        l10n.monthJul,
        l10n.monthAug,
        l10n.monthSep,
        l10n.monthOct,
        l10n.monthNov,
        l10n.monthDec,
      ];
      return months[index % 12];
    }
  }

  // Groups filtered transactions into time buckets (7 days, 5 weeks, or 12 months)
  // and sums each bucket's income and expense for the combo BarChart + LineChart.
  Map<int, TimeBucketData> _getComboChartBuckets(
    List<AppTransaction> filteredTransactions,
  ) {
    Map<int, TimeBucketData> buckets = {};
    int nBuckets = _selectedPeriod == FilterPeriod.week
        ? 7
        : (_selectedPeriod == FilterPeriod.month ? 5 : 12);

    for (int i = 0; i < nBuckets; i++) {
      buckets[i] = TimeBucketData();
    }

    for (var t in filteredTransactions) {
      int bucketKey;
      if (_selectedPeriod == FilterPeriod.week) {
        bucketKey = t.dateTime.weekday - 1; // 0 to 6
      } else if (_selectedPeriod == FilterPeriod.month) {
        bucketKey = (t.dateTime.day - 1) ~/ 7; // 0 to 4
        if (bucketKey > 4) bucketKey = 4; // cap at 4 (Week 5)
      } else {
        bucketKey = t.dateTime.month - 1; // 0 to 11
      }

      if (t.type == TransactionType.income) {
        buckets[bucketKey]!.income += t.amount;
      } else {
        buckets[bucketKey]!.expense += t.amount;
      }
    }

    return buckets;
  }

  // Filters all transactions to only those occurring within the active _selectedPeriod (current year, month, or week).
  List<AppTransaction> _getFilteredTransactions(List<AppTransaction> all) {
    final now = DateTime.now();
    return all.where((t) {
      if (_selectedPeriod == FilterPeriod.year) {
        return t.dateTime.year == now.year;
      } else if (_selectedPeriod == FilterPeriod.month) {
        return t.dateTime.year == now.year && t.dateTime.month == now.month;
      } else {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startOfWeek = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
        return t.dateTime.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            t.dateTime.isBefore(endOfWeek);
      }
    }).toList();
  }

  // Aggregates expense transactions by category into _ExpenseSliceData items with distinct colors and icons.
  List<_ExpenseSliceData> _getExpenseSlices(List<AppTransaction> transactions) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final Map<String, double> categoryAmounts = {};
    final Map<String, IconData> categoryIcons = {};

    for (final t in expenses) {
      if (!t.amount.isFinite || t.amount <= 0) continue;
      categoryAmounts[t.category] =
          (categoryAmounts[t.category] ?? 0.0) + t.amount;
      categoryIcons[t.category] = t.icon;
    }

    final total = categoryAmounts.values.fold<double>(0.0, (s, v) => s + v);
    if (total <= 0) return const [];

    // Distinct, high-contrast palette inspired by the reference callout pie chart
    const List<Color> palette = [
      Color(0xFF4272A7), // Steel Blue
      Color(0xFFAA4643), // Crimson Terracotta
      Color(0xFF89A54E), // Olive Green
      Color(0xFF71588F), // Muted Purple
      Color(0xFF4198AF), // Teal Cyan
      Color(0xFFDB843D), // Warm Orange
      Color(0xFF5442F5), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFF93A9CF), // Periwinkle
      Color(0xFFD19392), // Rose
      Color(0xFFB9CD96), // Sage
      Color(0xFFA99BBD), // Lavender
    ];

    int index = 0;
    return categoryAmounts.entries
        .where((entry) => entry.value.isFinite && entry.value > 0)
        .map((entry) {
          final safeValue = entry.value.clamp(0.0, 1e12);
          final pct = (safeValue / total) * 100.0;
          final color = palette[index % palette.length];
          final icon = categoryIcons[entry.key] ?? Icons.category;
          index++;
          return _ExpenseSliceData(
            category: entry.key,
            value: safeValue,
            percentage: pct,
            icon: icon,
            color: color,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Provider.of<SettingsProvider>(
      context,
    ).currencySymbol;
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Softer background
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final filteredTransactions = _getFilteredTransactions(
            provider.transactions,
          );
          double filteredIncome = 0;
          double filteredExpense = 0;
          for (var t in filteredTransactions) {
            if (t.type == TransactionType.income) filteredIncome += t.amount;
            if (t.type == TransactionType.expense) filteredExpense += t.amount;
          }
          double filteredBalance = filteredIncome - filteredExpense;

          final buckets = _getComboChartBuckets(filteredTransactions);
          const double maxChartValue = 1e12;
          double comboMaxY = 0;
          double comboMinY = 0;
          for (var bucket in buckets.values) {
            final inc = bucket.income.isFinite
                ? bucket.income.clamp(0.0, maxChartValue)
                : 0.0;
            final exp = bucket.expense.isFinite
                ? bucket.expense.clamp(0.0, maxChartValue)
                : 0.0;
            final net = (inc - exp).clamp(-maxChartValue, maxChartValue);
            if (inc > comboMaxY) comboMaxY = inc;
            if (exp > comboMaxY) comboMaxY = exp;
            if (net > comboMaxY) comboMaxY = net;
            if (net < comboMinY) comboMinY = net;
          }
          comboMaxY = (comboMaxY * 1.2).clamp(0.0, maxChartValue * 1.2);
          if (comboMinY < 0) {
            comboMinY = (comboMinY * 1.2).clamp(-maxChartValue * 1.2, 0.0);
          }
          if (!comboMaxY.isFinite || comboMaxY <= 0) comboMaxY = 100;
          if (!comboMinY.isFinite || comboMinY > 0) comboMinY = 0;
          if (comboMaxY <= comboMinY) comboMaxY = comboMinY + 100;
          final safeHorizontalInterval = ((comboMaxY - comboMinY) / 4).clamp(
            1.0,
            maxChartValue,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(
                filteredBalance,
                filteredIncome,
                filteredExpense,
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Saving Goals Section (placed between Income & Expense and Expense Analytics)
                      _buildActiveSavingGoalsSection(provider, currencySymbol),

                      // Analytics Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          AppLocalizations.of(context)!.expenseAnalytics,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 280,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: filteredExpense > 0
                              ? _CalloutPieChart(
                                  slices: _getExpenseSlices(
                                    filteredTransactions,
                                  ),
                                  currencySymbol: currencySymbol,
                                )
                              : Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.noExpensesYet,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Warnings Section
                      _buildWarnings(provider, currencySymbol),

                      // Income & Expense Comparison Section (Bar Chart)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          AppLocalizations.of(context)!.incomeVsExpense,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 220,
                          margin: const EdgeInsets.only(
                            bottom: 100,
                          ), // To make room for FAB
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: comboMaxY,
                                  minY: comboMinY,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              _getBucketLabel(
                                                value.toInt(),
                                                AppLocalizations.of(context)!,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: safeHorizontalInterval,
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: buckets.entries.map((e) {
                                    final inc = e.value.income.isFinite
                                        ? e.value.income.clamp(
                                            0.0,
                                            maxChartValue,
                                          )
                                        : 0.0;
                                    final exp = e.value.expense.isFinite
                                        ? e.value.expense.clamp(
                                            0.0,
                                            maxChartValue,
                                          )
                                        : 0.0;
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: inc,
                                          color: const Color(0xFF10B981),
                                          width: 8,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                        ),
                                        BarChartRodData(
                                          toY: exp,
                                          color: const Color(0xFFEF4444),
                                          width: 8,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              LineChart(
                                LineChartData(
                                  minX: -0.5,
                                  maxX: buckets.length - 0.5,
                                  minY: comboMinY,
                                  maxY: comboMaxY,
                                  titlesData: const FlTitlesData(show: false),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineTouchData: LineTouchData(enabled: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: buckets.entries.map((e) {
                                        final inc = e.value.income.isFinite
                                            ? e.value.income.clamp(
                                                0.0,
                                                maxChartValue,
                                              )
                                            : 0.0;
                                        final exp = e.value.expense.isFinite
                                            ? e.value.expense.clamp(
                                                0.0,
                                                maxChartValue,
                                              )
                                            : 0.0;
                                        return FlSpot(
                                          e.key.toDouble(),
                                          (inc - exp).clamp(
                                            -maxChartValue,
                                            maxChartValue,
                                          ),
                                        );
                                      }).toList(),
                                      color: const Color(
                                        0xFF3B82F6,
                                      ), // Blue line for net balance
                                      isCurved: true,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI WIDGET EXTRACTS ---

  // Builds the top indigo header card containing the tappable Streak pill,
  // period filter dropdown, net balance display, and Income/Expense summary cards.
  Widget _buildHeroHeader(double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: _primaryIndigo,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Streak Banner (tappable -> opens Duolingo-style StreakPage)
          Consumer<GamificationProvider>(
            builder: (context, gamification, child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StreakPage()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.dayStreakBanner(gamification.currentStreak),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<FilterPeriod>(
            initialValue: _selectedPeriod,
            onSelected: (FilterPeriod result) {
              setState(() {
                _selectedPeriod = result;
              });
            },
            offset: const Offset(0, 30),
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<FilterPeriod>>[
                  PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.year,
                    child: Text(AppLocalizations.of(context)!.yearly),
                  ),
                  PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.month,
                    child: Text(AppLocalizations.of(context)!.monthly),
                  ),
                  PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.week,
                    child: Text(AppLocalizations.of(context)!.weekly),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodLabel(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final settings = Provider.of<SettingsProvider>(context);
              final sign = balance < 0 ? '-' : '';
              return Text(
                '$sign${settings.currencySymbol}${settings.formatAmount(balance.abs())}',
                style: TextStyle(
                  color: balance >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Glassmorphism Cards
          Row(
            children: [
              Expanded(
                child: _buildGlassCard(
                  AppLocalizations.of(context)!.income,
                  income,
                  Icons.arrow_upward,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassCard(
                  AppLocalizations.of(context)!.expense,
                  expense,
                  Icons.arrow_downward,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a semi-transparent summary card inside the hero header for displaying total Income or Expense.
  Widget _buildGlassCard(
    String label,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final settings = Provider.of<SettingsProvider>(context);
              return Text(
                '${settings.currencySymbol}${settings.formatAmount(amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Evaluates active budgets (>= 90% spent) and savings goals (behind schedule)
  // to generate warning alert tiles on the dashboard.
  Widget _buildWarnings(TransactionProvider provider, String currency) {
    final now = DateTime.now();
    List<Widget> warnings = [];

    // Check Budgets
    for (var budget in provider.budgets) {
      if (budget.isFixed &&
          budget.targetDate != null &&
          budget.targetDate!.isBefore(now)) {
        continue; // Expired
      }

      final spent = provider.getSpentAmountForBudget(budget);
      if (budget.amount > 0 && spent >= budget.amount * 0.9) {
        warnings.add(
          _buildWarningTile(
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            title: AppLocalizations.of(context)!.budgetAlert(budget.name),
            subtitle: AppLocalizations.of(context)!.budgetSpentWarning(
              currency,
              NumberFormat("#,##0", "en_US").format(spent),
              NumberFormat("#,##0", "en_US").format(budget.amount),
            ),
          ),
        );
      }
    }

    // Check Savings
    for (var goal in provider.savingsGoals) {
      if (goal.isCompleted) continue;
      if (goal.isFixed &&
          goal.targetDate != null &&
          goal.targetDate!.isBefore(now)) {
        continue; // Expired
      }

      final saved = provider.getSavedAmountForGoal(goal);
      if (goal.amount > 0 && saved >= goal.amount) {
        continue; // Already reached
      }
      if (goal.amount > 0) {
        bool showWarning = false;

        if (goal.isFixed && goal.targetDate != null) {
          final totalDuration = goal.targetDate!
              .difference(goal.createdAt)
              .inDays;
          final elapsedDuration = now.difference(goal.createdAt).inDays;
          if (totalDuration > 0 &&
              (elapsedDuration / totalDuration) >= 0.5 &&
              (saved / goal.amount) < 0.5) {
            showWarning = true;
          }
        } else if (!goal.isFixed && goal.period != null) {
          if (goal.period == BudgetPeriod.monthly &&
              now.day >= 24 &&
              saved < goal.amount) {
            showWarning = true;
          }
          if (goal.period == BudgetPeriod.weekly &&
              now.weekday >= 6 &&
              saved < goal.amount) {
            showWarning = true;
          }
          if (goal.period == BudgetPeriod.yearly &&
              now.month >= 11 &&
              saved < goal.amount) {
            showWarning = true;
          }
        }

        if (showWarning) {
          warnings.add(
            _buildWarningTile(
              icon: Icons.track_changes,
              color: Colors.orange,
              title: AppLocalizations.of(
                context,
              )!.savingsFallingBehind(goal.name),
              subtitle: AppLocalizations.of(context)!.savingsWarning(
                currency,
                NumberFormat("#,##0", "en_US").format(saved),
                NumberFormat("#,##0", "en_US").format(goal.amount),
              ),
            ),
          );
        }
      }
    }

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.alertsInsights,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...warnings,
        ],
      ),
    );
  }

  // Builds a styled alert banner tile for a budget or savings warning.
  Widget _buildWarningTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoLocalizedText(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                AutoLocalizedText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Renders the active Saving Goals section on HomePage right between the Income & Expense
  // hero cards and the Expense Analytics pie chart, showing the item picture on the left,
  // dynamic days left, and how much is saved so far (adjusting with the main balance).
  // Reached/completed goals are automatically removed from here and posted to B&S History.
  Widget _buildActiveSavingGoalsSection(
    TransactionProvider provider,
    String currency,
  ) {
    final now = DateTime.now();
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

    if (activeSavings.isEmpty) {
      return const SizedBox.shrink();
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.savingGoals,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...activeSavings.map((goal) {
            final rawSaved = provider.getSavedAmountForGoal(goal);
            final saved = rawSaved.isFinite ? rawSaved : 0.0;
            final target =
                (goal.amount.isFinite && goal.amount > 0) ? goal.amount : 0.0;
            final rawPercent = (target > 0) ? (saved / target) : 0.0;
            final percent =
                rawPercent.isFinite ? rawPercent.clamp(0.0, 1.0) : 0.0;
            final daysLeft = provider.getDynamicDaysLeftForGoal(goal);
            final extraDays = provider.getExtraDaysAddedFromBalance(goal);
            final isNegativeSaved = saved < 0;
            final savedSign = isNegativeSaved ? '-' : '';
            final formattedSaved =
                '$savedSign$currency${settings.formatAmount(saved.abs())}';
            final formattedTarget = '$currency${settings.formatAmount(target)}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Picture of the item on the left
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildGoalThumbnail(
                      goal.productImageUrl,
                      size: 64,
                      fallback: _buildHomeFallbackGoalImage(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Days left and how much saved so far on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AutoLocalizedText(
                                goal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
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
                          ],
                        ),
                        if (goal.productSite != null &&
                            goal.productSite!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          AutoLocalizedText(
                            goal.productSite!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        if (extraDays > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.extraDaysNegativeBalance(extraDays),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.savedSoFar(formattedSaved),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isNegativeSaved
                                    ? Colors.redAccent
                                    : const Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              formattedTarget,
                              style: const TextStyle(
                                fontSize: 12,
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
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Safely renders a saving goal thumbnail using SafeProductImage so non-200 HTTP responses
  // never throw NetworkImageLoadException.
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

  // Fallback thumbnail icon for saving goals without a product image URL on HomePage.
  Widget _buildHomeFallbackGoalImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.savings_rounded,
        color: Color(0xFF10B981),
        size: 30,
      ),
    );
  }
}

/// Holds aggregated data for a single expense category slice in the Callout Pie Chart.
class _ExpenseSliceData {
  final String category;
  final double value;
  final double percentage;
  final IconData icon;
  final Color color;

  const _ExpenseSliceData({
    required this.category,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.color,
  });
}

/// Holds the computed geometry for a slice and its inside badge or outside leader-line callout.
class _PlacedSlice {
  final _ExpenseSliceData data;
  final double startAngle;
  final double sweepAngle;
  final bool isInside;
  final bool isRightSide;
  final Offset rimPoint;
  final Offset elbowPoint;
  final Offset tickEndPoint;
  final Offset insideCenter;

  const _PlacedSlice({
    required this.data,
    required this.startAngle,
    required this.sweepAngle,
    required this.isInside,
    required this.isRightSide,
    required this.rimPoint,
    required this.elbowPoint,
    required this.tickEndPoint,
    required this.insideCenter,
  });
}

/// Renders a solid pie chart where:
/// - Large slices display their category icon + percentage inside the slice.
/// - Small slices use angled leader callout lines pointing outside the pie to
///   automatically spaced-out category icon + percentage badges so icons never squish together.
class _CalloutPieChart extends StatelessWidget {
  final List<_ExpenseSliceData> slices;
  final String currencySymbol;

  const _CalloutPieChart({
    required this.slices,
    required this.currencySymbol,
  });

  String _formatPct(double pct) {
    if (pct >= 10) {
      return '${pct.toStringAsFixed(1)}%';
    } else if (pct >= 0.1) {
      return '${pct.toStringAsFixed(1)}%';
    }
    return '<0.1%';
  }

  List<_PlacedSlice> _computeLayout(Size size) {
    final total = slices.fold<double>(0.0, (s, item) => s + item.value);
    if (total <= 0 || slices.isEmpty) return const [];

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * 0.25, size.height * 0.35);

    double currentAngle = -math.pi / 2; // Start at 12 o'clock
    final List<_PlacedSlice> initial = [];

    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi;
      final mid = currentAngle + sweep / 2;
      final isSingle = slices.length == 1;
      // Place inside if the slice is wide enough (>= ~10.5% of the circle)
      final isInside = isSingle || sweep >= 0.66;
      final isRight = math.cos(mid) >= 0;

      final insideDist = isSingle ? 0.0 : radius * 0.56;
      final insidePos =
          center + Offset(math.cos(mid), math.sin(mid)) * insideDist;

      final rimPos =
          center + Offset(math.cos(mid), math.sin(mid)) * (radius * 0.98);
      final rawElbow =
          center + Offset(math.cos(mid), math.sin(mid)) * (radius + 14.0);

      initial.add(
        _PlacedSlice(
          data: s,
          startAngle: currentAngle,
          sweepAngle: sweep,
          isInside: isInside,
          isRightSide: isRight,
          rimPoint: rimPos,
          elbowPoint: rawElbow,
          tickEndPoint: rawElbow,
          insideCenter: insidePos,
        ),
      );
      currentAngle += sweep;
    }

    // Separate outside callouts into left and right groups and resolve vertical collisions
    final List<int> rightIndices = [];
    final List<int> leftIndices = [];
    for (int i = 0; i < initial.length; i++) {
      if (!initial[i].isInside) {
        if (initial[i].isRightSide) {
          rightIndices.add(i);
        } else {
          leftIndices.add(i);
        }
      }
    }

    void resolveSide(List<int> indices, {required bool isRight}) {
      if (indices.isEmpty) return;
      indices.sort(
        (a, b) =>
            initial[a].elbowPoint.dy.compareTo(initial[b].elbowPoint.dy),
      );

      const double minGap = 30.0;
      const double topBound = 16.0;
      final double bottomBound = math.max(topBound, size.height - 16.0);

      final List<double> ys = indices
          .map((idx) => initial[idx].elbowPoint.dy.clamp(topBound, bottomBound))
          .toList();

      // Top-down pass to push overlapping badges down
      for (int i = 1; i < ys.length; i++) {
        if (ys[i] - ys[i - 1] < minGap) {
          ys[i] = ys[i - 1] + minGap;
        }
      }

      // Clamp bottom and run bottom-up pass to keep within card height
      if (ys.last > bottomBound) {
        ys[ys.length - 1] = bottomBound;
        for (int i = ys.length - 2; i >= 0; i--) {
          if (ys[i + 1] - ys[i] < minGap) {
            ys[i] = math.max(topBound, ys[i + 1] - minGap);
          }
        }
      }

      for (int k = 0; k < indices.length; k++) {
        final idx = indices[k];
        final item = initial[idx];
        final adjustedY = ys[k];
        final dy = (adjustedY - center.dy).abs();
        final outerClearRadius = radius + 12.0;
        final minHorizontal = dy < outerClearRadius
            ? math.sqrt(outerClearRadius * outerClearRadius - dy * dy)
            : 10.0;

        final double elbowX = isRight
            ? math.max(item.elbowPoint.dx, center.dx + minHorizontal)
            : math.min(item.elbowPoint.dx, center.dx - minHorizontal);

        const double tickLen = 10.0;
        final double tickEndX = isRight ? elbowX + tickLen : elbowX - tickLen;

        initial[idx] = _PlacedSlice(
          data: item.data,
          startAngle: item.startAngle,
          sweepAngle: item.sweepAngle,
          isInside: false,
          isRightSide: isRight,
          rimPoint: item.rimPoint,
          elbowPoint: Offset(elbowX, adjustedY),
          tickEndPoint: Offset(tickEndX, adjustedY),
          insideCenter: item.insideCenter,
        );
      }
    }

    resolveSide(rightIndices, isRight: true);
    resolveSide(leftIndices, isRight: false);

    return initial;
  }

  void _showSliceTooltip(BuildContext context, _ExpenseSliceData slice) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final label = getLocalizedCategory(context, slice.category);
    final formatted = '$currencySymbol${settings.formatAmount(slice.value)}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(slice.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$label: $formatted (${_formatPct(slice.percentage)})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? Colors.white70 : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final placed = _computeLayout(size);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: size,
              painter: _CalloutPiePainter(
                placedSlices: placed,
                dividerColor: Theme.of(context).cardColor,
                leaderLineColor: lineColor,
              ),
            ),
            for (final p in placed)
              if (p.isInside)
                Positioned(
                  left: p.insideCenter.dx - 24,
                  top: p.insideCenter.dy - 22,
                  width: 48,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showSliceTooltip(context, p.data),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            p.data.icon,
                            color: p.data.color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPct(p.data.percentage),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  left: p.isRightSide
                      ? p.tickEndPoint.dx + 2
                      : p.tickEndPoint.dx - 68,
                  top: p.tickEndPoint.dy - 14,
                  width: 66,
                  height: 28,
                  child: GestureDetector(
                    onTap: () => _showSliceTooltip(context, p.data),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: p.isRightSide
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      children: [
                        if (!p.isRightSide) ...[
                          Flexible(
                            child: Text(
                              _formatPct(p.data.percentage),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: p.data.color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.data.color.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            p.data.icon,
                            color: p.data.color,
                            size: 14,
                          ),
                        ),
                        if (p.isRightSide) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatPct(p.data.percentage),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// CustomPainter that draws the solid pie slices and the outside callout leader lines.
class _CalloutPiePainter extends CustomPainter {
  final List<_PlacedSlice> placedSlices;
  final Color dividerColor;
  final Color leaderLineColor;

  const _CalloutPiePainter({
    required this.placedSlices,
    required this.dividerColor,
    required this.leaderLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (placedSlices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * 0.25, size.height * 0.35);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = dividerColor
      ..strokeWidth = 1.5;

    for (final s in placedSlices) {
      fillPaint.color = s.data.color;
      canvas.drawArc(rect, s.startAngle, s.sweepAngle, true, fillPaint);
      if (placedSlices.length > 1) {
        canvas.drawArc(rect, s.startAngle, s.sweepAngle, true, dividerPaint);
      }
    }

    // Draw callout leader lines (radial stem + horizontal tick) for small slices
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = leaderLineColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final s in placedSlices) {
      if (s.isInside) continue;
      final path = Path()
        ..moveTo(s.rimPoint.dx, s.rimPoint.dy)
        ..lineTo(s.elbowPoint.dx, s.elbowPoint.dy)
        ..lineTo(s.tickEndPoint.dx, s.tickEndPoint.dy);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalloutPiePainter oldDelegate) {
    return oldDelegate.placedSlices != placedSlices ||
        oldDelegate.dividerColor != dividerColor ||
        oldDelegate.leaderLineColor != leaderLineColor;
  }
}
