import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'transaction_provider.dart';
import 'transaction_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await TransactionRepository.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: const EasyBudget(),
    ),
  );
}

class EasyBudget extends StatelessWidget {
  const EasyBudget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF4F46E5)),
      home: const HomePage(),
    );
  }
}