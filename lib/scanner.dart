import 'dart:convert';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // TEMP debug
import 'package:firebase_auth/firebase_auth.dart'; // TEMP debug

import 'settings_provider.dart';
import 'transaction_provider.dart';
import 'gamification_provider.dart';
import 'history.dart';

class _DebugHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String? overrideAppCheckToken;

  _DebugHttpClient({this.overrideAppCheckToken});

  http.Request _cloneRequest(http.BaseRequest original, List<int> bodyBytes) {
    final copy = http.Request(original.method, original.url)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..headers.addAll(original.headers)
      ..bodyBytes = bodyBytes;
    return copy;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();

    if (overrideAppCheckToken != null) {
      request.headers['X-Firebase-AppCheck'] = overrideAppCheckToken!;
    }

    var reqToSend = _cloneRequest(request, bodyBytes);
    var streamed = await _inner.send(reqToSend);
    var bytes = await streamed.stream.toBytes();

    // If cached token was rejected (401), retry with a force-refreshed standard token,
    // and then a limited-use token if Replay Protection is enforced.
    if (streamed.statusCode == 401) {
      for (final fetchToken in <Future<String?> Function()>[
        () => FirebaseAppCheck.instance.getToken(true),
        () => FirebaseAppCheck.instance.getLimitedUseToken(),
      ]) {
        try {
          final fallbackToken = await fetchToken();
          if (fallbackToken != null && fallbackToken.isNotEmpty) {
            final retryReq = _cloneRequest(request, bodyBytes);
            retryReq.headers['X-Firebase-AppCheck'] = fallbackToken;
            streamed = await _inner.send(retryReq);
            bytes = await streamed.stream.toBytes();
            if (streamed.statusCode != 401) break;
          }
        } catch (e) {
          debugPrint('AppCheck fallback token fetch failed: $e');
        }
      }
    }

    if (streamed.statusCode != 200) {
      debugPrint(
        'DBG_HTTP_ERR (${streamed.statusCode}): ${utf8.decode(bytes, allowMalformed: true)}',
      );
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      streamed.statusCode,
      contentLength: bytes.length,
      request: streamed.request,
      headers: streamed.headers,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );
  }
}

class Scanner extends StatefulWidget {
  final ImageSource? initialSource;
  const Scanner({super.key, this.initialSource});

