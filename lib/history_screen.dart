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
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'category_localization.dart';
import 'history.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Tracks the currently selected date, visible month/week focus, and calendar view format.
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Builds the Transaction History layout with the interactive calendar on top
  // and the selected day's transaction list below.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.transactionHistory,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 3. Calendar Feature
          _buildCalendar(),
          const Divider(),
          // 4. Filtered List
          Expanded(child: _buildFilteredList()),
        ],
      ),
    );
  }

  // Builds the TableCalendar widget, marking dates that have transactions and
  // updating _selectedDay whenever the user taps a date.
  Widget _buildCalendar() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          // Update _selectedDay using setState
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          // eventLoader: Check provider for transactions on a specific day
          eventLoader: (day) {
            return provider.getTransactionsForDate(day);
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF0D47A1),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            formatButtonShowsNext: false,
            titleCentered: true,
          ),
        );
      },
    );
  }

  // Queries TransactionProvider for transactions on _selectedDay and renders
  // either an empty placeholder or a list of transaction cards.
  Widget _buildFilteredList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // Call getTransactionsForDate from the Provider
        final filteredTransactions = provider.getTransactionsForDate(
          _selectedDay,
        );

        // 5. Empty State
        if (filteredTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noTransactionsOnDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final tx = filteredTransactions[index];
            final isIncome = tx.type == TransactionType.income;

            return GestureDetector(
              onLongPress: () => _showDeleteConfirmation(context, tx),
              child: Stack(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.iconColor.withValues(alpha: 0.1),
                        child: Icon(tx.icon, color: tx.iconColor, size: 20),
                      ),
                      title: Text(
                        getLocalizedCategory(context, tx.category),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(tx.description),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text(
                          '${isIncome ? '+' : '-'}${Provider.of<SettingsProvider>(context).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(tx.amount)}',
                          style: TextStyle(
                            color: isIncome
                                ? Colors.green
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFFBCAAA4),
                      ), // greyreddish
                      onPressed: () => _showDeleteConfirmation(context, tx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Prompts the user to confirm before deleting the selected transaction from TransactionProvider.
  void _showDeleteConfirmation(BuildContext context, AppTransaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.confirm,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this transaction?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () {
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).deleteTransaction(tx);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaction deleted.")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
