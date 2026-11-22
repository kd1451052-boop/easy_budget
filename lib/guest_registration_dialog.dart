import 'package:flutter/material.dart';
import 'package:easy_budget/login_page.dart';
import 'package:easy_budget/l10n/app_localizations.dart';
import 'auto_translator.dart';

Future<void> showGuestRegistrationDialog(
  BuildContext context, {
  String featureName = 'this feature',
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(tr(context, 'Register Account', 'アカウント登録')),
        content: Text(
          tr(
            context,
            'Please register an account to access $featureName. Guest users have limited access.',
            'この機能を利用するにはアカウントを登録してください。ゲストユーザーは一部機能が制限されています。',
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: <Widget>[
          TextButton(
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.signUp),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(initialIsLogin: false),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
