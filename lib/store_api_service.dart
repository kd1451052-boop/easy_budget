import 'dart:convert';
import 'package:http/http.dart' as http; // ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a live store listing returned directly by Rakuten Ichiba or Yahoo! Shopping APIs.
class StoreItem {
  final String title;
  final String siteName;
  final double price;
  final String imageUrl;
  final String siteUrl;
  final String badge;

  const StoreItem({
    required this.title,
    required this.siteName,
    required this.price,
    required this.imageUrl,
    required this.siteUrl,
    required this.badge,
  });
}

/// Result wrapper for a live store API query.
class StoreSearchResult {
  final List<StoreItem> items;
  final String? error;

  const StoreSearchResult({required this.items, this.error});
}

/// Persists the user's connected Rakuten Ichiba and Yahoo! Shopping credentials locally
/// so the app can run live price searches on its own.
class StoreCredentials {
  static const _kRakutenAppId = 'store_rakuten_app_id';
  static const _kRakutenAccessKey = 'store_rakuten_access_key';
  static const _kYahooClientId = 'store_yahoo_client_id';

  final String rakutenAppId;
  final String rakutenAccessKey;
  final String yahooClientId;

  const StoreCredentials({
    this.rakutenAppId = '',
    this.rakutenAccessKey = '',
    this.yahooClientId = '',
  });

  /// Rakuten Ichiba is considered connected when an Application ID is saved.
  bool get hasRakuten => rakutenAppId.trim().isNotEmpty;

  /// Yahoo! Shopping is considered connected when a Client ID (appid) is saved.
  bool get hasYahoo => yahooClientId.trim().isNotEmpty;

  bool get hasAny => hasRakuten || hasYahoo;

  static Future<StoreCredentials> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StoreCredentials(
      rakutenAppId: prefs.getString(_kRakutenAppId) ?? '',
      rakutenAccessKey: prefs.getString(_kRakutenAccessKey) ?? '',
      yahooClientId: prefs.getString(_kYahooClientId) ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRakutenAppId, rakutenAppId.trim());
    await prefs.setString(_kRakutenAccessKey, rakutenAccessKey.trim());
    await prefs.setString(_kYahooClientId, yahooClientId.trim());
  }
}

