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
import 'history_screen.dart';
import 'scanner.dart';
import 'add_transaction_screen.dart';
import 'settings_page.dart';
import 'settings_provider.dart';
import 'shared_bottom_nav.dart';

enum FilterPeriod { year, month, week }

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
    switch (_selectedPeriod) {
      case FilterPeriod.year:
        return '${now.year}';
      case FilterPeriod.month:
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[now.month - 1];
      case FilterPeriod.week:
        return 'This Week';
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> all) {
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
    List<Transaction> transactions,
    String currencySymbol,
  ) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final Map<String, double> categoryMap = {};

    for (var t in expenses) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
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
    return categoryMap.entries.map((entry) {
      final color = sectionColors[index % sectionColors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n$currencySymbol${entry.value.toStringAsFixed(0)}',
        radius: 24, // Thinner radius for a modern donut look
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.transparent,
        ), // Hide raw text for cleaner look
        showTitle: false, // Turn off titles to keep the minimalist vibe
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(
                filteredBalance,
                filteredIncome,
                filteredExpense,
              ),

              // Analytics Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'Expense Analytics',
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
                                centerSpaceRadius:
                                    60, // Wide center for donut chart
                                sectionsSpace: 4,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total Spent",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "$currencySymbol${filteredExpense.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'No expenses yet!',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                ),
              ),

              // Recent Transactions List
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(child: _buildTransactionList(filteredTransactions)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        backgroundColor: _primaryIndigo,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SharedBottomNav(currentIndex: 0),
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
                  const PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.year,
                    child: Text('Yearly'),
                  ),
                  const PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.month,
                    child: Text('Monthly'),
                  ),
                  const PopupMenuItem<FilterPeriod>(
                    value: FilterPeriod.week,
                    child: Text('Weekly'),
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
            '${Provider.of<SettingsProvider>(context).currencySymbol}${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Glassmorphism Cards
          Row(
            children: [
              Expanded(
                child: _buildGlassCard(
                  'Income',
                  income,
                  Icons.arrow_upward,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassCard(
                  'Expense',
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
                '${Provider.of<SettingsProvider>(context).currencySymbol}${amount.toStringAsFixed(2)}',
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

  Widget _buildTransactionList(List<Transaction> allFilteredTransactions) {
    final transactions = allFilteredTransactions.take(5).toList();

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          "No recent transactions.",
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;

        // Reuse model helpers to rebuild icon and color.
        final txIcon = tx.icon;
        final txColor = tx.iconColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: txColor.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(txIcon, color: txColor),
            ),
            title: Text(
              tx.category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              tx.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'}${Provider.of<SettingsProvider>(context).currencySymbol}${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF10B981)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
