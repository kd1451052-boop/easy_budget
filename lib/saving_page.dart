import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'currency_input_formatter.dart';
import 'store_api_service.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'auto_translator.dart';

// HTTP client wrapper that attaches the cached Firebase App Check token and retries
// with a refreshed token if the Gemini API returns HTTP 401.
class _SavingAiHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String? overrideAppCheckToken;

  _SavingAiHttpClient({this.overrideAppCheckToken});

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
          debugPrint('Saving AI AppCheck fallback token failed: $e');
        }
      }
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

// Represents a single e-commerce or manual item offer with its visual product photo,
// store/source label, target price, badge, and whether the price is an AI estimate or live store price.
class AiProductOffer {
  final String title;
  final String siteName;
  final double price;
  final String imageUrl;
  final String siteUrl;
  final String badge;
  final bool isEstimate;

  AiProductOffer({
    required this.title,
    required this.siteName,
    required this.price,
    required this.imageUrl,
    required this.siteUrl,
    required this.badge,
    this.isEstimate = true,
  });
}

// Holds the AI-calculated saving plan comparing the "Usual" plan (little/no cutting)
// against the "Cut Unnecessary Expenses" plan based on the user's transaction history.
class AiSavingAnalysis {
  final int usualDays;
  final double usualDailySaving;
  final String usualSummary;
  final int cutDays;
  final double cutDailySaving;
  final String cutSummary;
  final List<String> cutTips;

  AiSavingAnalysis({
    required this.usualDays,
    required this.usualDailySaving,
    required this.usualSummary,
    required this.cutDays,
    required this.cutDailySaving,
    required this.cutSummary,
    required this.cutTips,
  });
}

class SavingPage extends StatefulWidget {
  const SavingPage({super.key});

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  // Controllers for the AI product search bar and the remade Manual Custom Item inputs.
  final _searchController = TextEditingController();
  final _manualNameController = TextEditingController();
  final _manualPriceController = TextEditingController();
  final _manualStoreController = TextEditingController();
  final _manualNoteController = TextEditingController();

  // Tracks whether the user is using the AI Store Search tab (false) or the Manual Custom Item tab (true).
  bool _isManualMode = false;

  // State variables for AI product search, autocomplete suggestions, active offer, and AI plan analysis.
  bool _isSearchingProducts = false;
  Timer? _suggestDebounce;
  List<String> _autocompleteSuggestions = [];
  List<AiProductOffer> _searchResults = [];
  AiProductOffer? _selectedProduct;
  bool _isAnalyzingTransactions = false;
  AiSavingAnalysis? _aiAnalysis;
  String _selectedPlanMode = 'usual'; // 'usual' or 'cut_expenses'

  // Connected Rakuten Ichiba & Yahoo! Shopping credentials for live price search.
  StoreCredentials _credentials = const StoreCredentials();

  @override
  void initState() {
    super.initState();
    _loadStoreCredentials();
  }

  Future<void> _loadStoreCredentials() async {
    final loaded = await StoreCredentials.load();
    if (!mounted) return;
    setState(() {
      _credentials = loaded;
    });
  }

