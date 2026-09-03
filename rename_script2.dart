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
    content = content.replaceAll(RegExp(r'List<Transaction>'), 'List<AppTransaction>');
    content = content.replaceAll(RegExp(r'Stream<List<Transaction>>'), 'Stream<List<AppTransaction>>');
    file.writeAsStringSync(content);
  }
}
