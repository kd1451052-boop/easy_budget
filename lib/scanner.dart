import 'dart:convert';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // TEMP debug
import 'package:firebase_auth/firebase_auth.dart'; // TEMP debug
import 'package:intl/intl.dart';

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
        'Return JSON: {"merchant":"name","date":"yyyy-MM-dd","total":12.34,"currency":"JPY","items":[{"name":"item","price":1.23}]}',
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

      final data = jsonDecode(jsonString);

      final String? scannedCurrency = data['currency']?.toString();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
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

      _showResultBottomSheet(
        merchant: data['merchant']?.toString() ?? 'Unknown Merchant',
        total: double.tryParse(data['total']?.toString() ?? '0') ?? 0.0,
        dateString:
            data['date']?.toString() ??
            DateTime.now().toIso8601String().split('T')[0],
        items: List<Map<String, dynamic>>.from(data['items'] ?? []),
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

  void _showResultBottomSheet({
    required String merchant,
    required double total,
    required String dateString,
    required List<Map<String, dynamic>> items,
  }) {
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildResultRow(AppLocalizations.of(context)!.merchant, merchant),
            _buildResultRow(
              AppLocalizations.of(context)!.totalAmount,
              '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(total)}',
            ),
            _buildResultRow(AppLocalizations.of(context)!.date, dateString),

            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.items,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final price =
                      double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['name']?.toString() ??
                                AppLocalizations.of(context)!.unknownItem,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        Text(
                          '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${NumberFormat("#,##0.00", "en_US").format(price)}',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _saveTransaction(merchant, total, dateString, items);
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
                style: TextStyle(
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

  void _saveTransaction(
    String merchant,
    double total,
    String dateString,
    List<Map<String, dynamic>> items,
  ) {
    // Concatenate items for the description
    StringBuffer descriptionBuffer = StringBuffer();
    descriptionBuffer.writeln(merchant);
    for (var item in items) {
      final name = item['name'] ?? 'Item';
      final price = item['price'] ?? 0.0;
      descriptionBuffer.writeln('- $name: \$$price');
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateString);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final transaction = AppTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.expense,
      category: 'Shopping', // Default category for scanned receipts
      description: descriptionBuffer.toString().trim(),
      amount: total,
      dateTime: parsedDate,
      iconCodePoint: Icons.receipt.codePoint,
      iconColorValue: const Color(0xFF6366F1).toARGB32(),
    );

    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addTransaction(transaction);

    Provider.of<GamificationProvider>(
      context,
      listen: false,
    ).addReceiptScannedEvent();
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
