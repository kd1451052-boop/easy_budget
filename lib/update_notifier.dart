import 'dart:async';
import 'package:flutter/material.dart';
import 'settings_provider.dart';
import 'auto_translator.dart';
import 'update_ffi_stub.dart'
    if (dart.library.io) 'update_ffi_io.dart';

/// Tracks the current Shorebird OTA patch number and its "What's New" release notes.
/// Whenever you push a new Shorebird patch, increment [kCurrentPatchNumber]
/// and update [kWhatsNewItemsEn] / [kWhatsNewItemsJa] so users see a popup explaining what changed.
class UpdateNotifier {
  static const int kCurrentPatchNumber = 3;
  static const String kUpdateVersionLabel = 'v1.0.1 • Update #3';

  static const List<String> kWhatsNewItemsEn = [
    'Added full Burmese (မြန်မာဘာသာ) language and Myanmar Kyat (MMK / Ks) currency support across all screens.',
    'Full Japanese, English, and Burmese localization across Settings, Calendar, Home, and Add Transaction.',
    'Receipt scan results, notes, and saving goals automatically translate to match your selected app language.',
    'Calendar markers show Green for Income and Red for Expenses, with improved Login & Guest Registration flow.',
  ];

  static const List<String> kWhatsNewItemsJa = [
    'すべての画面でビルマ語（မြန်မာဘာသာ）とミャンマーチャット（MMK / Ks）通貨に完全対応しました。',
    '設定、カレンダー、ホーム、取引追加画面の日本語・英語・ビルマ語ローカライズを完全対応しました。',
    'レシートのスキャン結果、メモ、貯金目標が選択中のアプリ言語に自動翻訳されるようになりました。',
    'カレンダーのドットが収入は緑、支出は赤で表示され、ログイン・ゲスト登録フローを改善しました。',
  ];

  static const List<String> kWhatsNewItemsMy = [
    'ဆက်တင်များ၊ ပြက္ခဒိန်၊ ပင်မစာမျက်နှာနှင့် ငွေစာရင်းထည့်သွင်းသည့် မျက်နှာပြင်များအားလုံးတွင် မြန်မာဘာသာနှင့် မြန်မာကျပ်ငွေ (MMK / Ks) အပြည့်အဝ အသုံးပြုနိုင်ပါပြီ။',
    'ဘောင်ချာ စကန်ဖတ်ထားသော ရလဒ်များ၊ မှတ်စုများနှင့် စုငွေရည်မှန်းချက်များကို ရွေးချယ်ထားသော ဘာသာစကားသို့ အလိုအလျောက် ဘာသာပြန်ပေးပါသည်။',
    'ပြက္ခဒိန်တွင် ဝင်ငွေကို အစိမ်းရောင်၊ ထွက်ငွေကို အနီရောင် အစက်များဖြင့် ပြသပေးပါသည်။',
    'Easy Budget လိုဂိုအသစ်နှင့် အကောင့်ဝင်ခြင်း/ဧည့်သည်အသုံးပြုမှု စနစ်ကို ပိုမိုကောင်းမွန်အောင် ပြုလုပ်ထားပါသည်။',
  ];

  static const String _prefKeyLastSeenPatch = 'last_seen_patch_number';
  static bool _isDialogShowing = false;
  static bool _hasNotifiedPendingDownload = false;

  /// Checks if a new Shorebird update was just downloaded and applied,
  /// and also watches for background Shorebird downloads during the session.
  static Future<void> checkAndShowWhatsNew(BuildContext context) async {
    _watchForBackgroundDownload(context);

    if (_isDialogShowing || !context.mounted) return;

    final prefs = SettingsProvider.prefs;
    final lastSeenPatch = prefs.getInt(_prefKeyLastSeenPatch) ?? 0;

    if (lastSeenPatch >= kCurrentPatchNumber) {
      return;
    }

    _isDialogShowing = true;
    await prefs.setInt(_prefKeyLastSeenPatch, kCurrentPatchNumber);

    if (!context.mounted) {
      _isDialogShowing = false;
      return;
    }

    final code = Localizations.localeOf(context).languageCode;
    final items = code == 'ja'
        ? kWhatsNewItemsJa
        : (code == 'my' ? kWhatsNewItemsMy : kWhatsNewItemsEn);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        ctx,
                        'New Update Downloaded!',
                        '新しいアップデートを適用しました！',
                        'အပ်ဒိတ်အသစ် ထည့်သွင်းပြီးပါပြီ!',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      kUpdateVersionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  ctx,
                  'Your app has been automatically updated to the latest version. Here is what\'s new:',
                  'アプリが最新バージョンに自動更新されました。更新内容は以下の通りです:',
                  'သင့်အက်ပ်ကို နောက်ဆုံးဗားရှင်းသို့ အလိုအလျောက် အပ်ဒိတ်လုပ်ပြီးပါပြီ။ အသစ်ပါဝင်လာသော အချက်များမှာ -',
                ),
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.star,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 13.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  tr(ctx, 'Got It!', 'OK', 'သိပါပြီ!'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    _isDialogShowing = false;
  }

  /// Periodically checks if Shorebird just finished downloading a new patch
  /// in the background while the user is using the app, and notifies them.
  static void _watchForBackgroundDownload(BuildContext context) {
    if (_hasNotifiedPendingDownload) return;
    for (final seconds in const [5, 12, 25]) {
      Future<void>.delayed(Duration(seconds: seconds), () {
        if (_hasNotifiedPendingDownload || !context.mounted) return;
        if (isNewShorebirdPatchDownloaded()) {
          _hasNotifiedPendingDownload = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF4F46E5),
              duration: const Duration(seconds: 6),
              content: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(
                        context,
                        'New update downloaded! Restart the app to apply the latest changes.',
                        '新しいアップデートがダウンロードされました！アプリを再起動すると反映されます。',
                        'အပ်ဒိတ်အသစ် ဒေါင်းလုဒ်ဆွဲပြီးပါပြီ! ပြောင်းလဲမှုများ အသက်ဝင်စေရန် အက်ပ်ကို ပြန်ဖွင့်ပေးပါ။',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    }
  }
}
