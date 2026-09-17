import 'package:flutter/material.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

String getLocalizedCategory(BuildContext context, String category) {
  final loc = AppLocalizations.of(context)!;
  switch (category) {
    case 'Food': return loc.categoryFood;
    case 'Transport': return loc.categoryTransport;
    case 'Bill': return loc.categoryBill;
    case 'Rent': return loc.categoryRent;
    case 'Shopping': return loc.categoryShopping;
    case 'Salary': return loc.categorySalary;
    case 'Investment': return loc.categoryInvestment;
    case 'Gift': return loc.categoryGift;
    case 'Bonus': return loc.categoryBonus;
    case 'Entertainment': return loc.categoryEntertainment;
    case 'Utilities': return loc.categoryUtilities;
    case 'Health': return loc.categoryHealth;
    case 'Other': return loc.categoryOther;
    default: return category; // Custom category
  }
}