/// Official API client for Rakuten Ichiba Item Search API (20220601)
/// and Yahoo! Shopping Item Search API (V3).
class StoreApiService {
  /// Searches Rakuten Ichiba live product listings using the user's connected Rakuten credentials.
  static Future<StoreSearchResult> searchRakuten({
    required String query,
    required String appId,
    String accessKey = '',
    int hits = 3,
  }) async {
    final cleanAppId = appId.trim();
    final cleanAccessKey = accessKey.trim();
    if (cleanAppId.isEmpty) {
      return const StoreSearchResult(
        items: [],
        error: 'Rakuten Application ID is empty.',
      );
    }

    try {
      final bool useOpenApi = cleanAccessKey.isNotEmpty;
      final Uri uri = useOpenApi
          ? Uri.https(
              'openapi.rakuten.co.jp',
              '/ichibams/api/IchibaItem/Search/20220601',
              {
                'applicationId': cleanAppId,
                'accessKey': cleanAccessKey,
                'keyword': query,
                'hits': '$hits',
                'imageFlag': '1',
                'format': 'json',
                'formatVersion': '2',
              },
            )
          : Uri.https(
              'app.rakuten.co.jp',
              '/services/api/IchibaItem/Search/20220601',
              {
                'applicationId': cleanAppId,
                'keyword': query,
                'hits': '$hits',
                'imageFlag': '1',
                'format': 'json',
                'formatVersion': '2',
              },
            );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (useOpenApi) 'Authorization': 'Bearer $cleanAccessKey',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map) {
            detail =
                (errJson['error_description'] ??
                        errJson['errors']?['errorMessage'] ??
                        errJson['error'] ??
                        detail)
                    .toString();
          }
        } catch (_) {}
        return StoreSearchResult(
          items: const [],
          error: 'Rakuten API: $detail',
        );
      }

      final decoded = jsonDecode(response.body);
      final rawItems = (decoded is Map ? decoded['Items'] : null) as List?;
      if (rawItems == null || rawItems.isEmpty) {
        return const StoreSearchResult(items: []);
      }

      final List<StoreItem> results = [];
      for (final raw in rawItems) {
        final Map? item = raw is Map
            ? (raw['Item'] is Map ? raw['Item'] as Map : raw)
            : null;
        if (item == null) continue;

        final title = (item['itemName'] ?? query).toString().trim();
        final priceNum = item['itemPrice'];
        final double price = priceNum is num
            ? priceNum.toDouble()
            : (double.tryParse(priceNum?.toString() ?? '') ?? 0.0);
        if (price <= 0) continue;

        final itemUrl = (item['itemUrl'] ?? '').toString().trim();
        final shopName = (item['shopName'] ?? 'Rakuten Shop').toString().trim();
        final pointRate = item['pointRate'];

        String imageUrl = '';
        final mediumUrls = item['mediumImageUrls'];
        if (mediumUrls is List && mediumUrls.isNotEmpty) {
          final first = mediumUrls.first;
          if (first is String) {
            imageUrl = first;
          } else if (first is Map && first['imageUrl'] != null) {
            imageUrl = first['imageUrl'].toString();
          }
        }
        if (imageUrl.isNotEmpty) {
          // Request higher-resolution 400x400 thumbnail from Rakuten CDN
          imageUrl = imageUrl.replaceAll('_ex=128x128', '_ex=400x400');
        }

        final badge = pointRate != null && '$pointRate' != '1'
            ? '$shopName • ${pointRate}x Pts'
            : shopName;

        results.add(
          StoreItem(
            title: title,
            siteName: 'Rakuten Ichiba',
            price: price,
            imageUrl: imageUrl,
            siteUrl: itemUrl,
            badge: badge,
          ),
        );
      }

      return StoreSearchResult(items: results);
    } catch (e) {
      return StoreSearchResult(
        items: const [],
        error: 'Rakuten connection error: $e',
      );
    }
  }

  /// Searches Yahoo! Shopping Japan live product listings (V3/itemSearch)
  /// using the user's connected Yahoo! Client ID (appid).
  static Future<StoreSearchResult> searchYahoo({
    required String query,
    required String clientId,
    int hits = 3,
  }) async {
    final cleanId = clientId.trim();
    if (cleanId.isEmpty) {
      return const StoreSearchResult(
        items: [],
        error: 'Yahoo! Client ID (appid) is empty.',
      );
    }

    try {
      final uri = Uri.https(
        'shopping.yahooapis.jp',
        '/ShoppingWebService/V3/itemSearch',
        {
          'appid': cleanId,
          'query': query,
          'results': '$hits',
          'image_size': '300',
          'in_stock': 'true',
        },
      );

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map && errJson['Error'] is Map) {
            detail = (errJson['Error']['Message'] ?? detail).toString();
          }
        } catch (_) {}
        return StoreSearchResult(
          items: const [],
          error: 'Yahoo! Shopping API: $detail',
        );
      }

      final decoded = jsonDecode(response.body);
      final rawHits = (decoded is Map ? decoded['hits'] : null) as List?;
      if (rawHits == null || rawHits.isEmpty) {
        return const StoreSearchResult(items: []);
      }

      final List<StoreItem> results = [];
      for (final raw in rawHits.whereType<Map>()) {
        final title = (raw['name'] ?? query).toString().trim();
        final priceNum = raw['price'];
        final double price = priceNum is num
            ? priceNum.toDouble()
            : (double.tryParse(priceNum?.toString() ?? '') ?? 0.0);
        if (price <= 0) continue;

        final url = (raw['url'] ?? '').toString().trim();
        String imageUrl = '';
        final imgMap = raw['exImage'] ?? raw['image'];
        if (imgMap is Map) {
          imageUrl = (imgMap['url'] ?? imgMap['medium'] ?? imgMap['small'] ?? '')
              .toString()
              .trim();
        }

        final seller = raw['seller'];
        final sellerName = seller is Map && seller['name'] != null
            ? seller['name'].toString().trim()
            : 'Yahoo! Store';

        results.add(
          StoreItem(
            title: title,
            siteName: 'Yahoo! Shopping',
            price: price,
            imageUrl: imageUrl,
            siteUrl: url,
            badge: sellerName,
          ),
        );
      }

      return StoreSearchResult(items: results);
    } catch (e) {
      return StoreSearchResult(
        items: const [],
        error: 'Yahoo! Shopping connection error: $e',
      );
    }
  }

  /// Verifies Rakuten credentials with a quick 1-item test search.
  static Future<String?> testRakuten({
    required String appId,
    String accessKey = '',
  }) async {
    final res = await searchRakuten(
      query: 'Nintendo Switch',
      appId: appId,
      accessKey: accessKey,
      hits: 1,
    );
    if (res.error != null) return res.error;
    if (res.items.isEmpty) return 'No items returned. Check your Rakuten credentials.';
    return null;
  }

  /// Verifies Yahoo! Shopping Client ID with a quick 1-item test search.
  static Future<String?> testYahoo({required String clientId}) async {
    final res = await searchYahoo(
      query: 'Nintendo Switch',
      clientId: clientId,
      hits: 1,
    );
    if (res.error != null) return res.error;
    if (res.items.isEmpty) return 'No items returned. Check your Yahoo! Client ID.';
    return null;
  }
}