  // Opens a modal bottom sheet allowing the user to connect their Rakuten Ichiba
  // and Yahoo! Shopping accounts/keys so the app can fetch real live store prices on its own.
  Future<void> _showConnectStoresSheet() async {
    final rakutenIdCtrl = TextEditingController(text: _credentials.rakutenAppId);
    final rakutenKeyCtrl = TextEditingController(
      text: _credentials.rakutenAccessKey,
    );
    final yahooIdCtrl = TextEditingController(text: _credentials.yahooClientId);
    bool isTesting = false;
    String? statusMessage;
    bool statusIsError = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connect Rakuten & Yahoo! Shopping',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect your Rakuten Ichiba and Yahoo! Shopping developer keys so the app can search real-time store prices and product images on its own. Unconnected stores are clearly labeled as "AI estimate".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // RAKUTEN SECTION
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBF0000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Rakuten Ichiba',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'webservice.rakuten.co.jp',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rakutenIdCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rakuten Application ID',
                        hintText: 'e.g. 1023456789... or UUID',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rakutenKeyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rakuten Access Key (Optional / OpenAPI)',
                        hintText: 'e.g. pk_... (leave blank for classic App ID)',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // YAHOO! SHOPPING SECTION
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0033),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Yahoo! Shopping',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'developer.yahoo.co.jp (Client ID / appid)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: yahooIdCtrl,
                      decoration: InputDecoration(
                        labelText: 'Yahoo! Japan Client ID (appid)',
                        hintText: 'e.g. dj00aiZpPV...',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (statusIsError ? Colors.red : Colors.green)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (statusIsError ? Colors.red : Colors.green)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusIsError
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isTesting
                                ? null
                                : () async {
                                    setSheetState(() {
                                      isTesting = true;
                                      statusMessage = null;
                                    });
                                    final List<String> checks = [];
                                    bool hasErr = false;
                                    if (rakutenIdCtrl.text.trim().isNotEmpty) {
                                      final err =
                                          await StoreApiService.testRakuten(
                                            appId: rakutenIdCtrl.text,
                                            accessKey: rakutenKeyCtrl.text,
                                          );
                                      if (err != null) {
                                        hasErr = true;
                                        checks.add('Rakuten: $err');
                                      } else {
                                        checks.add(
                                          'Rakuten Ichiba: Connected & verified!',
                                        );
                                      }
                                    }
                                    if (yahooIdCtrl.text.trim().isNotEmpty) {
                                      final err =
                                          await StoreApiService.testYahoo(
                                            clientId: yahooIdCtrl.text,
                                          );
                                      if (err != null) {
                                        hasErr = true;
                                        checks.add('Yahoo!: $err');
                                      } else {
                                        checks.add(
                                          'Yahoo! Shopping: Connected & verified!',
                                        );
                                      }
                                    }
                                    if (checks.isEmpty) {
                                      hasErr = true;
                                      checks.add(
                                        'Enter a Rakuten Application ID or Yahoo! Client ID to test.',
                                      );
                                    }
                                    setSheetState(() {
                                      isTesting = false;
                                      statusIsError = hasErr;
                                      statusMessage = checks.join('\n');
                                    });
                                  },
                            icon: isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.bolt_rounded, size: 18),
                            label: const Text('Test Connection'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final updated = StoreCredentials(
                                rakutenAppId: rakutenIdCtrl.text.trim(),
                                rakutenAccessKey: rakutenKeyCtrl.text.trim(),
                                yahooClientId: yahooIdCtrl.text.trim(),
                              );
                              await updated.save();
                              if (!mounted) return;
                              setState(() {
                                _credentials = updated;
                              });
                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                              }
                              if (_searchController.text.trim().isNotEmpty) {
                                _searchProductsWithAi();
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Save & Use'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Queries connected Rakuten Ichiba & Yahoo! Shopping APIs directly for live prices and images.
  Future<(List<AiProductOffer>, List<String>)> _searchLiveStores(
    String query,
  ) async {
    final List<AiProductOffer> liveOffers = [];
    final List<String> errors = [];

    final futures = <Future<void>>[];

    if (_credentials.hasRakuten) {
      futures.add(() async {
        final res = await StoreApiService.searchRakuten(
          query: query,
          appId: _credentials.rakutenAppId,
          accessKey: _credentials.rakutenAccessKey,
          hits: 2,
        );
        if (res.error != null) {
          errors.add(res.error!);
        }
        for (final item in res.items) {
          liveOffers.add(
            AiProductOffer(
              title: item.title,
              siteName: item.siteName,
              price: item.price,
              imageUrl: item.imageUrl,
              siteUrl: item.siteUrl,
              badge: item.badge,
              isEstimate: false,
            ),
          );
        }
      }());
    }

    if (_credentials.hasYahoo) {
      futures.add(() async {
        final res = await StoreApiService.searchYahoo(
          query: query,
          clientId: _credentials.yahooClientId,
          hits: 2,
        );
        if (res.error != null) {
          errors.add(res.error!);
        }
        for (final item in res.items) {
          liveOffers.add(
            AiProductOffer(
              title: item.title,
              siteName: item.siteName,
              price: item.price,
              imageUrl: item.imageUrl,
              siteUrl: item.siteUrl,
              badge: item.badge,
              isEstimate: false,
            ),
          );
        }
      }());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    return (liveOffers, errors);
  }

  // Places verified live store listings first, followed by AI-estimated listings for unconnected stores.
  List<AiProductOffer> _mergeLiveAndEstimates(
    List<AiProductOffer> liveOffers,
    List<AiProductOffer> aiOffers,
  ) {
    if (liveOffers.isEmpty) return aiOffers;
    final hasLiveRakuten = liveOffers.any(
      (o) => o.siteName.toLowerCase().contains('rakuten'),
    );
    final hasLiveYahoo = liveOffers.any(
      (o) => o.siteName.toLowerCase().contains('yahoo'),
    );

    // If a live store returned a real product photo, share that verified photo with AI estimate cards
    // that didn't find an image so all cards show the real product picture.
    final livePhoto = liveOffers
        .map((o) => o.imageUrl)
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');

    final filteredEstimates = aiOffers
        .where((o) {
          final lower = o.siteName.toLowerCase();
          if (hasLiveRakuten && lower.contains('rakuten')) return false;
          if (hasLiveYahoo && lower.contains('yahoo')) return false;
          return true;
        })
        .map(
          (o) => o.imageUrl.isEmpty && livePhoto.isNotEmpty
              ? AiProductOffer(
                  title: o.title,
                  siteName: o.siteName,
                  price: o.price,
                  imageUrl: livePhoto,
                  siteUrl: o.siteUrl,
                  badge: o.badge,
                  isEstimate: o.isEstimate,
                )
              : o,
        )
        .toList();

    return [...liveOffers, ...filteredEstimates];
  }

  // Popular full product names used for instant local prefix/substring matching alongside live Amazon autocomplete.
  static const List<String> _popularProductCatalog = [
    'Apple MacBook Pro 14-inch M3',
    'Apple MacBook Pro 16-inch M3 Max',
    'Apple MacBook Air 13-inch M3',
    'Apple MacBook Air 15-inch M3',
    'Apple iPhone 16 Pro Max',
    'Apple iPhone 16 Pro',
    'Apple iPhone 16',
    'Apple iPad Pro M4',
    'Apple iPad Air M2',
    'Apple AirPods Pro 2',
    'Apple AirPods Max',
    'Apple Watch Ultra 2',
    'Apple Watch Series 10',
    'Sony PlayStation 5 (PS5)',
    'Sony PlayStation 5 Pro',
    'Sony WH-1000XM5 Wireless Headphones',
    'Sony WF-1000XM5 Earbuds',
    'Sony Alpha a7 IV Mirrorless Camera',
    'Nintendo Switch OLED Model',
    'Nintendo Switch Lite',
    'Samsung Galaxy S24 Ultra',
    'Samsung Galaxy Z Fold 6',
    'Samsung Galaxy Tab S9',
    'Dyson Airwrap Multi-Styler',
    'Dyson V15 Detect Cordless Vacuum',
    'Bose QuietComfort Ultra Headphones',
    'Canon EOS R6 Mark II',
    'Fujifilm X100VI Digital Camera',
    'GoPro HERO13 Black',
    'Steam Deck OLED 512GB',
    'Dell XPS 14 Laptop',
    'ASUS ROG Ally X',
    'Keychron Q1 Pro Mechanical Keyboard',
    'Logitech MX Master 3S Mouse',
  ];

  // Disposes text controllers and active debounce timers when the screen is closed.
  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _searchController.dispose();
    _manualNameController.dispose();
    _manualPriceController.dispose();
    _manualStoreController.dispose();
    _manualNoteController.dispose();
    super.dispose();
  }

  // Updates autofill product name suggestions as the user types in the search bar,
  // combining instant catalog matches (e.g. "apple mac b" -> "Apple MacBook Pro", "Apple MacBook Air")
  // with live Amazon Japan & Google Shopping autocomplete suggestions.
  void _onSearchQueryChanged(String rawValue) {
    _suggestDebounce?.cancel();
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      if (_autocompleteSuggestions.isNotEmpty) {
        setState(() => _autocompleteSuggestions = []);
      }
      return;
    }

    // 1. Instant local catalog matching using word-prefix rules, so "h" only suggests names
    // with a word starting with "h" and "apple mac b" -> "Apple MacBook Pro / Air".
    final localMatches = _popularProductCatalog
        .where((item) => _matchesSuggestionQuery(item, trimmed))
        .take(5)
        .toList();

    setState(() {
      _autocompleteSuggestions = localMatches;
    });

    // 2. Debounced live e-commerce autocomplete from Amazon & Google Shopping
    _suggestDebounce = Timer(const Duration(milliseconds: 220), () async {
      final liveSuggestions = await _fetchLiveProductAutocomplete(trimmed);
      if (!mounted || _searchController.text.trim() != trimmed) return;

      final merged = <String>[...localMatches];
      for (final s in liveSuggestions) {
        // Skip unrelated live suggestions that don't match what the user typed.
        if (!_matchesSuggestionQuery(s, trimmed)) continue;
        if (!merged.any(
          (existing) => existing.toLowerCase() == s.toLowerCase(),
        )) {
          merged.add(s);
        }
        if (merged.length >= 7) break;
      }

      setState(() {
        _autocompleteSuggestions = merged;
      });
    });
  }

