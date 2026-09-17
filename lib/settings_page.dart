import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'transaction_provider.dart';
import 'b_and_s_history_page.dart';
import 'achievements_page.dart';
import 'settings_provider.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'profile_page.dart';
import 'profile_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:archive/archive.dart';
import 'login_page.dart';
import 'dart:convert';

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
          _buildSettingTile(
            Icons.emoji_events,
            'Achievements & Badges',
            null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsPage()),
              );
            },
          ),

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
            Icons.backup_outlined,
            'Backup Data (ZIP)',
            null,
            onTap: () => _backupDataToZip(context),
          ),
          _buildSettingTile(
            Icons.delete_outline,
            AppLocalizations.of(context)!.clearAllData,
            null,
            isDestructive: true,
            onTap: () => _showClearDataDialog(context),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Account'),
          _buildSettingTile(
            Icons.switch_account_outlined,
            'Switch Account',
            null,
            onTap: () => _handleSignOut(context, isSwitchAccount: true),
          ),
          _buildSettingTile(
            Icons.logout,
            'Log Out',
            null,
            isDestructive: true,
            onTap: () => _handleSignOut(context, isSwitchAccount: false),
          ),
        ],
      ),
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
      'Japanese',
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
      () async {
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

        try {
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/transactions.csv');
          await file.writeAsString(csv.toString());
          
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Easy Budget Transactions Export',
          );
        } catch (e) {
          debugPrint("Export failed: $e");
        }
      },
    );
  }

  void _backupDataToZip(BuildContext context) {
    _confirmChange(
      'Backup Data',
      'Are you sure you want to backup all your data? The file will be saved on your device.',
      () async {
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        final transactions = provider.transactions;
        
        if (transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to backup!'))
          );
          return;
        }

        try {
          final archive = Archive();
          
          final txJsonList = transactions.map((t) => {
            'id': t.id,
            'amount': t.amount,
            'type': t.type.toString(),
            'category': t.category,
            'description': t.description,
            'dateTime': t.dateTime.toIso8601String(),
          }).toList();
          
          final jsonString = jsonEncode(txJsonList);
          final jsonBytes = utf8.encode(jsonString);
          
          archive.addFile(ArchiveFile('transactions_backup.json', jsonBytes.length, jsonBytes));
          
          final zipData = ZipEncoder().encode(archive);

          final directory = await getApplicationDocumentsDirectory();
          final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
          final zipFile = File('${directory.path}/EasyBudget_Backup_$dateStr.zip');
          
          await zipFile.writeAsBytes(zipData);
          
          if (!context.mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Backup Successful', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('Your backup has been saved to:\n\n${zipFile.path}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.shareXFiles([XFile(zipFile.path)], text: 'My Easy Budget Backup');
                  },
                  child: const Text('Share/Export'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } catch (e) {
          debugPrint("Backup failed: $e");
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup failed: $e'))
          );
        }
      },
    );
  }

  void _handleSignOut(BuildContext context, {required bool isSwitchAccount}) {
    final title = isSwitchAccount ? 'Switch Account' : 'Log Out';
    final desc = isSwitchAccount 
      ? 'Are you sure you want to switch accounts?' 
      : 'Are you sure you want to log out?';

    _confirmChange(
      title,
      desc,
      () async {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (!isSwitchAccount) {
          settings.updateRememberMe(false);
          settings.updateRememberedEmail('');
        }
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
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
