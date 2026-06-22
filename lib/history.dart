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
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

part 'history.g.dart';

/// Hive uses typeId to uniquely identify classes when saving data.
/// This enum represents the type of transaction.
/// @HiveType(typeId: 1) tells the generator to create an adapter for this enum.
/// @HiveField(index) marks each value so it can be stored persistently.
@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

/// The main data model for a Transaction.
/// Extending [HiveObject] gives us helper methods like [save()] and [delete()]
/// directly on the object instance.
@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final TransactionType type;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  final DateTime dateTime;
  @HiveField(6)
  final int iconCodePoint;
  @HiveField(7)
  final int iconColorValue;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.iconCodePoint,
    required this.iconColorValue,
  });

  /// Reconstructs [IconData] from the stored integer code point.
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// Reconstructs [Color] from the stored integer value.
  Color get iconColor => Color(iconColorValue);
}

/// A simple helper class for the calendar UI to track day state.
class CalendarDay {
  final DateTime date;
  final bool hasIncome;
  final bool hasExpense;
  final bool isSelected;

  CalendarDay({
    required this.date,
    this.hasIncome = false,
    this.hasExpense = false,
    this.isSelected = false,
  });
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  /// Temporary mock data used for initial UI development.
  /// In a real app, this would be fetched from the [TransactionRepository].
  List<Transaction> get transactions => [
    Transaction(
      id: '1',
      type: TransactionType.expense,
      category: 'Food',
      description: 'Lunch with team',
      amount: -45.50,
      dateTime: DateTime(2026, 6, 11, 14, 46),
      iconCodePoint: Icons.restaurant.codePoint,
      iconColorValue: const Color(0xFFFF9800).toARGB32(),
    ),
    Transaction(
      id: '2',
      type: TransactionType.income,
      category: 'Salary',
      description: 'Monthly Salary',
      amount: 3000.00,
      dateTime: DateTime(2026, 6, 10, 14, 46),
      iconCodePoint: Icons.attach_money.codePoint,
      iconColorValue: const Color(0xFF4CAF50).toARGB32(),
    ),
    Transaction(
      id: '3',
      type: TransactionType.expense,
      category: 'Bill',
      description: 'Electricity Bill',
      amount: -120.00,
      dateTime: DateTime(2026, 6, 8, 14, 46),
      iconCodePoint: Icons.bolt.codePoint,
      iconColorValue: const Color(0xFF2196F3).toARGB32(),
    ),
  ];

  /// Converts a [DateTime] object into a user-friendly string (e.g., "Jun 11, 14:46 PM").
  String _formatDateTime(DateTime dateTime) {
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
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) =>
                          _buildTransactionRow(context, transactions[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal scrolling list of dates at the top of the screen.
  /// It highlights the selected day and shows dots for income/expenses.
  Widget _buildCalendarStrip() {
    // Mocking a weekly strip
    final days = List.generate(
      7,
      (i) => DateTime.now().add(Duration(days: i - 3)),
    );
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = index == 3; // Mocking today as selected
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ][date.weekday % 7],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: !isSelected
                        ? Border.all(color: Colors.grey.shade200)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index % 2 == 0)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (index % 3 == 0) const SizedBox(width: 2),
                    if (index % 3 == 0)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shown when there is no data to display for the current selection.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions for this day',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// A single row representing a transaction in the history list.
  Widget _buildTransactionRow(BuildContext context, Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: transaction.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(transaction.icon, color: transaction.iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.description} • ${_formatDateTime(transaction.dateTime)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Provider.of<SettingsProvider>(context).currencySymbol}${transaction.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
