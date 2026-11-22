import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'settings_provider.dart';

/// Helper to return [ja] when the active locale is Japanese, or [en] otherwise.
String tr(BuildContext context, String en, String ja) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'ja' ? ja : en;
}

/// Returns the localized display name for a language key ('English' or 'Japanese').
String getLocalizedLanguageName(BuildContext context, String langKey) {
  final l10n = AppLocalizations.of(context)!;
  switch (langKey) {
    case 'Japanese':
      return l10n.languageJapanese;
    case 'Spanish':
      return l10n.languageSpanish;
    case 'French':
      return l10n.languageFrench;
    case 'German':
      return l10n.languageGerman;
    case 'Korean':
      return l10n.languageKorean;
    case 'English':
    default:
      return l10n.languageEnglish;
  }
}

/// Automatically translates and caches dynamic/saved text (such as scanned receipt
/// items, notes like "No note" / "メモなし", store names, and product titles)
/// so that switching the app between English and Japanese displays everything
/// in the currently selected language.
class AutoTranslator {
  static final Map<String, String> _memoryCache = {};
  static final Map<String, Future<String>> _inFlight = {};

  static final RegExp _japaneseRegex = RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]');
  static final RegExp _latinWordRegex = RegExp(r'[A-Za-z]{3,}');

  static const Set<String> _noNoteVariants = {
    'no note',
    'メモなし',
    '메모 없음',
    '无备注',
  };

  /// Synchronously translates known phrases ("No note" / "メモなし", store names,
  /// receipt labels) or returns a previously cached AI translation if available.
  static String localizeSync(BuildContext context, String rawText) {
    final trimmed = rawText.trim();
    final l10n = AppLocalizations.of(context)!;
    if (trimmed.isEmpty || _noNoteVariants.contains(trimmed.toLowerCase())) {
      return l10n.noNote;
    }

    final langCode = Localizations.localeOf(context).languageCode;
    final isJa = langCode == 'ja';

    // Known store names
    if (isJa) {
      if (trimmed == 'Rakuten Ichiba') return '楽天市場';
      if (trimmed == 'Yahoo! Shopping') return 'Yahoo!ショッピング';
      if (trimmed == 'Mercari') return 'メルカリ';
    } else {
      if (trimmed == '楽天市場') return 'Rakuten Ichiba';
      if (trimmed == 'Yahoo!ショッピング') return 'Yahoo! Shopping';
      if (trimmed == 'メルカリ') return 'Mercari';
    }

    final cacheKey = 'autotr_${langCode}_$trimmed';
    final mem = _memoryCache[cacheKey];
    if (mem != null && mem.isNotEmpty) return mem;

    try {
      final persisted = SettingsProvider.prefs.getString(cacheKey);
      if (persisted != null && persisted.isNotEmpty) {
        _memoryCache[cacheKey] = persisted;
        return persisted;
      }
    } catch (_) {}

    // Apply lightweight prefix replacements even before AI translation finishes
    var result = trimmed;
    if (isJa) {
      result = result
          .replaceAll('Receipt Date:', 'レシート日付:')
          .replaceAll('Note: Split receipt', 'メモ: 分割レシート')
          .replaceAll('Note: Majority category', 'メモ: メインカテゴリー')
          .replaceAll('Note:', 'メモ:')
          .replaceAll('Unknown Merchant', '不明な店舗')
          .replaceAll('Multiple Receipts', '複数のレシート');
    } else {
      result = result
          .replaceAll('レシート日付:', 'Receipt Date:')
          .replaceAll('メモ: 分割レシート', 'Note: Split receipt')
          .replaceAll('メモ:', 'Note:')
          .replaceAll('不明な店舗', 'Unknown Merchant')
          .replaceAll('複数のレシート', 'Multiple Receipts');
    }
    return result;
  }

  /// Returns true if [text] needs AI translation for [langCode]
  /// (e.g., contains Japanese characters when app is in English, or
  /// contains English words without Japanese characters when app is in Japanese).
  static bool needsAsyncTranslation(String text, String langCode) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _noNoteVariants.contains(trimmed.toLowerCase())) {
      return false;
    }
    final cacheKey = 'autotr_${langCode}_$trimmed';
    if (_memoryCache.containsKey(cacheKey)) return false;
    try {
      if (SettingsProvider.prefs.getString(cacheKey) != null) return false;
    } catch (_) {}

    if (langCode == 'en') {
      return _japaneseRegex.hasMatch(trimmed);
    } else if (langCode == 'ja') {
      return !_japaneseRegex.hasMatch(trimmed) &&
          _latinWordRegex.hasMatch(trimmed);
    }
    return false;
  }

  /// Translates [rawText] into [langCode] ('en' or 'ja') using Gemini Flash
  /// and caches the result in memory and SharedPreferences.
  static Future<String> translateAsync(String rawText, String langCode) async {
    final trimmed = rawText.trim();
    final cacheKey = 'autotr_${langCode}_$trimmed';

    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }
    try {
      final persisted = SettingsProvider.prefs.getString(cacheKey);
      if (persisted != null && persisted.isNotEmpty) {
        _memoryCache[cacheKey] = persisted;
        return persisted;
      }
    } catch (_) {}

    if (_inFlight.containsKey(cacheKey)) {
      return _inFlight[cacheKey]!;
    }

    final future = _performAiTranslation(trimmed, langCode, cacheKey);
    _inFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  static Future<String> _performAiTranslation(
    String text,
    String langCode,
    String cacheKey,
  ) async {
    final targetLanguageName = langCode == 'ja' ? 'Japanese' : 'English';
    try {
      final googleAI = FirebaseAI.googleAI();
      final model = googleAI.generativeModel(model: 'gemini-flash-latest');
      final prompt = TextPart(
        'Translate the following receipt/budget text into natural $targetLanguageName. '
        'Keep the exact line breaks, bullet points ("- "), numbers, and currency symbols/amounts unchanged. '
        'Return ONLY the translated text without quotes or explanations:\n$text',
      );
      final response = await model
          .generateContent([Content.multi([prompt])])
          .timeout(const Duration(seconds: 8));
      final translated = response.text?.trim();
      if (translated != null && translated.isNotEmpty) {
        _memoryCache[cacheKey] = translated;
        try {
          await SettingsProvider.prefs.setString(cacheKey, translated);
        } catch (_) {}
        return translated;
      }
    } catch (e) {
      debugPrint('AutoTranslator fallback for "$text": $e');
    }
    return text;
  }
}

