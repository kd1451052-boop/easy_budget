import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'settings_provider.dart';
import 'transaction_provider.dart';
import 'history.dart';
import 'home_page.dart';
class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    final apiKey = Provider.of<SettingsProvider>(context, listen: false).geminiApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your Gemini API Key in Settings first.')),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final bytes = await image.readAsBytes();
      
      final prompt = TextPart('''
Extract receipt data as JSON. Return a JSON object with this exact structure: 
{
  "merchant": "name", 
  "date": "yyyy-MM-dd", 
  "total": 12.34, 
  "items": [{"name": "item 1", "price": 1.23}]
}
Output ONLY valid JSON without any markdown formatting.
''');
      final imagePart = DataPart('image/jpeg', bytes);
      
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (!mounted) return;

      final text = response.text ?? '{}';
      // Clean up potential markdown formatting from Gemini response
      final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final data = jsonDecode(jsonString);
      
      _showResultBottomSheet(
        merchant: data['merchant']?.toString() ?? 'Unknown Merchant',
        total: double.tryParse(data['total']?.toString() ?? '0') ?? 0.0,
        dateString: data['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
        items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning receipt: $e')),
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
            const Text(
              'Scan Result',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildResultRow('Merchant', merchant),
            _buildResultRow(
              'Total Amount',
              '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${total.toStringAsFixed(2)}',
            ),
            _buildResultRow('Date', dateString),
            
            const SizedBox(height: 16),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['name']?.toString() ?? 'Unknown item', style: TextStyle(color: Colors.grey.shade700))),
                        Text('${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${price.toStringAsFixed(2)}'),
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
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const HomePage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm & Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(
                child: Text('Retake', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction(String merchant, double total, String dateString, List<Map<String, dynamic>> items) {
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

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.expense,
      category: 'Shopping', // Default category for scanned receipts
      description: descriptionBuffer.toString().trim(),
      amount: total,
      dateTime: parsedDate,
      iconCodePoint: Icons.receipt.codePoint,
      iconColorValue: const Color(0xFF6366F1).toARGB32(),
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Viewfinder
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animationController.value * (MediaQuery.of(context).size.height * 0.5 - 2),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              color: Colors.cyanAccent,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          // Top Controls
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) => const HomePage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _scanReceipt(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: _isScanning ? null : () => _scanReceipt(ImageSource.camera),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.flash_on_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 300),
                child: Text(
                  'Scanning Receipt...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
