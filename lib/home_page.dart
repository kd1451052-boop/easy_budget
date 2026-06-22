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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final Color _primaryIndigo = const Color(0xFF5442F5); // Matches the Figma prototype

  /// Groups expense transactions by category for the Donut Chart
  List<PieChartSectionData> _getPieChartData(TransactionProvider provider) {
    final expenses = provider.transactions.where((t) => t.type == TransactionType.expense).toList();
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
        title: '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
        radius: 24, // Thinner radius for a modern donut look
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.transparent), // Hide raw text for cleaner look
        showTitle: false, // Turn off titles to keep the minimalist vibe
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Softer background
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(provider),
              
              // Analytics Section
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text('Expense Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: provider.totalExpense > 0 
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: _getPieChartData(provider),
                              centerSpaceRadius: 60, // Wide center for donut chart
                              sectionsSpace: 4,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Total Spent", style: TextStyle(color: Colors.black54, fontSize: 12)),
                              Text("\$${provider.totalExpense.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          )
                        ],
                      )
                    : const Center(child: Text('No expenses yet!', style: TextStyle(color: Colors.black45))),
                ),
              ),

              // Recent Transactions List
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              Expanded(
                child: _buildTransactionList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        backgroundColor: _primaryIndigo,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- UI WIDGET EXTRACTS ---

  Widget _buildHeroHeader(TransactionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: _primaryIndigo,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('\$${provider.totalBalance.toStringAsFixed(2)}', 
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          // Glassmorphism Cards
          Row(
            children: [
              Expanded(child: _buildGlassCard('Income', provider.totalIncome, Icons.arrow_upward, const Color(0xFF10B981))),
              const SizedBox(width: 16),
              Expanded(child: _buildGlassCard('Expense', provider.totalExpense, Icons.arrow_downward, const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String label, double amount, IconData icon, Color iconColor) {
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
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    final transactions = provider.transactions.take(5).toList();
    
    if (transactions.isEmpty) {
      return const Center(child: Text("No recent transactions.", style: TextStyle(color: Colors.black45)));
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: txColor.withAlpha((0.1 * 255).round()), shape: BoxShape.circle),
              child: Icon(txIcon, color: txColor),
            ),
            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
            trailing: Text(
              '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome ? const Color(0xFF10B981) : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  // FIXED: Removed the Hive database functions from the UI list!
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        // Note: Pushing directly from a BottomNav isn't standard routing, but leaving it as you had it to prevent breaking your flow!
        if (index == 1) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
        if (index == 2) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Scanner()));
        if (index == 3) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _primaryIndigo,
      unselectedItemColor: Colors.grey.shade400,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}