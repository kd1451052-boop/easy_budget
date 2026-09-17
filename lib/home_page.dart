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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui'; // Required for the glassmorphism backdrop filter

import 'transaction_provider.dart';
import 'history.dart'; // Assuming your model is here
import 'settings_provider.dart';
import 'gamification_provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum FilterPeriod { year, month, week }

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

  String _getBucketLabel(int index, AppLocalizations l10n) {
    if (_selectedPeriod == FilterPeriod.week) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[index % 7];
    } else if (_selectedPeriod == FilterPeriod.month) {
      return 'W${index + 1}';
    } else {
      final months = [
        l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
        l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
        l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
      ];
      return months[index % 12];
    }
  }

  Map<int, TimeBucketData> _getComboChartBuckets(List<AppTransaction> filteredTransactions) {
    Map<int, TimeBucketData> buckets = {};
    int nBuckets = _selectedPeriod == FilterPeriod.week ? 7 : (_selectedPeriod == FilterPeriod.month ? 5 : 12);
    
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

  List<PieChartSectionData> _getPieChartData(
    List<AppTransaction> transactions,
    String currencySymbol,
  ) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final Map<String, double> categoryAmounts = {};
    final Map<String, IconData> categoryIcons = {};
    final Map<String, Color> categoryColors = {};

    for (var t in expenses) {
      categoryAmounts[t.category] = (categoryAmounts[t.category] ?? 0) + t.amount;
      categoryIcons[t.category] = t.icon;
      categoryColors[t.category] = t.iconColor;
    }

    final List<Color> sectionColors = [
      const Color(0xFF5442F5), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF3B82F6), // Blue
    ];

    int index = 0;
    return categoryAmounts.entries.map((entry) {
      final color = categoryColors[entry.key] ?? sectionColors[index % sectionColors.length];
      final icon = categoryIcons[entry.key] ?? Icons.category;
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n$currencySymbol${NumberFormat("#,##0", "en_US").format(entry.value)}',
        radius: 80, // Solid pie chart
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.transparent,
        ), // Hide raw text for cleaner look
        showTitle: false, // Turn off titles to keep the minimalist vibe
        badgeWidget: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        badgePositionPercentageOffset: 0.7,
      );
    }).toList();
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
          double comboMaxY = 0;
          double comboMinY = 0;
          for (var bucket in buckets.values) {
            if (bucket.income > comboMaxY) comboMaxY = bucket.income;
            if (bucket.expense > comboMaxY) comboMaxY = bucket.expense;
            if (bucket.netBalance > comboMaxY) comboMaxY = bucket.netBalance;
            if (bucket.netBalance < comboMinY) comboMinY = bucket.netBalance;
          }
          comboMaxY = comboMaxY * 1.2;
          if (comboMinY < 0) comboMinY = comboMinY * 1.2;
          if (comboMaxY == 0) comboMaxY = 100;

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
                          height: 220,
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
                          child: filteredExpense > 0
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sections: _getPieChartData(
                                          filteredTransactions,
                                          currencySymbol,
                                        ),
                                        centerSpaceRadius: 0,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.noExpensesYet,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                          'Income vs Expense',
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
                          margin: const EdgeInsets.only(bottom: 100), // To make room for FAB
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
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              _getBucketLabel(value.toInt(), AppLocalizations.of(context)!),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(show: true, drawVerticalLine: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: buckets.entries.map((e) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.income,
                                          color: const Color(0xFF10B981),
                                          width: 8,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                        BarChartRodData(
                                          toY: e.value.expense,
                                          color: const Color(0xFFEF4444),
                                          width: 8,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                                      spots: buckets.entries.map((e) => FlSpot(e.key.toDouble(), e.value.netBalance)).toList(),
                                      color: const Color(0xFF3B82F6), // Blue line for net balance
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
          // Streak Banner
          Consumer<GamificationProvider>(
            builder: (context, gamification, child) {
              if (gamification.currentStreak > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${gamification.currentStreak} Day Streak!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
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
          Text(
            '${Provider.of<SettingsProvider>(context).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(balance.abs())}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: balance >= 0 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              balance >= 0 ? 'Positive Balance' : 'Negative Balance',
              style: TextStyle(
                color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )
            ),
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

  Widget _buildGlassCard(
    String label,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
                    decoration: BoxDecoration(
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
              Text(
                '${Provider.of<SettingsProvider>(context).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildWarnings(TransactionProvider provider, String currency) {
    final now = DateTime.now();
    List<Widget> warnings = [];

    // Check Budgets
    for (var budget in provider.budgets) {
      if (budget.isFixed &&
          budget.targetDate != null &&
          budget.targetDate!.isBefore(now))
        continue; // Expired

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
      if (goal.isFixed &&
          goal.targetDate != null &&
          goal.targetDate!.isBefore(now))
        continue; // Expired

      final saved = provider.getSavedAmountForGoal(goal);
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
              saved < goal.amount)
            showWarning = true;
          if (goal.period == BudgetPeriod.weekly &&
              now.weekday >= 6 &&
              saved < goal.amount)
            showWarning = true;
          if (goal.period == BudgetPeriod.yearly &&
              now.month >= 11 &&
              saved < goal.amount)
            showWarning = true;
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
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
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
}
