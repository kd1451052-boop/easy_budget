import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart'; // Make sure this import matches your file structure

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- STATE VARIABLES ---
  String userName = 'John Doe';
  String selectedCurrency = 'USD';
  String selectedLanguage = 'English';
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 32),
          
          _buildSectionHeader('Preferences'),
          _buildSettingTile(
            Icons.monetization_on_outlined, 
            'Currency', 
            selectedCurrency,
            onTap: _showCurrencyPicker,
          ),
          _buildSettingTile(
            Icons.language_outlined, 
            'Language', 
            selectedLanguage,
            onTap: _showLanguagePicker,
          ),
          _buildThemeToggle(),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader('Data Management'),
          _buildSettingTile(
            Icons.file_download_outlined, 
            'Export Data (CSV)', 
            null,
            onTap: () => _exportToCSV(context),
          ),
          
          _buildSettingTile(
            Icons.delete_outline, 
            'Clear All Data', 
            null, 
            isDestructive: true,
            onTap: () => _showClearDataDialog(context),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, elevation: 0),
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog
              onConfirm(); // Execute the actual change
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changes applied successfully!')),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FEATURE LOGIC ---

  void _editProfileName() {
    final TextEditingController nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: Colors.black54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, elevation: 0),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != userName) {
                Navigator.pop(ctx); // Close input dialog
                // Trigger Confirmation
                _confirmChange(
                  'Confirm Name Change', 
                  'Are you sure you want to change your profile name to $newName?', 
                  () {
                    setState(() => userName = newName);
                    // TODO: Save to your user profile database/provider here
                  }
                );
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx); // Close picker
              if (currency != selectedCurrency) {
                // Trigger Confirmation
                _confirmChange(
                  'Confirm Currency', 
                  'Are you sure you want to change your default currency to $currency?', 
                  () {
                    setState(() => selectedCurrency = currency);
                    // TODO: Update your Global Settings Provider here
                  }
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
    final languages = ['English', 'Spanish', 'French', 'German', 'Japanese', 'Korean'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: languages.map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx); // Close picker
              if (lang != selectedLanguage) {
                // Trigger Confirmation
                _confirmChange(
                  'Confirm Language', 
                  'Are you sure you want to change the app language to $lang?', 
                  () {
                    setState(() => selectedLanguage = lang);
                    // TODO: Update your Global Settings Provider / Localization here
                  }
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
      'Export Data', 
      'Are you sure you want to generate and export all your transaction data as a CSV file?', 
      () {
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        final transactions = provider.transactions;

        if (transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export!')),
          );
          return;
        }

        StringBuffer csv = StringBuffer();
        csv.writeln('Type,Category,Description,Amount,Date'); 
        for (var tx in transactions) {
          final typeString = tx.type.toString().split('.').last; 
          csv.writeln('$typeString,${tx.category},"${tx.description}",${tx.amount},${tx.dateTime.toIso8601String()}');
        }

        print("--- EXPORTED CSV DATA ---");
        print(csv.toString());
      }
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear All Data?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text("Are you absolutely sure? This will permanently delete all your transactions. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully')),
              );
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- ORIGINAL UI WIDGET EXTRACTS ---

  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: _editProfileName,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            const CircleAvatar(radius: 35, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d')),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pro Member', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String? trailing, {bool isDestructive = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF1E293B)),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) Text(trailing, style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.dark_mode_outlined, color: Color(0xFF1E293B)),
        title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (v) {
            // Trigger Confirmation when flipping the switch
            _confirmChange(
              'Confirm Theme Change', 
              'Are you sure you want to turn ${v ? 'on' : 'off'} Dark Mode?', 
              () {
                setState(() => isDarkMode = v);
                // TODO: Update your Global Theme Provider here
              }
            );
          },
          activeThumbColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }
}