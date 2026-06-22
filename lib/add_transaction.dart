//Copyright 2026 THANT ZIN

// Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at

//http://www.apache.org/licenses/LICENSE-2.0

//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'history.dart';
import 'transaction_repository.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // 1. All state variables are declared here once
  bool isExpense = true;
  String selectedCategory = 'Food';
  IconData selectedIcon = Icons.fastfood; 
  DateTime selectedDate = DateTime.now(); 

  // 2. The getter is placed here, so the whole class can use it!
  Color get themeColor => isExpense ? const Color(0xFF6366F1) : const Color(0xFF10B981);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final _repository = TransactionRepository();

  final List<String> categories = ['Food', 'Travel', 'Bills', 'Shopping', 'Health', 'Home', 'Custom'];

  void _showCustomCategoryModal() {
    String tempName = '';
    IconData tempIcon = Icons.star;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (value) => tempName = value,
                  decoration: InputDecoration(hintText: 'Category Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
                    itemCount: 6,
                    itemBuilder: (context, i) {
                      final iconList = [Icons.car_rental, Icons.coffee, Icons.monitor, Icons.favorite, Icons.pets, Icons.work];
                      final icon = iconList[i];
                      final isIconSelected = tempIcon == icon;
                      
                      return GestureDetector(
                        onTap: () => setModalState(() => tempIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isIconSelected ? Colors.black : Colors.grey.shade100, 
                            shape: BoxShape.circle
                          ),
                          child: Icon(icon, color: isIconSelected ? Colors.white : Colors.black),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (tempName.isNotEmpty) {
                      setState(() {
                        selectedCategory = tempName;
                        selectedIcon = tempIcon;
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Add Category', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Notice we removed the local `themeColor` variable from here! 
    // It will automatically use the getter from the top of the class.

    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(color: themeColor, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [_buildToggleButton('Expense', isExpense), _buildToggleButton('Income', !isExpense)]),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 60),
                const Text('Amount', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(prefixText: '${Provider.of<SettingsProvider>(context).currencySymbol}', prefixStyle: const TextStyle(color: Colors.white54), border: InputBorder.none, hintText: '0.00', hintStyle: const TextStyle(color: Colors.white24)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: categories.map((cat) => _buildCategoryPill(cat)).toList()),
                const SizedBox(height: 32),
                const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: _pickDateTime,
                  child: _buildCustomInput(Icons.calendar_today_outlined, DateFormat('MMM dd, yyyy · HH:mm a').format(selectedDate)),
                ),
                
                const SizedBox(height: 24),
                const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(hintText: 'Enter notes here...', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
              child: const Text('Save Transaction', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: isExpense ? TransactionType.expense : TransactionType.income,
      category: selectedCategory,
      description: _noteController.text.isEmpty ? 'No note' : _noteController.text,
      amount: amount,
      dateTime: selectedDate, 
      iconCodePoint: selectedCategory == categories.last ? selectedIcon.codePoint : _getIconForCategory(selectedCategory).codePoint,
      iconColorValue: (isExpense ? Colors.red : Colors.green).value,
    );

    await _repository.save(tx);
    if (mounted) Navigator.pop(context);
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood;
      case 'Travel': return Icons.flight;
      case 'Bills': return Icons.receipt;
      case 'Shopping': return Icons.shopping_bag;
      case 'Health': return Icons.medical_services;
      case 'Home': return Icons.home;
      default: return Icons.more_horiz;
    }
  }

  Widget _buildToggleButton(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => isExpense = label == 'Expense'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        // 4. themeColor works perfectly here now!
        child: Text(label, style: TextStyle(color: active ? themeColor : Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryPill(String cat) {
    final isSelected = selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        if (cat == 'Custom') {
          _showCustomCategoryModal();
        } else {
          setState(() => selectedCategory = cat);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cat == 'Custom') const Icon(Icons.add, size: 16, color: Colors.grey),
            if (cat == 'Custom') const SizedBox(width: 4),
            Text(cat == 'Custom' && selectedCategory != 'Food' && !categories.sublist(0,6).contains(selectedCategory) ? selectedCategory : cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [Icon(icon, color: Colors.grey, size: 20), const SizedBox(width: 12), Text(text, style: TextStyle(color: Colors.grey.shade600))]),
    );
  }
}