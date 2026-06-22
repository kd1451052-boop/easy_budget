import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'transaction_provider.dart';
import 'transaction_repository.dart';
import 'settings_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SettingsProvider.init();
  await TransactionRepository.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const EasyBudget(),
    ),
  );
}

class EasyBudget extends StatelessWidget {
  const EasyBudget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: settingsProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true, 
            colorSchemeSeed: const Color(0xFF4F46E5),
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            cardColor: Colors.white,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}