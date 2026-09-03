import 'dart:io';

void main() {
  final files = [
    'lib/transaction_repository.dart',
    'lib/transaction_provider.dart',
    'lib/history.dart',
    'lib/home_page.dart',
    'lib/add_transaction_screen.dart',
    'lib/scanner.dart',
  ];
  
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // replacements
    content = content.replaceAll(RegExp(r'\bList<Transaction>\b'), 'List<AppTransaction>');
    content = content.replaceAll(RegExp(r'\bTransaction\.fromMap\b'), 'AppTransaction.fromMap');
    content = content.replaceAll(RegExp(r'\bTransaction\('), 'AppTransaction(');
    content = content.replaceAll(RegExp(r'\bclass Transaction\b'), 'class AppTransaction');
    content = content.replaceAll(RegExp(r'\bTransaction transaction\b'), 'AppTransaction transaction');
    content = content.replaceAll(RegExp(r'\bTransaction t\b'), 'AppTransaction t');
    content = content.replaceAll(RegExp(r"import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;"), "import 'package:cloud_firestore/cloud_firestore.dart';");
    
    file.writeAsStringSync(content);
  }
}
