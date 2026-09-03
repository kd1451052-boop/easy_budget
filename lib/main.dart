import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'language_selection_page.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

import 'transaction_provider.dart';
import 'settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(),
      providerApple: AppleDebugProvider(),
    );
  }
  await SettingsProvider.init();

  final rememberMe = SettingsProvider.prefs.getBool('rememberMe') ?? false;
  if (!rememberMe) {
    await FirebaseAuth.instance.signOut();
  }

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: settingsProvider.locale,
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
          home: const RootWrapper(),
        );
      },
    );
  }
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (!settings.hasCompletedOnboarding) {
              return const LanguageSelectionPage();
            }
            return const HomePage();
          },
        );
      },
    );
  }
}
