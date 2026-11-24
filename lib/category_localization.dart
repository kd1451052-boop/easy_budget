import 'package:flutter/material.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'auto_translator.dart';

String getLocalizedCategory(BuildContext context, String category) {
  final loc = AppLocalizations.of(context)!;
  switch (category) {
    case 'Food':
      return loc.categoryFood;
    case 'Transport':
      return loc.categoryTransport;
    case 'Bill':
      return loc.categoryBill;
    case 'Rent':
      return loc.categoryRent;
    case 'Shopping':
      return loc.categoryShopping;
    case 'Salary':
      return loc.categorySalary;
    case 'Investment':
      return loc.categoryInvestment;
    case 'Gift':
      return loc.categoryGift;
    case 'Bonus':
      return loc.categoryBonus;
    case 'Entertainment':
      return loc.categoryEntertainment;
    case 'Utilities':
      return loc.categoryUtilities;
    case 'Health':
    case 'Medical':
      return loc.categoryHealth;
    case 'Other':
      return loc.categoryOther;
    case 'Clothes':
      return tr(context, 'Clothes', '衣類', 'အဝတ်အထည်');
    case 'Electronics':
      return tr(context, 'Electronics', '家電・電子機器', 'အီလက်ထရောနစ်');
    case 'Pets':
      return tr(context, 'Pets', 'ペット', 'အိမ်မွေးတိရစ္ဆာန်');
    case 'Coffee':
      return tr(context, 'Coffee', 'カフェ・コーヒー', 'ကော်ဖီ');
    case 'Education':
      return tr(context, 'Education', '教育', 'ပညာရေး');
    case 'Fitness':
    case 'Gym':
      return tr(context, 'Fitness', 'フィットネス', 'အားကစား');
    case 'Debt':
      return tr(context, 'Debt', '借入・返済', 'အကြွေး');
    case 'water_bill':
      return tr(context, 'Water Bill', '水道代', 'ရေဖိုး');
    case 'internet_bill':
      return tr(context, 'Internet Bill', 'インターネット代', 'အင်တာနက်ဖိုး');
    case 'electricity_bill':
      return tr(context, 'Electricity Bill', '電気代', 'မီးဖိုး');
    default:
      final langCode = Localizations.localeOf(context).languageCode;
      if (AutoTranslator.needsAsyncTranslation(category, langCode)) {
        AutoTranslator.translateAsync(category, langCode);
      }
      return AutoTranslator.localizeSync(context, category);
  }
}
