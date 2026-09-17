import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';

import 'settings_provider.dart';
import 'main_navigation_screen.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final Color _primaryIndigo = const Color(0xFF5442F5);
  
  final List<String> _languages = [
    'English',
    'Japanese',
  ];

  String _getLanguageDisplayName(BuildContext context, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    switch (langCode) {
      case 'Japanese': return l10n.languageJapanese;
      case 'English':
      default: return l10n.languageEnglish;
    }
  }

  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Default to the first language or read from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _selectedLanguage = settings.selectedLanguage;
        if (!_languages.contains(_selectedLanguage)) {
          _selectedLanguage = _languages.first;
        }
      });
    });
    _selectedLanguage = _languages.first;
  }

  void _finishOnboarding() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.updateLanguage(_selectedLanguage);
    settings.updateHasCompletedOnboarding(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.language_rounded,
                size: 80,
                color: _primaryIndigo,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.chooseLanguageDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = language == _selectedLanguage;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLanguage = language;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? _primaryIndigo.withValues(alpha: 0.1) 
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? _primaryIndigo 
                                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLanguageDisplayName(context, language),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: _primaryIndigo),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  AppLocalizations.of(context)!.continueButton,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
