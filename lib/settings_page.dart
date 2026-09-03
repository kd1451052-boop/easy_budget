import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart'; // Make sure this import matches your file structure
import 'settings_provider.dart';
import 'shared_bottom_nav.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'profile_page.dart';
import 'profile_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 16),

          _buildSectionHeader(AppLocalizations.of(context)!.preferences),
          _buildSettingTile(
            Icons.monetization_on_outlined,
            AppLocalizations.of(context)!.currency,
            settings.selectedCurrency,
            onTap: _showCurrencyPicker,
          ),
          _buildSettingTile(
            Icons.language_outlined,
            AppLocalizations.of(context)!.language,
            settings.selectedLanguage,
            onTap: _showLanguagePicker,
          ),
          _buildThemeToggle(),
          const SizedBox(height: 16),

          _buildSectionHeader(AppLocalizations.of(context)!.dataManagement),
          _buildSettingTile(
            Icons.file_download_outlined,
            AppLocalizations.of(context)!.exportDataCSV,
            null,
            onTap: () => _exportToCSV(context),
          ),

          _buildSettingTile(
            Icons.delete_outline,
            AppLocalizations.of(context)!.clearAllData,
            null,
            isDestructive: true,
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 4),
    );
  }

  // --- REUSABLE CONFIRMATION POPUP ---

  /// This handles the "Are you sure?" popup for all settings changes
  void _confirmChange(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Cancel does nothing
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog
              onConfirm(); // Execute the actual change
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.changesApplied)),
              );
            },
            child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FEATURE LOGIC ---



  void _showCurrencyPicker() {
    final selectedCurrency = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).selectedCurrency;
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          AppLocalizations.of(context)!.selectCurrency,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx); // Close picker
              if (currency != selectedCurrency) {
                // Trigger Confirmation
                _confirmChange(
                  AppLocalizations.of(context)!.confirmCurrency,
                  AppLocalizations.of(context)!.confirmCurrencyDesc(currency),
                  () {
                    Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).updateCurrency(currency);
                  },
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(currency, style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLanguagePicker() {
    final selectedLanguage = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Japanese',
      'Korean',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          AppLocalizations.of(context)!.confirmLanguage,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: languages.map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx); // Close picker
              if (lang != selectedLanguage) {
                // Trigger Confirmation
                _confirmChange(
                  AppLocalizations.of(context)!.confirmLanguage,
                  AppLocalizations.of(context)!.confirmLanguageDesc(lang),
                  () {
                    Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    ).updateLanguage(lang);
                  },
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(lang, style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _exportToCSV(BuildContext context) {
    _confirmChange(
      AppLocalizations.of(context)!.exportData,
      AppLocalizations.of(context)!.exportDataDesc,
      () {
        final provider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        final transactions = provider.transactions;

        if (transactions.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noDataToExport)));
          return;
        }

        StringBuffer csv = StringBuffer();
        csv.writeln('Type,Category,Description,Amount,Date');
        for (var tx in transactions) {
          final typeString = tx.type.toString().split('.').last;
          csv.writeln(
            '$typeString,${tx.category},"${tx.description}",${tx.amount},${tx.dateTime.toIso8601String()}',
          );
        }

        debugPrint("--- EXPORTED CSV DATA ---");
        debugPrint(csv.toString());
      },
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.clearAllDataPrompt,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          AppLocalizations.of(context)!.clearAllDataDesc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
            ),
            onPressed: () {
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.allDataCleared)),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.deleteAll,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- ORIGINAL UI WIDGET EXTRACTS ---

  Widget _buildProfileSection() {
    final settings = Provider.of<SettingsProvider>(context);
    final userName = settings.userName;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              imageUrl: settings.profilePicture,
              frame: settings.profileFrame,
              radius: 35,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.proMember,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String? trailing, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Colors.red
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing, style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggle() {
    final isDarkMode = Provider.of<SettingsProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.dark_mode_outlined,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          AppLocalizations.of(context)!.darkMode,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (v) {
            Provider.of<SettingsProvider>(
              context,
              listen: false,
            ).toggleTheme(v);
          },
          activeThumbColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }
}