  // Returns true when [candidate] starts with the typed query (ignoring spaces/case) or every typed
  // word is the beginning of some word in [candidate] (e.g. "apple mac b" matches "Apple MacBook Pro").
  bool _matchesSuggestionQuery(String candidate, String query) {
    final lowerCandidate = candidate.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return false;
    if (lowerCandidate.replaceAll(' ', '').startsWith(
      lowerQuery.replaceAll(' ', ''),
    )) {
      return true;
    }
    final candidateWords = lowerCandidate
        .split(RegExp(r'[^a-z0-9\u3040-\u30ff\u4e00-\u9fff]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final queryWords = lowerQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return queryWords.every(
      (q) => candidateWords.any((w) => w.startsWith(q)),
    );
  }

  // Queries Amazon's real-time product completion API and Google's suggestion API
  // to return full product names while the user types.
  Future<List<String>> _fetchLiveProductAutocomplete(String query) async {
    final List<String> suggestions = [];
    final encoded = Uri.encodeComponent(query);

    await Future.wait([
      () async {
        try {
          final url = Uri.parse(
            'https://completion.amazon.co.jp/api/2017/suggestions?mid=A1VC38T7YXB528&alias=aps&prefix=$encoded',
          );
          final resp = await http
              .get(url)
              .timeout(const Duration(milliseconds: 1800));
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final list = data['suggestions'] as List?;
            if (list != null) {
              for (final item in list.whereType<Map>()) {
                final val = item['value']?.toString().trim();
                if (val != null &&
                    val.isNotEmpty &&
                    !suggestions.contains(val)) {
                  suggestions.add(val);
                  if (suggestions.length >= 6) break;
                }
              }
            }
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final url = Uri.parse(
            'https://suggestqueries.google.com/complete/search?client=firefox&ds=sh&q=$encoded',
          );
          final resp = await http
              .get(url)
              .timeout(const Duration(milliseconds: 1800));
          if (resp.statusCode == 200) {
            final decoded = jsonDecode(resp.body);
            if (decoded is List && decoded.length > 1 && decoded[1] is List) {
              for (final s in decoded[1]) {
                final val = s?.toString().trim();
                if (val != null &&
                    val.isNotEmpty &&
                    !suggestions.contains(val)) {
                  suggestions.add(val);
                  if (suggestions.length >= 7) break;
                }
              }
            }
          }
        } catch (_) {}
      }(),
    ]);

    return suggestions;
  }

  // Calls Gemini via Firebase AI to search for the user's desired item across
  // Amazon, Rakuten Ichiba, Yahoo! Shopping, and Mercari, and fetches real product images
  // directly from the stores and Wikimedia/Bing product image catalogs.
  Future<void> _searchProductsWithAi() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    _suggestDebounce?.cancel();
    setState(() {
      _isSearchingProducts = true;
      _autocompleteSuggestions = [];
      _searchResults = [];
      _selectedProduct = null;
      _aiAnalysis = null;
    });

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final currencyCode = settings.selectedCurrency;
    final liveFuture = _searchLiveStores(query);

    try {
      String? dbgToken;
      try {
        dbgToken = await FirebaseAppCheck.instance.getToken(false);
      } catch (_) {}

      final googleAI = FirebaseAI.googleAI(
        useLimitedUseAppCheckTokens: false,
      );

      final prompt = TextPart(
        'The user wants to save money to buy "$query". '
        'Return realistic product listings from major shopping sites: '
        '"Amazon", "Rakuten Ichiba", "Yahoo! Shopping", and "Mercari" in currency $currencyCode. '
        'Return ONLY valid JSON in this exact format: '
        '{"products":['
        '{"title":"exact product brand and model name","siteName":"Amazon","price":12000,'
        '"badge":"Prime / Official","searchQuery":"exact brand model name product photo"},'
        '{"title":"exact product brand and model name","siteName":"Rakuten Ichiba","price":11800,'
        '"badge":"Points 5x","searchQuery":"exact brand model name official"},'
        '{"title":"exact product brand and model name","siteName":"Yahoo! Shopping","price":11500,'
        '"badge":"PayPay Bonus","searchQuery":"exact brand model name"},'
        '{"title":"exact product brand and model name (Used / Like New)","siteName":"Mercari","price":8900,'
        '"badge":"Good Condition","searchQuery":"exact brand model name"}'
        ']}',
      );

      final storeImagesFuture = _fetchRealStoreProductImages(query);

      const candidateModels = ['gemini-flash-latest'];
      GenerateContentResponse? response;
      for (final modelName in candidateModels) {
        try {
          final model = googleAI.generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
            httpClient: _SavingAiHttpClient(overrideAppCheckToken: dbgToken),
          );
          response = await model.generateContent([Content.multi([prompt])]);
          break;
        } catch (e) {
          debugPrint('Product search with $modelName failed: $e');
        }
      }

      final storeImages = await storeImagesFuture;

      List<AiProductOffer> offers = [];
      if (response != null && response.text != null) {
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final decoded = jsonDecode(cleanJson);
        final List? rawList = decoded is Map
            ? decoded['products'] as List?
            : (decoded is List ? decoded : null);

        if (rawList != null) {
          int i = 0;
          for (final item in rawList.whereType<Map>()) {
            final site = item['siteName']?.toString() ?? 'Amazon';
            final title = item['title']?.toString() ?? query;
            final price =
                double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
            final rawBadge = item['badge']?.toString() ?? 'Popular';
            final badge = rawBadge.toLowerCase().contains('estimate')
                ? rawBadge
                : 'AI estimate • $rawBadge';
            final searchKeyword =
                item['searchQuery']?.toString().trim().isNotEmpty == true
                ? item['searchQuery'].toString().trim()
                : title;

            final resolvedImg = _pickBestStoreImage(
              site: site,
              query: query,
              specificTitle: searchKeyword,
              index: i,
              storeImages: storeImages,
            );

            offers.add(
              AiProductOffer(
                title: title,
                siteName: site,
                price: price > 0
                    ? price
                    : _defaultPriceForCurrency(currencyCode),
                imageUrl: resolvedImg,
                siteUrl: _buildStoreSearchUrl(site, query),
                badge: badge,
                isEstimate: true,
              ),
            );
            i++;
          }
        }
      }

      if (offers.isEmpty) {
        offers = _buildFallbackProductOffers(query, currencyCode, storeImages);
      }

      final (liveOffers, liveErrors) = await liveFuture;
      final merged = _mergeLiveAndEstimates(liveOffers, offers);

      if (!mounted) return;
      setState(() {
        _searchResults = merged;
      });
      if (liveErrors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(liveErrors.first)),
        );
      }
    } catch (e) {
      debugPrint('AI product search error: $e');
      final storeImages = await _fetchRealStoreProductImages(query);
      final (liveOffers, _) = await liveFuture;
      final fallback = _buildFallbackProductOffers(
        query,
        currencyCode,
        storeImages,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = _mergeLiveAndEstimates(liveOffers, fallback);
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingProducts = false);
      }
    }
  }

  // Fetches lightweight product image thumbnails via JSON API without scraping multi-megabyte store HTML
  // on the main UI isolate (preventing UI thread freezes / ANRs on Android).
  Future<Map<String, List<String>>> _fetchRealStoreProductImages(
    String query,
  ) async {
    final Map<String, List<String>> result = {
      'amazon': <String>[],
      'rakuten': <String>[],
      'yahoo': <String>[],
      'general': <String>[],
    };

    try {
      // Uses Wikipedia's article lead image for the searched product (accurate for known products),
      // and only accepts a result whose title shares a word with the query so we never show random pictures.
      final wikiUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&generator=search'
        '&gsrsearch=${Uri.encodeComponent(query)}&gsrlimit=6'
        '&prop=pageimages&piprop=thumbnail&pithumbsize=400&format=json',
      );
      final resp = await http
          .get(
            wikiUrl,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) EasyBudget/1.0 Mobile',
            },
          )
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final pages = data['query']?['pages'] as Map?;
        if (pages != null) {
          final queryWords = query
              .toLowerCase()
              .split(RegExp(r'[^a-z0-9]+'))
              .where((w) => w.length > 1)
              .toList();
          final sorted = pages.values.whereType<Map>().toList()
            ..sort(
              (a, b) => ((a['index'] ?? 99) as num).compareTo(
                (b['index'] ?? 99) as num,
              ),
            );
          for (final page in sorted) {
            final title = (page['title']?.toString() ?? '').toLowerCase();
            final thumb = page['thumbnail']?['source']?.toString();
            final related = queryWords.isEmpty ||
                queryWords.any((w) => title.contains(w));
            if (thumb != null && thumb.isNotEmpty && related) {
              result['general']!.add(thumb);
              break;
            }
          }
        }
      }
    } catch (_) {}

    return result;
  }

  // Selects the matching real store product image for a given marketplace offer,
  // falling back to a real live product image search thumbnail if direct store scraping was blocked.
  String _pickBestStoreImage({
    required String site,
    required String query,
    required String specificTitle,
    required int index,
    required Map<String, List<String>> storeImages,
  }) {
    final lower = site.toLowerCase();
    if (lower.contains('amazon') && storeImages['amazon']!.isNotEmpty) {
      return storeImages['amazon']![index % storeImages['amazon']!.length];
    }
    if (lower.contains('rakuten') && storeImages['rakuten']!.isNotEmpty) {
      return storeImages['rakuten']![index % storeImages['rakuten']!.length];
    }
    if (lower.contains('yahoo') && storeImages['yahoo']!.isNotEmpty) {
      return storeImages['yahoo']![index % storeImages['yahoo']!.length];
    }

    final allStoreUrls = <String>[
      ...storeImages['rakuten']!,
      ...storeImages['yahoo']!,
      ...storeImages['amazon']!,
      ...storeImages['general']!,
    ];
    // Always use the same verified product picture for every store offer of the same item.
    if (allStoreUrls.isNotEmpty) {
      return allStoreUrls.first;
    }

    // No verified picture found: return empty so the UI shows a neutral icon instead of a random photo.
    return '';
  }

  // Returns a realistic fallback base price in the user's selected currency if offline.
  double _defaultPriceForCurrency(String currency) {
    switch (currency) {
      case 'JPY':
        return 15000;
      case 'KRW':
        return 150000;
      case 'MMK':
        return 350000;
      default:
        return 120;
    }
  }

  // Generates fallback offers across Amazon, Rakuten Ichiba, Yahoo! Shopping, and Mercari
  // using real product images if the AI call fails or times out.
  List<AiProductOffer> _buildFallbackProductOffers(
    String query,
    String currency,
    Map<String, List<String>> storeImages,
  ) {
    final base = _defaultPriceForCurrency(currency);
    return [
      AiProductOffer(
        title: query,
        siteName: 'Amazon',
        price: base,
        imageUrl: _pickBestStoreImage(
          site: 'Amazon',
          query: query,
          specificTitle: query,
          index: 0,
          storeImages: storeImages,
        ),
        siteUrl: _buildStoreSearchUrl('Amazon', query),
        badge: 'AI estimate • Fast Delivery',
        isEstimate: true,
      ),
      AiProductOffer(
        title: query,
        siteName: 'Rakuten Ichiba',
        price: (base * 0.97).roundToDouble(),
        imageUrl: _pickBestStoreImage(
          site: 'Rakuten Ichiba',
          query: query,
          specificTitle: query,
          index: 1,
          storeImages: storeImages,
        ),
        siteUrl: _buildStoreSearchUrl('Rakuten Ichiba', query),
        badge: 'AI estimate • Rakuten Points',
        isEstimate: true,
      ),
      AiProductOffer(
        title: query,
        siteName: 'Yahoo! Shopping',
        price: (base * 0.95).roundToDouble(),
        imageUrl: _pickBestStoreImage(
          site: 'Yahoo! Shopping',
          query: query,
          specificTitle: query,
          index: 2,
          storeImages: storeImages,
        ),
        siteUrl: _buildStoreSearchUrl('Yahoo! Shopping', query),
        badge: 'AI estimate • PayPay Bonus',
        isEstimate: true,
      ),
      AiProductOffer(
        title: '$query (Pre-owned)',
        siteName: 'Mercari',
        price: (base * 0.75).roundToDouble(),
        imageUrl: _pickBestStoreImage(
          site: 'Mercari',
          query: query,
          specificTitle: query,
          index: 3,
          storeImages: storeImages,
        ),
        siteUrl: _buildStoreSearchUrl('Mercari', query),
        badge: 'AI estimate • Best Value',
        isEstimate: true,
      ),
    ];
  }

  // Builds the store search URL for Amazon, Rakuten Ichiba, Yahoo! Shopping, or Mercari.
  String _buildStoreSearchUrl(String siteName, String query) {
    final encoded = Uri.encodeComponent(query);
    final lower = siteName.toLowerCase();
    if (lower.contains('amazon')) {
      return 'https://www.amazon.co.jp/s?k=$encoded';
    } else if (lower.contains('rakuten')) {
      return 'https://search.rakuten.co.jp/search/mall/$encoded/';
    } else if (lower.contains('yahoo')) {
      return 'https://shopping.yahoo.co.jp/search?p=$encoded';
    } else if (lower.contains('mercari') || lower.contains('merukari')) {
      return 'https://jp.mercari.com/search?keyword=$encoded';
    }
    return 'https://www.google.com/search?tbm=shop&q=$encoded';
  }

  // Selects a product from the AI search results and triggers the AI transaction analysis
  // to ask the user whether to save "Usually" or "Cut Unnecessary Expenses".
  Future<void> _onSelectProductOffer(AiProductOffer offer) async {
    setState(() {
      _selectedProduct = offer;
      _aiAnalysis = null;
    });

    await _analyzeTransactionsAndAskPlan(offer);
  }

  // Remade Manual Saving Goal builder (modeled on the AI Saving System):
  // Takes the user's manual item name, target price, and optional store/source,
  // fetches a real product photo for that item, constructs an AiProductOffer,
  // and runs the exact same AI Transaction Analysis ("Save Usually" vs "Cut Unnecessary Expenses").
  Future<void> _analyzeManualGoalWithAi() async {
    final name = _manualNameController.text.trim();
    final price =
        double.tryParse(_manualPriceController.text.replaceAll(',', '')) ?? 0.0;
    final store = _manualStoreController.text.trim().isNotEmpty
        ? _manualStoreController.text.trim()
        : 'Manual Goal';

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.enterValidNameAndGoalAmount,
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isAnalyzingTransactions = true;
      _aiAnalysis = null;
    });

    // Fetch a real product photo for the manually entered item name
    final storeImages = await _fetchRealStoreProductImages(name);
    final resolvedImg = _pickBestStoreImage(
      site: store,
      query: name,
      specificTitle: name,
      index: 0,
      storeImages: storeImages,
    );

    final manualOffer = AiProductOffer(
      title: name,
      siteName: store,
      price: price,
      imageUrl: resolvedImg,
      siteUrl: _buildStoreSearchUrl(store, name),
      badge: _manualNoteController.text.trim().isNotEmpty
          ? _manualNoteController.text.trim()
          : 'Custom Saving Goal',
      isEstimate: false,
    );

    if (!mounted) return;
    setState(() {
      _selectedProduct = manualOffer;
    });

    await _analyzeTransactionsAndAskPlan(manualOffer);
  }

  // Analyzes all previous transactions from TransactionProvider using Gemini AI
  // to calculate both the "Usual" saving plan and the "Cut Unnecessary Expenses" plan,
  // then shows a dialog asking the user which plan they want to use.
  Future<void> _analyzeTransactionsAndAskPlan(AiProductOffer offer) async {
    setState(() {
      _isAnalyzingTransactions = true;
    });

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;
    final allTx = txProvider.transactions;

    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final mainBalance = txProvider.totalBalance;

    final Map<String, double> expenseByCategory = {};
    for (final t in allTx.where((t) => t.type == TransactionType.expense)) {
      expenseByCategory[t.category] =
          (expenseByCategory[t.category] ?? 0.0) + t.amount;
    }

    int spanDays = 30;
    if (allTx.length >= 2) {
      final earliest = allTx
          .map((t) => t.dateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final diff = DateTime.now().difference(earliest).inDays;
      if (diff > 7) {
        spanDays = diff;
      }
    }

    final double minRemaining = (offer.price * 0.1).clamp(0.0, double.infinity);
    final double maxRemaining =
        (offer.price + mainBalance.abs()).clamp(minRemaining, double.infinity);
    final double remainingNeeded = (offer.price - mainBalance).clamp(
      minRemaining,
      maxRemaining,
    );

    final double avgDailyIncome = totalIncome > 0
        ? totalIncome / spanDays
        : (offer.price / 45.0);
    final double avgDailyExpense = totalExpense > 0
        ? totalExpense / spanDays
        : (avgDailyIncome * 0.7);
    final double netDailyFlow = avgDailyIncome - avgDailyExpense;

    final double maxDailyCap = offer.price > 1.0 ? offer.price : 1.0;
    final double fallbackUsualDaily = netDailyFlow > 0
        ? netDailyFlow.clamp(1.0, maxDailyCap)
        : (avgDailyIncome > 0 ? avgDailyIncome * 0.15 : offer.price / 60.0)
              .clamp(1.0, maxDailyCap);
    final double minCutDaily = fallbackUsualDaily * 1.25;
    final double maxCutDaily =
        offer.price >= minCutDaily ? offer.price : minCutDaily;
    final double fallbackCutDaily = (fallbackUsualDaily +
            (avgDailyExpense > 0
                ? avgDailyExpense * 0.35
                : fallbackUsualDaily * 0.5))
        .clamp(minCutDaily, maxCutDaily);

    final int fallbackUsualDays = (remainingNeeded / fallbackUsualDaily)
        .ceil()
        .clamp(1, 3650);
    final int maxCutDays = fallbackUsualDays > 1 ? fallbackUsualDays - 1 : 1;
    final int fallbackCutDays = (remainingNeeded / fallbackCutDaily)
        .ceil()
        .clamp(1, maxCutDays);

    AiSavingAnalysis? analysis;

    try {
      String? dbgToken;
      try {
        dbgToken = await FirebaseAppCheck.instance.getToken(false);
      } catch (_) {}

      final googleAI = FirebaseAI.googleAI(
        useLimitedUseAppCheckTokens: false,
      );

      final catSummary = expenseByCategory.entries
          .map((e) => '${e.key}: $symbol${settings.formatAmount(e.value)}')
          .join(', ');

      final targetLang = settings.selectedLanguage == 'Japanese'
          ? 'Japanese'
          : (settings.selectedLanguage == 'Myanmar' ||
                    settings.selectedLanguage == 'Burmese'
                ? 'Burmese (Myanmar Unicode)'
                : 'English');

      final prompt = TextPart(
        'Analyze this user\'s transaction history to create 2 saving plans for buying '
        '"${offer.title}" (${offer.siteName}) costing $symbol${settings.formatAmount(offer.price)}.\n'
        'User Financial Data:\n'
        '- Current Main Balance: $symbol${settings.formatAmount(mainBalance)}\n'
        '- Remaining Amount Needed (adjusted for main balance): $symbol${settings.formatAmount(remainingNeeded)}\n'
        '- Total Historical Income: $symbol${settings.formatAmount(totalIncome)} over $spanDays days\n'
        '- Total Historical Expense: $symbol${settings.formatAmount(totalExpense)} over $spanDays days\n'
        '- Expense Breakdown by Category: ${catSummary.isEmpty ? "No expenses recorded yet" : catSummary}\n\n'
        'Return ONLY valid JSON with two plans (write usualSummary, cutSummary, and cutTips in natural $targetLang):\n'
        '1. "usual": Saving naturally with little to no cutting of unnecessary expenses.\n'
        '2. "cut": Aggressively cutting unnecessary/discretionary expenses (e.g. Food/snacks, Shopping, Entertainment) to save faster.\n'
        'Exact JSON format:\n'
        '{"usualDays":$fallbackUsualDays,"usualDailySaving":${fallbackUsualDaily.toStringAsFixed(2)},'
        '"usualSummary":"Short explanation of usual pace in $targetLang",'
        '"cutDays":$fallbackCutDays,"cutDailySaving":${fallbackCutDaily.toStringAsFixed(2)},'
        '"cutSummary":"Short explanation of how much faster they can buy it by cutting expenses in $targetLang",'
        '"cutTips":["Specific tip 1 in $targetLang","Specific tip 2 in $targetLang"]}',
      );

      const candidateModels = ['gemini-flash-latest'];
      GenerateContentResponse? response;
      for (final modelName in candidateModels) {
        try {
          final model = googleAI.generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
            httpClient: _SavingAiHttpClient(overrideAppCheckToken: dbgToken),
          );
          response = await model.generateContent([Content.multi([prompt])]);
          break;
        } catch (e) {
          debugPrint('Saving plan AI analysis failed on $modelName: $e');
        }
      }

      if (response != null && response.text != null) {
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final decoded = jsonDecode(cleanJson);
        if (decoded is Map) {
          final uDaily =
              double.tryParse(decoded['usualDailySaving']?.toString() ?? '') ??
              fallbackUsualDaily;
          final cDaily =
              double.tryParse(decoded['cutDailySaving']?.toString() ?? '') ??
              fallbackCutDaily;
          final validUDaily = (uDaily.isFinite && uDaily > 0)
              ? uDaily
              : fallbackUsualDaily;
          final validCDaily = (cDaily.isFinite && cDaily > validUDaily)
              ? cDaily
              : fallbackCutDaily;
          final rawUDays = remainingNeeded / validUDaily;
          final uDays = rawUDays.isFinite
              ? rawUDays.ceil().clamp(1, 3650)
              : fallbackUsualDays;
          final rawCDays = remainingNeeded / validCDaily;
          final cDays = rawCDays.isFinite
              ? rawCDays.ceil().clamp(1, uDays)
              : fallbackCutDays;
          final tips = (decoded['cutTips'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

          analysis = AiSavingAnalysis(
            usualDays: uDays,
            usualDailySaving: validUDaily,
            usualSummary:
                decoded['usualSummary']?.toString() ??
                'Save steadily at $symbol${settings.formatAmount(validUDaily)}/day with little to no lifestyle changes.',
            cutDays: cDays,
            cutDailySaving: validCDaily,
            cutSummary:
                decoded['cutSummary']?.toString() ??
                'Cut unnecessary expenses to save $symbol${settings.formatAmount(validCDaily)}/day and reach your goal in $cDays days!',
            cutTips: tips,
          );
        }
      }
    } catch (e) {
      debugPrint('AI Saving Plan analysis fallback triggered: $e');
    }

    analysis ??= AiSavingAnalysis(
      usualDays: fallbackUsualDays,
      usualDailySaving: fallbackUsualDaily,
      usualSummary:
          'Save steadily at $symbol${settings.formatAmount(fallbackUsualDaily)}/day with little to no cutting of unnecessary expenses.',
      cutDays: fallbackCutDays,
      cutDailySaving: fallbackCutDaily,
      cutSummary:
          'Cut unnecessary discretionary expenses by ~35% to save $symbol${settings.formatAmount(fallbackCutDaily)}/day and buy it in $fallbackCutDays days!',
      cutTips: [
        'Reduce non-essential Shopping and dining-out expenses by 30–40%.',
        'Set aside daily savings first before discretionary spending.',
      ],
    );

    if (!mounted) return;
    setState(() {
      _isAnalyzingTransactions = false;
      _aiAnalysis = analysis;
    });

    await _showPlanChoiceModal(offer, analysis);
  }

  // Displays the AI prompt asking the user:
  // "Will you make the saving plan usually or cut the unnecessary expenses?"
  // and applies the chosen plan's daily saving rate and target date.
  Future<void> _showPlanChoiceModal(
    AiProductOffer offer,
    AiSavingAnalysis analysis,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          ctx,
                          'AI Saving Plan Advisor',
                          'AI貯金プランアドバイザー',
                          'AI စုငွေအစီအစဉ် အကြံပေး',
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tr(
                    ctx,
                    'Will you make the saving plan usually or cut the unnecessary expenses?',
                    '通常通り貯金しますか、それとも不要な支出を削減して早く達成しますか？',
                    'ပုံမှန်အတိုင်း စုဆောင်းမည်လား သို့မဟုတ် မလိုအပ်သော အသုံးစရိတ်များကို လျှော့ချ၍ စုဆောင်းမည်လား?',
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Usual Plan
                _buildPlanOptionCard(
                  ctx: ctx,
                  title: tr(
                    ctx,
                    '1. Save Usually (Little to No Cutting)',
                    '1. 通常プラン（無理なく貯金）',
                    '၁။ ပုံမှန်အတိုင်း စုဆောင်းမည် (အသုံးစရိတ် မလျှော့ဘဲ)',
                  ),
                  days: analysis.usualDays,
                  dailyAmount: tr(
                    ctx,
                    '$symbol${settings.formatAmount(analysis.usualDailySaving)} / day',
                    '$symbol${settings.formatAmount(analysis.usualDailySaving)} / 日',
                    'တစ်ရက်လျှင် $symbol${settings.formatAmount(analysis.usualDailySaving)}',
                  ),
                  description: analysis.usualSummary,
                  accentColor: const Color(0xFF3B82F6),
                  icon: Icons.schedule_rounded,
                  onTap: () => Navigator.pop(ctx, 'usual'),
                ),
                const SizedBox(height: 12),

                // Option 2: Cut Unnecessary Expenses Plan
                _buildPlanOptionCard(
                  ctx: ctx,
                  title: tr(
                    ctx,
                    '2. Cut Unnecessary Expenses (Fastest)',
                    '2. 節約プラン（不要な支出をカットして最速達成）',
                    '၂။ မလိုအပ်သော အသုံးစရိတ်များ လျှော့ချမည် (အမြန်ဆုံး)',
                  ),
                  days: analysis.cutDays,
                  dailyAmount: tr(
                    ctx,
                    '$symbol${settings.formatAmount(analysis.cutDailySaving)} / day',
                    '$symbol${settings.formatAmount(analysis.cutDailySaving)} / 日',
                    'တစ်ရက်လျှင် $symbol${settings.formatAmount(analysis.cutDailySaving)}',
                  ),
                  description: analysis.cutSummary,
                  tips: analysis.cutTips,
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.content_cut_rounded,
                  onTap: () => Navigator.pop(ctx, 'cut_expenses'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedPlanMode = chosen;
      });
    }
  }

  // Builds a selectable card inside the AI Saving Plan Advisor bottom sheet.
  Widget _buildPlanOptionCard({
    required BuildContext ctx,
    required String title,
    required int days,
    required String dailyAmount,
    required String description,
    List<String> tips = const [],
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: accentColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(ctx)!.streakDaysCount(days),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                ctx,
                'Target Pace: $dailyAmount',
                '目標ペース: $dailyAmount',
                'ရည်မှန်းချက် နှုန်းထား: $dailyAmount',
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            AutoLocalizedText(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...tips.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AutoLocalizedText(
                          t,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Saves the AI-analyzed saving goal (from either AI Store Search or Manual Custom Item)
  // directly into TransactionProvider and returns to the previous screen.
  Future<void> _handleSaveAiGoal() async {
    // If user is in Manual Mode and hasn't run the AI analysis yet, run it first so they choose Usual vs Cut Expenses
    if (_isManualMode && (_selectedProduct == null || _aiAnalysis == null)) {
      await _analyzeManualGoalWithAi();
      if (_selectedProduct == null || _aiAnalysis == null || !mounted) return;
    }

    final offer = _selectedProduct;
    final analysis = _aiAnalysis;
    if (offer == null || analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.enterValidNameAndGoalAmount,
          ),
        ),
      );
      return;
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final symbol = settings.currencySymbol;

    final isCut = _selectedPlanMode == 'cut_expenses';
    final int days = isCut ? analysis.cutDays : analysis.usualDays;
    final double daily = isCut
        ? analysis.cutDailySaving
        : analysis.usualDailySaving;
    final String summary = isCut ? analysis.cutSummary : analysis.usualSummary;
    final String customNote = _isManualMode
        ? _manualNoteController.text.trim()
        : '';

    final noteText = [
      '${offer.siteName} • ${isCut ? "Cut Unnecessary Expenses Plan" : "Usual Saving Plan"} '
          '($symbol${settings.formatAmount(daily)}/day, ~$days days).',
      summary,
      if (customNote.isNotEmpty) 'Note: $customNote',
    ].join(' ');

    final goal = SavingsGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: offer.title,
      note: noteText,
      amount: offer.price,
      isFixed: true,
      targetDate: DateTime.now().add(Duration(days: days)),
      period: null,
      category: 'Saving',
      createdAt: DateTime.now(),
      productSite: offer.siteName,
      productImageUrl: offer.imageUrl,
      productSiteUrl: offer.siteUrl,
      planMode: _selectedPlanMode,
      plannedDailySaving: daily,
      initialSavedBalance: txProvider.totalBalance,
      aiPlanSummary: summary,
    );

    txProvider.addSavingsGoal(goal);
    Navigator.pop(context);
  }

  // Returns the brand color associated with each shopping marketplace badge.
  Color _getSiteBadgeColor(String site) {
    final lower = site.toLowerCase();
    if (lower.contains('amazon')) return const Color(0xFFFF9900);
    if (lower.contains('rakuten')) return const Color(0xFFBF0000);
    if (lower.contains('yahoo')) return const Color(0xFFFF0033);
    if (lower.contains('mercari')) return const Color(0xFF4DC9FF);
    return const Color(0xFF10B981);
  }

  // Builds the AI-powered Saving Page with two unified modes:
  // 1. "AI Store Search" (search Amazon, Rakuten Ichiba, Yahoo! Shopping, Mercari with auto-fill)
  // 2. "Manual Custom Item" (remade manual entry that generates a visual card and uses the same AI Saving Plan Advisor).
  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF10B981); // Emerald Green for savings
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newSavingGoal),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MODE SWITCHER: AI Store Search vs Manual Custom Item (both powered by AI Saving Planner)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isManualMode = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isManualMode
                              ? headerColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              size: 18,
                              color: !_isManualMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr(
                                context,
                                'AI Store Search',
                                'AIストア検索',
                                'AI စတိုးဆိုင် ရှာဖွေမှု',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_isManualMode
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isManualMode = true;
                          _autocompleteSuggestions = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isManualMode
                              ? headerColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 18,
                              color: _isManualMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr(
                                context,
                                'Manual Custom Item',
                                '手動でアイテム登録',
                                'စိတ်ကြိုက်ပစ္စည်း ကိုယ်တိုင်ထည့်ရန်',
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _isManualMode
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TAB 1: AI STORE SEARCH BAR & MARKETPLACE CARDS
            if (!_isManualMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      headerColor.withValues(alpha: 0.12),
                      const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: headerColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: headerColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              context,
                              'AI Product Finder & Saving Planner',
                              'AI商品検索＆貯金プランナー',
                              'AI ပစ္စည်းရှာဖွေရေးနှင့် စုငွေအစီအစဉ်ရေးဆွဲသူ',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        'Search any item from Amazon, Rakuten Ichiba, Yahoo! Shopping, or Mercari to build a personalized AI saving plan.',
                        'Amazon、楽天市場、Yahoo!ショッピング、メルカリから商品を検索し、AIが最適な貯金プランを作成します。',
                        'Amazon၊ Rakuten Ichiba၊ Yahoo! Shopping သို့မဟုတ် Mercari မှ မည်သည့်ပစ္စည်းကိုမဆို ရှာဖွေပြီး သင့်အတွက် သီးသန့် AI စုငွေအစီအစဉ်ကို ရေးဆွဲပါ။',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _showConnectStoresSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _credentials.hasAny
                                ? headerColor.withValues(alpha: 0.6)
                                : Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _credentials.hasAny
                                  ? Icons.verified_rounded
                                  : Icons.link_rounded,
                              size: 16,
                              color: _credentials.hasAny
                                  ? headerColor
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _credentials.hasAny
                                    ? tr(
                                        context,
                                        'Connected: ${[if (_credentials.hasRakuten) "Rakuten", if (_credentials.hasYahoo) "Yahoo!"].join(" & ")} (Live price search active)',
                                        '連携済み: ${[if (_credentials.hasRakuten) "楽天市場", if (_credentials.hasYahoo) "Yahoo!"].join(" & ")}（リアルタイム価格検索）',
                                        'ချိတ်ဆက်ပြီး: ${[if (_credentials.hasRakuten) "Rakuten", if (_credentials.hasYahoo) "Yahoo!"].join(" & ")} (တိုက်ရိုက်ဈေးနှုန်း ရှာဖွေမှု)',
                                      )
                                    : tr(
                                        context,
                                        'Results are AI estimates • Tap to connect Rakuten / Yahoo! account',
                                        'AI推定価格を表示中 • タップして楽天 / Yahoo!アカウントを連携',
                                        'AI ခန့်မှန်းဈေးနှုန်းများ • Rakuten / Yahoo! ချိတ်ဆက်ရန် နှိပ်ပါ',
                                      ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _credentials.hasAny
                                      ? headerColor
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchQueryChanged,
                            onSubmitted: (_) => _searchProductsWithAi(),
                            decoration: InputDecoration(
                              hintText: tr(
                                context,
                                'Search item (e.g. Apple MacBook, PS5)...',
                                '商品を検索（例: Apple MacBook, PS5）...',
                                'ပစ္စည်းရှာရန် (ဥပမာ - Apple MacBook, PS5)...',
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchQueryChanged('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSearchingProducts
                              ? null
                              : _searchProductsWithAi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSearchingProducts
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  tr(context, 'Search', '検索', 'ရှာမည်'),
                                ),
                        ),
                      ],
                    ),

                    // AUTO-FILL SUGGESTION DROPDOWN LIST
                    if (_autocompleteSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: headerColor.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _autocompleteSuggestions.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _autocompleteSuggestions[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: headerColor,
                              ),
                              title: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(
                                Icons.north_west_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () {
                                _searchController.text = suggestion;
                                _searchController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: suggestion.length),
                                    );
                                setState(() => _autocompleteSuggestions = []);
                                _searchProductsWithAi();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // PRODUCT SEARCH RESULTS (Visual Picture + Site + Price)
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  tr(
                    context,
                    'Select Product & Store to Save For:',
                    '貯金する商品とストアを選択:',
                    'စုဆောင်းလိုသော ပစ္စည်းနှင့် ဆိုင်ကို ရွေးချယ်ပါ:',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 242,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final offer = _searchResults[index];
                      final isSelected = _selectedProduct == offer;
                      final siteColor = _getSiteBadgeColor(offer.siteName);

                      return GestureDetector(
                        onTap: () => _onSelectProductOffer(offer),
                        child: Container(
                          width: 175,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? headerColor
                                  : Colors.grey.withValues(alpha: 0.25),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: SafeProductImage(
                                      imageUrl: offer.imageUrl,
                                      height: 105,
                                      width: double.infinity,
                                      cacheWidth: 240,
                                      fit: BoxFit.cover,
                                      fallback: Container(
                                        height: 105,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 36,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: siteColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        offer.siteName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: offer.isEstimate
                                            ? Colors.amber.shade800.withValues(
                                                alpha: 0.92,
                                              )
                                            : headerColor.withValues(
                                                alpha: 0.92,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        offer.isEstimate
                                            ? tr(
                                                context,
                                                'AI estimate',
                                                'AI推定',
                                                'AI ခန့်မှန်းချက်',
                                              )
                                            : tr(
                                                context,
                                                'Live price',
                                                '実価格',
                                                'တိုက်ရိုက်ဈေး',
                                              ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: headerColor,
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoLocalizedText(
                                      offer.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AutoLocalizedText(
                                      offer.badge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${settings.currencySymbol}${settings.formatAmount(offer.price)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: headerColor,
                                            ),
                                          ),
                                        ),
                                        if (offer.isEstimate) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '(est.)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              // TAB 2: REMADE MANUAL CUSTOM SAVING GOAL (Powered by the AI Saving System)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: headerColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: headerColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              context,
                              'Manual Custom Item + AI Saving Plan',
                              '手動アイテム登録＋AI貯金プラン',
                              'စိတ်ကြိုက်ပစ္စည်း + AI စုငွေအစီအစဉ်',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        'Enter any custom item and price manually. AI will fetch its visual photo, analyze your transactions, and build your saving plan.',
                        '欲しい商品と価格を手動で入力してください。AIが商品画像を取得し、取引履歴を分析して貯金プランを作成します。',
                        'မည်သည့်ပစ္စည်းနှင့် ဈေးနှုန်းကိုမဆို ကိုယ်တိုင်ထည့်သွင်းပါ။ AI မှ ပစ္စည်းပုံရှာပေးပြီး သင်၏ ငွေစာရင်းများကို သုံးသပ်၍ စုငွေအစီအစဉ် ရေးဆွဲပေးပါမည်။',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item Name
                    TextField(
                      controller: _manualNameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.goalName,
                        hintText: tr(
                          context,
                          'e.g. Custom Gaming PC, Trip to Kyoto, Guitar',
                          '例: ゲーミングPC、京都旅行、ギター',
                          'ဥပမာ - Gaming PC, ခရီးစဉ်, ဂစ်တာ',
                        ),
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Price
                    TextField(
                      controller: _manualPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.targetAmount,
                        prefixText: '${settings.currencySymbol} ',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Store / Brand / Source (Optional)
                    TextField(
                      controller: _manualStoreController,
                      decoration: InputDecoration(
                        labelText: tr(
                          context,
                          'Store or Source (Optional)',
                          '店舗・ブランド（任意）',
                          'ဆိုင် သို့မဟုတ် အရင်းအမြစ် (ထည့်လိုက ထည့်ရန်)',
                        ),
                        hintText: tr(
                          context,
                          'e.g. Apple Store, Amazon, Local Shop',
                          '例: Apple Store、Amazon、近所のお店',
                          'ဥပမာ - Apple Store, Amazon, ပြည်တွင်းဆိုင်',
                        ),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Note
                    TextField(
                      controller: _manualNoteController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.note,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Button to trigger AI Transaction Analysis ("Save Usually" vs "Cut Unnecessary Expenses")
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzingTransactions
                            ? null
                            : _analyzeManualGoalWithAi,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          tr(
                            context,
                            'Analyze My Transactions & Choose AI Saving Plan',
                            '取引履歴を分析してAI貯金プランを選択',
                            'ငွေစာရင်းများကို သုံးသပ်၍ AI စုငွေအစီအစဉ် ရွေးချယ်မည်',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: headerColor,
                          side: const BorderSide(
                            color: headerColor,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI TRANSACTION ANALYSIS LOADING OR SELECTED PLAN BANNER
            if (_isAnalyzingTransactions) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: headerColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'AI is analyzing your transaction history to calculate the best saving plan...',
                          'AIが取引履歴を分析し、最適な貯金プランを計算しています...',
                          'အကောင်းဆုံး စုငွေအစီအစဉ် တွက်ချက်ရန် AI မှ သင်၏ ငွေစာရင်းမှတ်တမ်းကို သုံးသပ်နေပါသည်...',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_aiAnalysis != null && _selectedProduct != null) ...[
              const SizedBox(height: 20),
              _buildSelectedPlanSummaryBanner(settings, headerColor),
            ],

            const SizedBox(height: 32),

            // SAVE GOAL BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzingTransactions ? null : _handleSaveAiGoal,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context)!.saveGoal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: headerColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Displays the active AI saving plan summary card (product photo, store, days left, daily saving rate,
  // and AI tips) with a button to switch between "Save Usually" and "Cut Unnecessary Expenses".
  Widget _buildSelectedPlanSummaryBanner(
    SettingsProvider settings,
    Color headerColor,
  ) {
    final analysis = _aiAnalysis!;
    final offer = _selectedProduct!;
    final isCut = _selectedPlanMode == 'cut_expenses';
    final days = isCut ? analysis.cutDays : analysis.usualDays;
    final daily = isCut ? analysis.cutDailySaving : analysis.usualDailySaving;
    final summary = isCut ? analysis.cutSummary : analysis.usualSummary;
    final symbol = settings.currencySymbol;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: headerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeProductImage(
                  imageUrl: offer.imageUrl,
                  width: 56,
                  height: 56,
                  cacheWidth: 160,
                  fit: BoxFit.cover,
                  fallback: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.shopping_bag, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoLocalizedText(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCut
                          ? tr(
                              context,
                              'Plan: Cut Unnecessary Expenses',
                              'プラン: 不要な支出をカット',
                              'အစီအစဉ်: မလိုအပ်သော အသုံးစရိတ်များ လျှော့ချမည်',
                            )
                          : tr(
                              context,
                              'Plan: Save Usually',
                              'プラン: 通常通り貯金',
                              'အစီအစဉ်: ပုံမှန်အတိုင်း စုဆောင်းမည်',
                            ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(
                        context,
                        '$days days • $symbol${settings.formatAmount(daily)}/day • Goal: $symbol${settings.formatAmount(offer.price)}${offer.isEstimate ? " (AI estimate)" : " (Live price)"}',
                        '$days日 • $symbol${settings.formatAmount(daily)}/日 • 目標: $symbol${settings.formatAmount(offer.price)}${offer.isEstimate ? " (AI推定)" : " (リアルタイム価格)"}',
                        '$days ရက် • တစ်ရက် $symbol${settings.formatAmount(daily)} • ရည်မှန်းချက်: $symbol${settings.formatAmount(offer.price)}${offer.isEstimate ? " (AI ခန့်မှန်းချက်)" : " (တိုက်ရိုက်ဈေးနှုန်း)"}',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showPlanChoiceModal(offer, analysis),
                child: Text(
                  tr(context, 'Change', '変更', 'ပြောင်းမည်'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutoLocalizedText(
            summary,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
