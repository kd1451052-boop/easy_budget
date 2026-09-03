import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'history.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

class SavingPage extends StatefulWidget {
  const SavingPage({super.key});

  @override
  State<SavingPage> createState() => _SavingPageState();
}

class _SavingPageState extends State<SavingPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isFixed = true;
  DateTime _selectedDate = DateTime.now();
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String _selectedCategory = 'Investment';

  final List<String> _incomeCategories = [
    'Salary',
    'Investment',
    'Gift',
    'Bonus',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterValidNameAndGoalAmount)),
      );
      return;
    }

    final goal = SavingsGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      note: _noteController.text,
      amount: amount,
      isFixed: _isFixed,
      targetDate: _isFixed ? _selectedDate : null,
      period: !_isFixed ? _selectedPeriod : null,
      category: _selectedCategory,
      createdAt: DateTime.now(),
    );

    Provider.of<TransactionProvider>(context, listen: false).addSavingsGoal(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF10B981); // Emerald Green for savings
    final settings = Provider.of<SettingsProvider>(context);
    // Assuming savings are tracked against income/savings categories
    final currentCategories = [..._incomeCategories, ...settings.customIncomeCategories.keys];

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
            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.goalName,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.note,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.targetAmount,
                prefixText: '${settings.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),

            // Time Selection
            Text(AppLocalizations.of(context)!.timeframe, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFixed ? headerColor : Colors.grey.shade200,
                      foregroundColor: _isFixed ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isFixed = true),
                    child: Text(AppLocalizations.of(context)!.fixedDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isFixed ? headerColor : Colors.grey.shade200,
                      foregroundColor: !_isFixed ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isFixed = false),
                    child: Text(AppLocalizations.of(context)!.period),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isFixed)
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}"),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<BudgetPeriod>(
                initialValue: _selectedPeriod,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                items: [
                  DropdownMenuItem(value: BudgetPeriod.weekly, child: Text(AppLocalizations.of(context)!.weekly)),
                  DropdownMenuItem(value: BudgetPeriod.monthly, child: Text(AppLocalizations.of(context)!.monthly)),
                  DropdownMenuItem(value: BudgetPeriod.yearly, child: Text(AppLocalizations.of(context)!.yearly)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPeriod = val);
                },
              ),
            const SizedBox(height: 32),

            // Category Selection
            Text(AppLocalizations.of(context)!.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: currentCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? headerColor.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(color: isSelected ? headerColor : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(cat, style: TextStyle(color: isSelected ? headerColor : Colors.black54, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: headerColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(AppLocalizations.of(context)!.saveGoal, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
