import re

file_path = "lib/add_transaction_screen.dart"
with open(file_path, "r") as f:
    content = f.read()

# import AppLocalizations
content = content.replace("import 'shared_bottom_nav.dart';", "import 'shared_bottom_nav.dart';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';")

content = content.replace("const SnackBar(content: Text('Please enter a valid amount'))", "SnackBar(content: Text(AppLocalizations.of(context)!.enterValidAmount))")
content = content.replace("_noteController.text.isEmpty\n          ? 'No note'\n          : _noteController.text", "_noteController.text.isEmpty\n          ? AppLocalizations.of(context)!.noNote\n          : _noteController.text")
content = content.replace('const Text(\n                    "Customize Category",', 'Text(\n                    AppLocalizations.of(context)!.customizeCategory,')
content = content.replace('labelText: "Category Name",', 'labelText: AppLocalizations.of(context)!.categoryName,')
content = content.replace('const Text(\n                    "Select Icon",', 'Text(\n                    AppLocalizations.of(context)!.selectIcon,')
content = content.replace('const Text(\n                        "Save Custom Category",', 'Text(\n                        AppLocalizations.of(context)!.saveCustomCategory,')

content = content.replace("const SnackBar(\n                                    content: Text(\n                                      'Custom expense limit reached (10 max).',\n                                    ),\n                                  )", "SnackBar(\n                                    content: Text(\n                                      AppLocalizations.of(context)!.customExpenseLimitReached,\n                                    ),\n                                  )")
content = content.replace("const SnackBar(\n                                    content: Text(\n                                      'Custom income limit reached (10 max).',\n                                    ),\n                                  )", "SnackBar(\n                                    content: Text(\n                                      AppLocalizations.of(context)!.customIncomeLimitReached,\n                                    ),\n                                  )")

content = content.replace("const SnackBar(\n                                content: Text(\n                                  'Custom expense limit reached (10 max). Please delete a category first.',\n                                ),\n                              )", "SnackBar(\n                                content: Text(\n                                  AppLocalizations.of(context)!.customExpenseLimitReachedDeleteFirst,\n                                ),\n                              )")
content = content.replace("const SnackBar(\n                                content: Text(\n                                  'Custom income limit reached (10 max). Please delete a category first.',\n                                ),\n                              )", "SnackBar(\n                                content: Text(\n                                  AppLocalizations.of(context)!.customIncomeLimitReachedDeleteFirst,\n                                ),\n                              )")

content = content.replace('final headerTitle = isExpense ? "Add Expense" : "Add Income";', 'final headerTitle = isExpense ? AppLocalizations.of(context)!.addExpense : AppLocalizations.of(context)!.addIncome;')

content = content.replace('Text(\n                                "Expense",', 'Text(\n                                AppLocalizations.of(context)!.expenses,')
content = content.replace('Text(\n                                "Income",', 'Text(\n                                AppLocalizations.of(context)!.income,')

content = content.replace('const Text(\n                    "Category",', 'Text(\n                    AppLocalizations.of(context)!.category,')
content = content.replace('const Text(\n                            "Custom +",', 'Text(\n                            AppLocalizations.of(context)!.customPlus,')

content = content.replace('const Text(\n                    "Date & Time",', 'Text(\n                    AppLocalizations.of(context)!.dateTime,')
content = content.replace('const Text(\n                    "Note",', 'Text(\n                    AppLocalizations.of(context)!.note,')
content = content.replace('hintText: "What was this for?",', 'hintText: AppLocalizations.of(context)!.whatWasThisFor,')
content = content.replace('const Text(\n                        "Save Transaction",', 'Text(\n                        AppLocalizations.of(context)!.saveTransaction,')

with open(file_path, "w") as f:
    f.write(content)

print("Patched add_transaction_screen.dart")