  static void showScannerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              title: Text(AppLocalizations.of(context)!.scanWithCamera),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scanner(initialSource: ImageSource.camera),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF6366F1),
              ),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scanner(initialSource: ImageSource.gallery),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  bool _initialPickDone = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanReceipt(widget.initialSource!);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static const List<String> _builtInExpenseCategories = [
    'Food',
    'Transport',
    'Bill',
    'Rent',
    'Shopping',
  ];

  // Maps icon key names returned by Gemini or category names to tree-shakeable IconData
  // that are registered in AppTransaction._knownIcons and AddExpenseScreen.
  static const Map<String, IconData> _iconMap = {
    'fastfood': Icons.fastfood,
    'restaurant': Icons.restaurant,
    'coffee': Icons.coffee,
    'local_bar': Icons.local_bar,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'directions_bike': Icons.directions_bike,
    'home': Icons.home,
    'receipt_long': Icons.receipt_long,
    'bolt': Icons.bolt,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'school': Icons.school,
    'gamepad': Icons.gamepad,
    'movie': Icons.movie,
    'headset': Icons.headset,
    'card_giftcard': Icons.card_giftcard,
    'build': Icons.build,
    'star': Icons.star,
    'attach_money': Icons.attach_money,
  };

  // Resolves the proper IconData for any built-in or custom category so it never falls back to (...).
  IconData _resolveCategoryIcon(
    String category,
    String? aiIconKey,
    SettingsProvider settings,
  ) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Bill':
        return Icons.receipt_long;
      case 'Rent':
        return Icons.home;
      case 'Shopping':
        return Icons.shopping_bag;
    }

    if (settings.customExpenseCategories.containsKey(category)) {
      final code = settings.customExpenseCategories[category]!;
      for (final icon in _iconMap.values) {
        if (icon.codePoint == code) return icon;
      }
    }

    if (aiIconKey != null && _iconMap.containsKey(aiIconKey)) {
      return _iconMap[aiIconKey]!;
    }

    final lower = category.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('grocery') ||
        lower.contains('snack') ||
        lower.contains('meal') ||
        lower.contains('drink')) {
      return Icons.fastfood;
    }
    if (lower.contains('coffee') || lower.contains('cafe')) {
      return Icons.coffee;
    }
    if (lower.contains('cloth') ||
        lower.contains('apparel') ||
        lower.contains('fashion') ||
        lower.contains('wear') ||
        lower.contains('shoe')) {
      return Icons.shopping_bag;
    }
    if (lower.contains('med') ||
        lower.contains('health') ||
        lower.contains('pharm') ||
        lower.contains('drug')) {
      return Icons.medical_services;
    }
    if (lower.contains('transport') ||
        lower.contains('taxi') ||
        lower.contains('train') ||
        lower.contains('bus') ||
        lower.contains('fuel') ||
        lower.contains('gas')) {
      return Icons.directions_car;
    }
    if (lower.contains('bill') ||
        lower.contains('utilit') ||
        lower.contains('electric') ||
        lower.contains('water')) {
      return Icons.receipt_long;
    }
    if (lower.contains('pet')) return Icons.pets;
    if (lower.contains('game') || lower.contains('entertain')) {
      return Icons.gamepad;
    }
    if (lower.contains('movie') || lower.contains('cinema')) {
      return Icons.movie;
    }
    if (lower.contains('book') ||
        lower.contains('school') ||
        lower.contains('edu')) {
      return Icons.school;
    }
    if (lower.contains('gym') ||
        lower.contains('fitness') ||
        lower.contains('sport')) {
      return Icons.fitness_center;
    }
    return Icons.star;
  }

  // Ensures that if Gemini selected a category not in the built-in list, it is registered
  // in SettingsProvider.customExpenseCategories so it also appears in AddExpenseScreen.
  void _ensureCategoryRegistered(
    String category,
    IconData icon,
    SettingsProvider settings,
  ) {
    if (_builtInExpenseCategories.contains(category)) return;
    if (!settings.customExpenseCategories.containsKey(category)) {
      settings.addCustomExpenseCategory(category, icon.codePoint);
    }
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 30,
    );
    if (image == null) {
      if (widget.initialSource != null && !_initialPickDone) {
        _initialPickDone = true;
        if (mounted) Navigator.pop(context);
      }
      return;
    }
    _initialPickDone = true;
    if (!mounted) return;

    setState(() => _isScanning = true);

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final availableCategories = <String>[
        ..._builtInExpenseCategories,
        ...settings.customExpenseCategories.keys,
      ];

      String? dbgToken;
      try {
        // Use standard reusable cached token (valid for the full 1-hour TTL)
        dbgToken = await FirebaseAppCheck.instance.getToken(false);
      } catch (err) {
        debugPrint('DBG_APPCHECK_TOKEN_ERROR: $err');
      }
      final googleAI = FirebaseAI.googleAI(
        appCheck: FirebaseAppCheck.instance,
        auth: FirebaseAuth.instance,
        useLimitedUseAppCheckTokens: false,
      );
      final bytes = await image.readAsBytes();

      final prompt = TextPart(
        'Analyze this receipt image and return ONLY valid JSON in this exact format: '
        '{"merchant":"name","date":"yyyy-MM-dd","total":12.34,"currency":"JPY",'
        '"majorityCategory":"Food","majorityIcon":"fastfood","note":"optional note",'
        '"items":[{"name":"item","price":1.23,"category":"Food","icon":"fastfood"}]}. '
        'Rules for "category" on each item and "majorityCategory": '
        '1. Choose from existing categories when appropriate: ${availableCategories.join(", ")}. '
        '2. Food/groceries/drinks/restaurants MUST use "Food". '
        '3. If an item clearly belongs to a distinct category not in the list (e.g. "Clothes", "Medical", "Electronics", "Pets", "Coffee", "Entertainment"), '
        'create a short 1-word TitleCase category name (like "Clothes") so we can add it as a custom category. '
        '4. For "icon" and "majorityIcon", pick the closest match from: '
        '${_iconMap.keys.join(", ")}.',
      );
      final imagePart = InlineDataPart('image/jpeg', bytes);

      // Use 'gemini-flash-latest' (auto-updated alias) with 'gemini-3.8-flash' fallback
      // so future model retirements don't break receipt scanning.
      const candidateModels = ['gemini-flash-latest', 'gemini-3.8-flash'];
      GenerateContentResponse? response;
      Object? lastError;
      for (final modelName in candidateModels) {
        try {
          final model = googleAI.generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
            httpClient: _DebugHttpClient(overrideAppCheckToken: dbgToken),
          );
          response = await model.generateContent([
            Content.multi([prompt, imagePart]),
          ]);
          break;
        } catch (err) {
          lastError = err;
          debugPrint('Model $modelName failed, trying fallback if available: $err');
        }
      }
      if (response == null) {
        throw lastError ?? Exception('Failed to generate content');
      }

      if (!mounted) return;

      final text = response.text ?? '{}';
      // Clean up potential markdown formatting from Gemini response
      final jsonString = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(jsonString);

      // Handle both a single JSON object `{...}` and a JSON list of receipts `[{...}, {...}]`
      // (which Gemini returns when an image contains multiple receipts or sections).
      Map<String, dynamic> data;
      if (decoded is List) {
        final receiptMaps = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (receiptMaps.isEmpty) {
          data = <String, dynamic>{};
        } else if (receiptMaps.length == 1) {
          data = receiptMaps.first;
        } else {
          // Merge multiple receipts detected in the scan into one combined result
          final merchants = <String>[];
          double combinedTotal = 0.0;
          final combinedItems = <Map<String, dynamic>>[];
          String? firstDate;
          String? firstCurrency;
          String? firstMajorityCategory;
          String? firstMajorityIcon;

          for (final r in receiptMaps) {
            final m = r['merchant']?.toString().trim();
            if (m != null && m.isNotEmpty && !merchants.contains(m)) {
              merchants.add(m);
            }
            combinedTotal +=
                double.tryParse(r['total']?.toString() ?? '0') ?? 0.0;
            firstDate ??= r['date']?.toString();
            firstCurrency ??= r['currency']?.toString();
            firstMajorityCategory ??= r['majorityCategory']?.toString();
            firstMajorityIcon ??= r['majorityIcon']?.toString();

            final rItems =
                (r['items'] as List?)
                    ?.whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                const <Map<String, dynamic>>[];
            combinedItems.addAll(rItems);
          }

          data = <String, dynamic>{
            'merchant': merchants.isNotEmpty
                ? merchants.join(' & ')
                : 'Multiple Receipts',
            'date': firstDate,
            'total': combinedTotal,
            'currency': firstCurrency,
            'majorityCategory': firstMajorityCategory,
            'majorityIcon': firstMajorityIcon,
            'items': combinedItems,
          };
        }
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      } else {
        data = <String, dynamic>{};
      }

      final String? scannedCurrency = data['currency']?.toString();
      if (scannedCurrency != null &&
          scannedCurrency != settings.selectedCurrency) {
        // If the parsed currency is valid and different, update it
        if ([
          'USD',
          'EUR',
          'GBP',
          'JPY',
          'AUD',
          'CAD',
        ].contains(scannedCurrency)) {
          settings.updateCurrency(scannedCurrency);
        }
      }

      settings.incrementGuestScanCount();

      final rawItems =
          (data['items'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];
      final fallbackCategory =
          (data['majorityCategory']?.toString().trim().isNotEmpty ?? false)
          ? data['majorityCategory'].toString().trim()
          : 'Food';
      final fallbackIconKey = data['majorityIcon']?.toString().trim();

      // Normalize each item's category and icon
      final normalizedItems = rawItems.map((item) {
        final rawCat = item['category']?.toString().trim() ?? '';
        final cat = rawCat.isNotEmpty ? rawCat : fallbackCategory;
        final iconKey = item['icon']?.toString().trim() ?? fallbackIconKey;
        return <String, dynamic>{
          'name': item['name']?.toString() ?? 'Item',
          'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'category': cat,
          'icon': iconKey,
        };
      }).toList();

      _showResultBottomSheet(
        merchant: data['merchant']?.toString() ?? 'Unknown Merchant',
        total: double.tryParse(data['total']?.toString() ?? '0') ?? 0.0,
        dateString:
            data['date']?.toString() ??
            DateTime.now().toIso8601String().split('T')[0],
        items: normalizedItems,
        majorityCategory: fallbackCategory,
        majorityIconKey: fallbackIconKey,
        aiNote: data['note']?.toString(),
      );
    } catch (e, st) {
      debugPrint('Receipt scan failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorScanningReceipt(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // Groups items by category to determine whether the receipt can be split into
  // multiple category transactions or saved under the majority category with a note.
  Map<String, List<Map<String, dynamic>>> _groupItemsByCategory(
    List<Map<String, dynamic>> items,
    String fallbackCategory,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in items) {
      final cat = (item['category']?.toString().trim().isNotEmpty ?? false)
          ? item['category'].toString().trim()
          : fallbackCategory;
      groups.putIfAbsent(cat, () => []).add(item);
    }
    return groups;
  }

  void _showResultBottomSheet({
    required String merchant,
    required double total,
    required String dateString,
    required List<Map<String, dynamic>> items,
    required String majorityCategory,
    String? majorityIconKey,
    String? aiNote,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final groups = _groupItemsByCategory(items, majorityCategory);
    final hasMultipleCategories = groups.length > 1;
    final canSplitByPrice =
        hasMultipleCategories &&
        groups.values.every(
          (g) => g.fold<double>(0.0, (s, i) => s + (i['price'] as double)) > 0,
        );

    final categorySummary = groups.keys.isNotEmpty
        ? groups.keys.join(', ')
        : majorityCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.scanResult,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow(AppLocalizations.of(context)!.merchant, merchant),
            _buildResultRow(
              AppLocalizations.of(context)!.totalAmount,
              '${settings.currencySymbol}${settings.formatAmount(total)}',
            ),
            _buildResultRow(AppLocalizations.of(context)!.date, dateString),
            _buildResultRow(
              AppLocalizations.of(context)!.category,
              categorySummary,
            ),
            if (hasMultipleCategories) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.call_split_rounded,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        canSplitByPrice
                            ? 'Mixed items detected: Will save ${groups.length} separate transactions ($categorySummary).'
                            : 'Mixed items detected: Will save under majority category with a note.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.items,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                  final itemCat =
                      item['category']?.toString() ?? majorityCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name'] ?? AppLocalizations.of(context)!.unknownItem} ($itemCat)',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        Text(
                          '${settings.currencySymbol}${settings.formatAmount(price)}',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _saveTransaction(
                  merchant: merchant,
                  total: total,
                  dateString: dateString,
                  items: items,
                  majorityCategory: majorityCategory,
                  majorityIconKey: majorityIconKey,
                  aiNote: aiNote,
                );
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.confirmAndSave,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.retake,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Persists the scanned receipt(s) into TransactionProvider and Firestore,
  // splitting mixed-category items proportionally up to the receipt total.
  Future<void> _saveTransaction({
    required String merchant,
    required double total,
    required String dateString,
    required List<Map<String, dynamic>> items,
    required String majorityCategory,
    String? majorityIconKey,
    String? aiNote,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final gamification = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );
    final symbol = settings.currencySymbol;

    final now = DateTime.now();
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateString);
    } catch (_) {
      parsedDate = now;
    }

    // If the receipt has an older date (e.g. a sample receipt from 2020-10-18) or future date,
    // use today's date so the transaction appears immediately on HomePage and today's HistoryScreen,
    // and record the original printed receipt date in the description note.
    final bool isCurrentMonth =
        parsedDate.year == now.year && parsedDate.month == now.month;
    final DateTime transactionDate = isCurrentMonth ? parsedDate : now;
    final String? originalDateNote = isCurrentMonth
        ? null
        : 'Receipt Date: $dateString';

    final groups = _groupItemsByCategory(items, majorityCategory);
    final hasMultipleCategories = groups.length > 1;
    final canSplitByPrice =
        hasMultipleCategories &&
        groups.values.every(
          (g) => g.fold<double>(0.0, (s, i) => s + (i['price'] as double)) > 0,
        );

    if (canSplitByPrice) {
      // Calculate total of extracted item prices so we can scale proportionally
      // if the receipt total includes taxes or additional receipts not itemized.
      final double itemsSum = items.fold<double>(
        0.0,
        (sum, i) => sum + ((i['price'] as num?)?.toDouble() ?? 0.0),
      );
      final double scaleFactor = (total > 0 && itemsSum > 0)
          ? (total / itemsSum)
          : 1.0;

      // Split into separate transactions for each category (e.g. Food and Shopping)
      int idx = 0;
      final allCategories = groups.keys.toList();
      double allocatedSoFar = 0.0;

      for (final entry in groups.entries) {
        final category = entry.key;
        final catItems = entry.value;
        final rawSubtotal = catItems.fold<double>(
          0.0,
          (sum, i) => sum + ((i['price'] as num?)?.toDouble() ?? 0.0),
        );
        final bool isLast = idx == groups.length - 1;
        double adjustedAmount;
        if (total > 0 && itemsSum > 0) {
          if (isLast) {
            adjustedAmount = (total - allocatedSoFar).clamp(0.0, total);
          } else {
            adjustedAmount = settings.currencyHasDecimals
                ? double.parse(
                    (rawSubtotal * scaleFactor).toStringAsFixed(2),
                  )
                : (rawSubtotal * scaleFactor).roundToDouble();
            allocatedSoFar += adjustedAmount;
          }
        } else {
          adjustedAmount = rawSubtotal;
        }

        final firstIconKey = catItems.first['icon']?.toString();
        final iconData = _resolveCategoryIcon(category, firstIconKey, settings);

        // Register as a custom category in AddExpenseScreen if not built-in
        _ensureCategoryRegistered(category, iconData, settings);

        final otherCategories = allCategories
            .where((c) => c != category)
            .join(', ');
        final descriptionBuffer = StringBuffer()..writeln(merchant);
        if (originalDateNote != null) {
          descriptionBuffer.writeln(originalDateNote);
        }
        for (final item in catItems) {
          final name = item['name'] ?? 'Item';
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          descriptionBuffer.writeln(
            '- $name: $symbol${settings.formatAmount(price)}',
          );
        }
        descriptionBuffer.writeln(
          'Note: Split receipt (${idx + 1}/${groups.length}) — also had $otherCategories',
        );

        final transaction = AppTransaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_$idx',
          type: TransactionType.expense,
          category: category,
          description: descriptionBuffer.toString().trim(),
          amount: adjustedAmount,
          dateTime: transactionDate,
          iconCodePoint: iconData.codePoint,
          iconColorValue: Colors.red.toARGB32(),
        );
        await txProvider.addTransaction(transaction);
        idx++;
      }
    } else {
      // Single category OR mixed items without individual prices -> use majority category + note
      String chosenCategory = majorityCategory;
      String? chosenIconKey = majorityIconKey;

      if (groups.isNotEmpty) {
        // Pick category with the most items (or highest subtotal)
        final sortedEntries = groups.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
        chosenCategory = sortedEntries.first.key;
        chosenIconKey =
            sortedEntries.first.value.first['icon']?.toString() ??
            majorityIconKey;
      }

      final iconData = _resolveCategoryIcon(
        chosenCategory,
        chosenIconKey,
        settings,
      );
      _ensureCategoryRegistered(chosenCategory, iconData, settings);

      final descriptionBuffer = StringBuffer()..writeln(merchant);
      if (originalDateNote != null) {
        descriptionBuffer.writeln(originalDateNote);
      }
      for (final item in items) {
        final name = item['name'] ?? 'Item';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final itemCat = item['category']?.toString() ?? chosenCategory;
        final catSuffix = hasMultipleCategories ? ' [$itemCat]' : '';
        descriptionBuffer.writeln(
          '- $name$catSuffix: $symbol${settings.formatAmount(price)}',
        );
      }

      if (hasMultipleCategories) {
        final otherCats = groups.keys
            .where((c) => c != chosenCategory)
            .join(', ');
        descriptionBuffer.writeln(
          'Note: Majority category ($chosenCategory); receipt also included $otherCats.',
        );
      } else if (aiNote != null && aiNote.trim().isNotEmpty) {
        descriptionBuffer.writeln('Note: ${aiNote.trim()}');
      }

      final double finalAmount = total > 0
          ? total
          : items.fold<double>(
              0.0,
              (sum, i) => sum + ((i['price'] as num?)?.toDouble() ?? 0.0),
            );

      final transaction = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.expense,
        category: chosenCategory,
        description: descriptionBuffer.toString().trim(),
        amount: finalAmount,
        dateTime: transactionDate,
        iconCodePoint: iconData.codePoint,
        iconColorValue: Colors.red.toARGB32(),
      );

      await txProvider.addTransaction(transaction);
    }

    gamification.addReceiptScannedEvent();
  }

  // Builds a key-value summary row in the Scan Result bottom sheet with overflow protection.
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: _isScanning
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.scanningReceipt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
