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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'category_localization.dart';
import 'add_transaction_screen.dart';
import 'history.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Tracks the optional selected date (null = show entire month), visible month focus, and calendar format.
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Navigates to AddExpenseScreen pre-filled with [date].
  Future<void> _openAddTransactionForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(initialDate: normalized),
      ),
    );
    if (!mounted) return;
    setState(() {
      _selectedDay = normalized;
      _focusedDay = normalized;
    });
  }

  // Formats a DateTime as Date only (no time), e.g. "2026/04/12".
  String _formatDateOnly(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // Builds the Transaction History layout with the interactive calendar on top
  // and the month/selected-day transaction list below.
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
          const Divider(height: 1),
          // 4. Filtered List (Month view + Selected date on top)
          Expanded(child: _buildFilteredList()),
        ],
      ),
    );
  }

  // Builds the TableCalendar widget:
  // - Viewing a month shows all transactions of that month.
  // - Clicking a date selects it and brings that date's transactions to the top of the list.
  // - Pressing the selected day again (or long-pressing any day) opens AddExpenseScreen for that date.
  Widget _buildCalendar() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return TableCalendar<AppTransaction>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (_selectedDay != null && isSameDay(_selectedDay, selectedDay)) {
              // Pressing the already-selected day opens Add Transaction for that date
              _openAddTransactionForDate(selectedDay);
              return;
            }
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onDayLongPressed: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _openAddTransactionForDate(selectedDay);
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _selectedDay =
                  null; // Show all transactions of the newly focused period
            });
          },
          onFormatChanged: (format) {
            setState(() {
              if (_selectedDay != null) {
                _focusedDay = _selectedDay!;
              }
              _calendarFormat = format;
              _selectedDay =
                  null; // Show all transactions of the newly selected format (month / 2 weeks / week)
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
          ),
          calendarBuilders: CalendarBuilders<AppTransaction>(
            singleMarkerBuilder: (context, date, event) {
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: event.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              );
            },
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

  // Computes the exact inclusive [startDate, endDate] and display label for the currently visible
  // calendar view (Month, 2 Weeks, or Week), matching TableCalendar's page calculation.
  (DateTime, DateTime, String) _getVisiblePeriodRangeAndLabel() {
    if (_calendarFormat == CalendarFormat.month) {
      final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      final label = DateFormat('MMMM yyyy').format(_focusedDay);
      return (start, end, label);
    }

    // TableCalendar's firstDay is DateTime.utc(2020, 1, 1) with default StartingDayOfWeek.sunday.
    final firstCalendarDay = DateTime.utc(2020, 1, 1);
    final baseSunday = firstCalendarDay.subtract(
      Duration(days: firstCalendarDay.weekday % 7),
    );
    final focusedUtc = DateTime.utc(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );

    if (_calendarFormat == CalendarFormat.twoWeeks) {
      final twoWeekIndex = focusedUtc.difference(baseSunday).inDays ~/ 14;
      final startUtc = baseSunday.add(Duration(days: twoWeekIndex * 14));
      final endUtc = startUtc.add(const Duration(days: 13));
      final start = DateTime(startUtc.year, startUtc.month, startUtc.day);
      final end = DateTime(endUtc.year, endUtc.month, endUtc.day);
      final label = '${_formatDateOnly(start)} – ${_formatDateOnly(end)}';
      return (start, end, label);
    } else {
      // CalendarFormat.week
      final weekIndex = focusedUtc.difference(baseSunday).inDays ~/ 7;
      final startUtc = baseSunday.add(Duration(days: weekIndex * 7));
      final endUtc = startUtc.add(const Duration(days: 6));
      final start = DateTime(startUtc.year, startUtc.month, startUtc.day);
      final end = DateTime(endUtc.year, endUtc.month, endUtc.day);
      final label = '${_formatDateOnly(start)} – ${_formatDateOnly(end)}';
      return (start, end, label);
    }
  }

  // Returns all transactions whose date falls within the inclusive [start, end] date range.
  List<AppTransaction> _getTransactionsInDateRange(
    List<AppTransaction> allTransactions,
    DateTime start,
    DateTime end,
  ) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return allTransactions
        .where(
          (t) =>
              !t.dateTime.isBefore(startDay) && !t.dateTime.isAfter(endDay),
        )
        .toList();
  }

  // Renders all transactions of the active calendar period (Month, 2 Weeks, or Week).
  // When a specific date (_selectedDay) is clicked:
  // - Shows the transactions of _selectedDay at the TOP (with a button to add a transaction for that date).
  // - Shows the rest of the visible period's transactions below, displaying only their DATE (not date and time).
  Widget _buildFilteredList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final (rangeStart, rangeEnd, periodLabel) =
            _getVisiblePeriodRangeAndLabel();
        final periodTransactions = _getTransactionsInDateRange(
          provider.transactions,
          rangeStart,
          rangeEnd,
        );

        // If no date is selected yet, show all transactions of the current period (Month / 2 Weeks / Week).
        if (_selectedDay == null) {
          if (periodTransactions.isEmpty) {
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

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Text(
                  '$periodLabel (${periodTransactions.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...periodTransactions.map(
                (tx) => _buildTransactionCard(
                  context,
                  tx,
                  showDateOnly: true,
                ),
              ),
            ],
          );
        }

        // A specific date is selected: split into selected date's transactions (top)
        // and the rest of the visible period's transactions (below, showing date only).
        final selectedDayTx = periodTransactions
            .where((t) => isSameDay(t.dateTime, _selectedDay))
            .toList();
        final restOfPeriodTx = periodTransactions
            .where((t) => !isSameDay(t.dateTime, _selectedDay))
            .toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // TOP SECTION: Selected Date Header + Add Transaction Button
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 18,
                    color: Color(0xFF0D47A1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateOnly(_selectedDay!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddTransactionForDate(_selectedDay!),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            if (selectedDayTx.isEmpty)
              InkWell(
                onTap: () => _openAddTransactionForDate(_selectedDay!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_task, size: 20, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${AppLocalizations.of(context)!.noTransactionsOnDate} • Tap to add',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...selectedDayTx.map(
                (tx) => _buildTransactionCard(
                  context,
                  tx,
                  showDateOnly: true,
                ),
              ),

            // REST OF THE PERIOD SECTION (shown in dates only, not date and time)
            if (restOfPeriodTx.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Text(
                  'Other transactions in $periodLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...restOfPeriodTx.map(
                (tx) => _buildTransactionCard(
                  context,
                  tx,
                  showDateOnly: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Builds a single transaction card showing its category, description, date (date only, not date & time),
  // formatted amount, and delete action.
  Widget _buildTransactionCard(
    BuildContext context,
    AppTransaction tx, {
    required bool showDateOnly,
  }) {
    final isIncome = tx.type == TransactionType.income;
    final dateLabel = _formatDateOnly(tx.dateTime);

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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tx.description.isNotEmpty) Text(tx.description),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Builder(
                  builder: (context) {
                    final settings = Provider.of<SettingsProvider>(context);
                    return Text(
                      '${isIncome ? '+' : '-'}${settings.currencySymbol}${settings.formatAmount(tx.amount)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
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