/// Drop-in replacement for [Text] that automatically localizes stored transaction
/// descriptions, receipt scan results, "No note" / "メモなし", and product names
/// into the user's currently selected app language.
class AutoLocalizedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AutoLocalizedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  State<AutoLocalizedText> createState() => _AutoLocalizedTextState();
}

class _AutoLocalizedTextState extends State<AutoLocalizedText> {
  String? _asyncTranslated;
  String? _lastLangCode;
  String? _lastRawText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkTranslation();
  }

  @override
  void didUpdateWidget(covariant AutoLocalizedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _asyncTranslated = null;
      _checkTranslation();
    }
  }

  void _checkTranslation() {
    final langCode = Localizations.localeOf(context).languageCode;
    if (_lastLangCode != langCode || _lastRawText != widget.text) {
      _lastLangCode = langCode;
      _lastRawText = widget.text;
      _asyncTranslated = null;
    }

    if (AutoTranslator.needsAsyncTranslation(widget.text, langCode)) {
      AutoTranslator.translateAsync(widget.text, langCode).then((res) {
        if (mounted &&
            _lastLangCode == langCode &&
            _lastRawText == widget.text) {
          setState(() {
            _asyncTranslated = res;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final display =
        _asyncTranslated ?? AutoTranslator.localizeSync(context, widget.text);
    return Text(
      display,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
