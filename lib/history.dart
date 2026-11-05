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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'settings_provider.dart';

enum TransactionType { income, expense }

extension TransactionTypeExtension on TransactionType {
  String toShortString() => toString().split('.').last;
  static TransactionType fromString(String str) =>
      TransactionType.values.firstWhere(
        (e) => e.toShortString() == str,
        orElse: () => TransactionType.expense,
      );
}

class AppTransaction {
  final String id;
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final DateTime dateTime;
  final int iconCodePoint;
  final int iconColorValue;

  AppTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.iconCodePoint,
    required this.iconColorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toShortString(),
      'category': category,
      'description': description,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'iconCodePoint': iconCodePoint,
      'iconColorValue': iconColorValue,
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map, String id) {
    final rawAmount = map['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0);
    return AppTransaction(
      id: id,
      type: TransactionTypeExtension.fromString(
        map['type']?.toString() ?? 'expense',
      ),
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      amount: parsedAmount.isFinite ? parsedAmount : 0.0,
      dateTime: map['dateTime'] != null
          ? (DateTime.tryParse(map['dateTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      iconCodePoint: map['iconCodePoint'] is int
          ? map['iconCodePoint'] as int
          : Icons.more_horiz.codePoint,
      iconColorValue: map['iconColorValue'] is int
          ? map['iconColorValue'] as int
          : Colors.grey.toARGB32(),
    );
  }

  static const List<IconData> _knownIcons = [
    Icons.star,
    Icons.bolt,
    Icons.coffee,
    Icons.fitness_center,
    Icons.flight,
    Icons.gamepad,
    Icons.medical_services,
    Icons.pets,
    Icons.school,
    Icons.local_bar,
    Icons.build,
    Icons.card_giftcard,
    Icons.movie,
    Icons.headset,
    Icons.directions_bike,
    Icons.attach_money,
    Icons.fastfood,
    Icons.directions_car,
    Icons.receipt_long,
    Icons.home,
    Icons.shopping_bag,
    Icons.trending_up,
    Icons.restaurant,
    Icons.more_horiz,
  ];

  IconData get icon {
    return _knownIcons.firstWhere(
      (i) => i.codePoint == iconCodePoint,
      orElse: () => Icons.more_horiz,
    );
  }

  Color get iconColor => Color(iconColorValue);
}

enum BudgetPeriod { weekly, monthly, yearly }

extension BudgetPeriodExtension on BudgetPeriod {
  String toShortString() => toString().split('.').last;
  static BudgetPeriod fromString(String str) => BudgetPeriod.values.firstWhere(
    (e) => e.toShortString() == str,
    orElse: () => BudgetPeriod.monthly,
  );
}

class Budget {
  final String id;
  final String name;
  final String note;
  final double amount;
  final bool isFixed; // true if fixed date, false if period
  final DateTime? targetDate;
  final BudgetPeriod? period;
  final String category;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.name,
    required this.note,
    required this.amount,
    required this.isFixed,
    this.targetDate,
    this.period,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'amount': amount,
      'isFixed': isFixed,
      'targetDate': targetDate?.toIso8601String(),
      'period': period?.toShortString(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    final rawAmount = map['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0);
    return Budget(
      id: id,
      name: map['name']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      amount: parsedAmount.isFinite ? parsedAmount : 0.0,
      isFixed: map['isFixed'] == true,
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'].toString())
          : null,
      period: map['period'] != null
          ? BudgetPeriodExtension.fromString(map['period'].toString())
          : null,
      category: map['category']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final String note;
  final double amount; // The target savings amount
  final bool isFixed;
  final DateTime? targetDate;
  final BudgetPeriod? period;
  final String category;
  final DateTime createdAt;

  // Optional AI product saving fields
  final String? productSite; // e.g., 'Amazon', 'Yahoo! Shopping', 'Rakuten Ichiba', 'Mercari'
  final String? productImageUrl; // Product thumbnail URL
  final String? productSiteUrl; // Store product/search URL
  final String? planMode; // 'usual' or 'cut_expenses'
  final double? plannedDailySaving; // Estimated daily saving rate calculated by AI
  final double? initialSavedBalance; // Main balance snapshot when goal was created
  final String? aiPlanSummary; // AI explanation / tips for achieving the goal
  final bool isCompleted; // True once the saving goal is met and moved to B&S History
  final DateTime? completedAt; // Timestamp when the saving goal was met

  SavingsGoal({
    required this.id,
    required this.name,
    required this.note,
    required this.amount,
    required this.isFixed,
    this.targetDate,
    this.period,
    required this.category,
    required this.createdAt,
    this.productSite,
    this.productImageUrl,
    this.productSiteUrl,
    this.planMode,
    this.plannedDailySaving,
    this.initialSavedBalance,
    this.aiPlanSummary,
    this.isCompleted = false,
    this.completedAt,
  });

  bool get isAiProductGoal =>
      (productSite != null && productSite!.isNotEmpty) ||
      (planMode != null && planMode!.isNotEmpty);

  // Creates an updated copy of this SavingsGoal (e.g. when marking it completed and moving to history).
  SavingsGoal copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? targetDate,
  }) {
    return SavingsGoal(
      id: id,
      name: name,
      note: note,
      amount: amount,
      isFixed: isFixed,
      targetDate: targetDate ?? this.targetDate,
      period: period,
      category: category,
      createdAt: createdAt,
      productSite: productSite,
      productImageUrl: productImageUrl,
      productSiteUrl: productSiteUrl,
      planMode: planMode,
      plannedDailySaving: plannedDailySaving,
      initialSavedBalance: initialSavedBalance,
      aiPlanSummary: aiPlanSummary,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'amount': amount,
      'isFixed': isFixed,
      'targetDate': targetDate?.toIso8601String(),
      'period': period?.toShortString(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'productSite': productSite,
      'productImageUrl': productImageUrl,
      'productSiteUrl': productSiteUrl,
      'planMode': planMode,
      'plannedDailySaving': plannedDailySaving,
      'initialSavedBalance': initialSavedBalance,
      'aiPlanSummary': aiPlanSummary,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map, String id) {
    final rawAmount = map['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0);
    return SavingsGoal(
      id: id,
      name: map['name']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      amount: parsedAmount.isFinite ? parsedAmount : 0.0,
      isFixed: map['isFixed'] == true,
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'].toString())
          : null,
      period: map['period'] != null
          ? BudgetPeriodExtension.fromString(map['period'].toString())
          : null,
      category: map['category']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      productSite: map['productSite']?.toString(),
      productImageUrl: map['productImageUrl']?.toString(),
      productSiteUrl: map['productSiteUrl']?.toString(),
      planMode: map['planMode']?.toString(),
      plannedDailySaving: map['plannedDailySaving'] != null
          ? double.tryParse(map['plannedDailySaving'].toString())
          : null,
      initialSavedBalance: map['initialSavedBalance'] != null
          ? double.tryParse(map['initialSavedBalance'].toString())
          : null,
      aiPlanSummary: map['aiPlanSummary']?.toString(),
      isCompleted: map['isCompleted'] == true,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
    );
  }
}

/// Safely loads and caches external product thumbnails using `package:http` and `Image.memory`
/// instead of `Image.network`, preventing `_network_image_io.dart` from throwing
/// `NetworkImageLoadException` (`DRT_ReThrow`) and pausing the IDE debugger on HTTP 403/404 responses.
class SafeProductImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final BoxFit fit;
  final Widget fallback;

  const SafeProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.cacheWidth = 160,
    this.fit = BoxFit.cover,
    required this.fallback,
  });

  @override
  State<SafeProductImage> createState() => _SafeProductImageState();
}

class _SafeProductImageState extends State<SafeProductImage> {
  static final Map<String, Uint8List?> _byteCache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant SafeProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _bytes = null;
      _loadBytes();
    }
  }

  // Fetches image bytes via HTTP GET with a browser-compatible User-Agent header,
  // returning null without throwing on non-200 status codes.
  static Future<Uint8List?> _fetchUrlBytes(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        url.contains('loremflickr.com') ||
        url.contains('unsplash.com') ||
        url.length > 500) {
      return null;
    }
    try {
      final resp = await http
          .get(
            uri,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) EasyBudget/1.0 Mobile',
              'Accept': 'image/*,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200 && resp.bodyBytes.length > 64) {
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  void _loadBytes() {
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) return;

    if (_byteCache.containsKey(url)) {
      _bytes = _byteCache[url];
      return;
    }

    final future = _inFlight.putIfAbsent(url, () => _fetchUrlBytes(url));
    future.then((result) {
      _byteCache[url] = result;
      _inFlight.remove(url);
      if (mounted && widget.imageUrl?.trim() == url && result != null) {
        setState(() {
          _bytes = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _bytes;
    if (data == null || data.isEmpty) {
      return widget.fallback;
    }
    return Image.memory(
      data,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      fit: widget.fit,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
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
  List<AppTransaction> get transactions => [
    AppTransaction(
      id: '1',
      type: TransactionType.expense,
      category: 'Food',
      description: 'Lunch with team',
      amount: 45.50,
      dateTime: DateTime(2026, 6, 11, 14, 46),
      iconCodePoint: Icons.restaurant.codePoint,
      iconColorValue: const Color(0xFFFF9800).toARGB32(),
    ),
    AppTransaction(
      id: '2',
      type: TransactionType.income,
      category: 'Salary',
      description: 'Monthly Salary',
      amount: 3000.00,
      dateTime: DateTime(2026, 6, 10, 14, 46),
      iconCodePoint: Icons.attach_money.codePoint,
      iconColorValue: const Color(0xFF4CAF50).toARGB32(),
    ),
    AppTransaction(
      id: '3',
      type: TransactionType.expense,
      category: 'Bill',
      description: 'Electricity Bill',
      amount: 120.00,
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
  Widget _buildTransactionRow(
    BuildContext context,
    AppTransaction transaction,
  ) {
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
            '${isIncome ? '+' : '-'}${Provider.of<SettingsProvider>(context).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(transaction.amount.abs())}',
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
