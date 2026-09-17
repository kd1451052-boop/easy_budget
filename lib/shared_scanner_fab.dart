import 'package:flutter/material.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'scanner.dart';
import 'settings_provider.dart';
import 'guest_registration_dialog.dart';

class SharedScannerFAB extends StatelessWidget {
  const SharedScannerFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.qr_code_scanner,
      activeIcon: Icons.close,
      backgroundColor: const Color(0xFF5442F5),
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.camera_alt, color: Colors.white),
          backgroundColor: const Color(0xFF6366F1),
          label: AppLocalizations.of(context)!.takePhoto,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: () {
            final settings = Provider.of<SettingsProvider>(context, listen: false);
            if (!settings.canGuestScan) {
              showGuestRegistrationDialog(context, featureName: 'more than 10 scans a day');
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const Scanner(initialSource: ImageSource.camera),
              ),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.photo_library, color: Colors.white),
          backgroundColor: const Color(0xFF5442F5),
          label: AppLocalizations.of(context)!.useGallery,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: () {
            final settings = Provider.of<SettingsProvider>(context, listen: false);
            if (!settings.canGuestScan) {
              showGuestRegistrationDialog(context, featureName: 'more than 10 scans a day');
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const Scanner(initialSource: ImageSource.gallery),
              ),
            );
          },
        ),
      ],
    );
  }
}
