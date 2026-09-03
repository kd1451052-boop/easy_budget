// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get chooseLanguageDesc =>
      'Wählen Sie Ihre bevorzugte Sprache, um zu beginnen.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageJapanese => 'Japanisch';

  @override
  String get languageKorean => 'Koreanisch';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get rememberMe => 'Angemeldet bleiben';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get login => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get dontHaveAccount => 'Sie haben noch kein Konto? Registrieren';

  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto? Anmelden';

  @override
  String get enterEmailReset =>
      'Bitte geben Sie Ihre E-Mail-Adresse ein, um das Passwort zurückzusetzen.';

  @override
  String get resetEmailSent =>
      'E-Mail zum Zurücksetzen des Passworts gesendet. Bitte überprüfen Sie Ihren Posteingang.';

  @override
  String get failedResetEmail =>
      'Fehler beim Senden der E-Mail zum Zurücksetzen des Passworts.';

  @override
  String get unexpectedError => 'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get authFailed =>
      'Authentifizierung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get expenseAnalytics => 'Ausgabenanalyse';

  @override
  String get totalSpent => 'Gesamtausgaben';

  @override
  String get noExpensesYet => 'Noch keine Ausgaben!';

  @override
  String get recentTransactions => 'Letzte Transaktionen';

  @override
  String get yearly => 'Jährlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get income => 'Einkommen';

  @override
  String get expense => 'Ausgaben';

  @override
  String get noRecentTransactions => 'Keine aktuellen Transaktionen.';

  @override
  String budgetAlert(String budgetName) {
    return 'Budget-Alarm: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return 'Sie haben $currency$spent von Ihrem $currency$limit Limit ausgegeben.';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return 'Einsparungen im Rückstand: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return 'Sie haben nur $currency$saved von Ihrem $currency$limit Ziel gespart.';
  }

  @override
  String get alertsInsights => 'Warnungen & Einblicke';

  @override
  String get settings => 'Einstellungen';

  @override
  String get preferences => 'Präferenzen';

  @override
  String get currency => 'Währung';

  @override
  String get language => 'Sprache';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get dataManagement => 'Datenverwaltung';

  @override
  String get exportDataCSV => 'Daten exportieren (CSV)';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get changesApplied => 'Änderungen erfolgreich angewendet!';

  @override
  String get editProfileName => 'Profilnamen bearbeiten';

  @override
  String get enterYourName => 'Geben Sie Ihren Namen ein';

  @override
  String get confirmNameChange => 'Namensänderung bestätigen';

  @override
  String confirmNameChangeDesc(String newName) {
    return 'Sind Sie sicher, dass Sie Ihren Profilnamen in $newName ändern möchten?';
  }

  @override
  String get save => 'Speichern';

  @override
  String get selectCurrency => 'Währung auswählen';

  @override
  String get confirmCurrency => 'Währung bestätigen';

  @override
  String confirmCurrencyDesc(String currency) {
    return 'Sind Sie sicher, dass Sie Ihre Standardwährung in $currency ändern möchten?';
  }

  @override
  String get confirmLanguage => 'Sprache bestätigen';

  @override
  String confirmLanguageDesc(String lang) {
    return 'Sind Sie sicher, dass Sie die App-Sprache in $lang ändern möchten?';
  }

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get exportDataDesc =>
      'Sind Sie sicher, dass Sie alle Ihre Transaktionsdaten als CSV-Datei generieren und exportieren möchten?';

  @override
  String get noDataToExport => 'Keine Daten zum Exportieren!';

  @override
  String get clearAllDataPrompt => 'Alle Daten löschen?';

  @override
  String get clearAllDataDesc =>
      'Sind Sie absolut sicher? Dadurch werden alle Ihre Transaktionen dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAll => 'Alles löschen';

  @override
  String get allDataCleared => 'Alle Daten erfolgreich gelöscht';

  @override
  String get proMember => 'Pro-Mitglied';

  @override
  String get confirmThemeChange => 'Themenänderung bestätigen';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return 'Sind Sie sicher, dass Sie den Dunkelmodus $on_off möchten?';
  }

  @override
  String get on => 'einschalten';

  @override
  String get off => 'ausschalten';

  @override
  String get budgetPageTitle => 'Budget';

  @override
  String get activeBudgets => 'Aktive Budgets';

  @override
  String get addBudget => 'Budget hinzufügen';

  @override
  String get noActiveBudgets => 'Keine aktiven Budgets.';

  @override
  String get savingGoals => 'Sparziele';

  @override
  String get newSaving => 'Neues Sparen';

  @override
  String get noActiveSavings => 'Keine aktiven Sparziele.';

  @override
  String get budgetAndSavingHistory => 'Budget- und Sparverlauf';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount ausgegeben';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount Limit';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount gespart';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount Ziel';
  }

  @override
  String get newSavingGoal => 'Neues Sparziel';

  @override
  String get goalName => 'Zielname';

  @override
  String get note => 'Hinweis';

  @override
  String get targetAmount => 'Zielbetrag';

  @override
  String get timeframe => 'Zeitrahmen';

  @override
  String get fixedDate => 'Festes Datum';

  @override
  String get period => 'Zeitraum';

  @override
  String get category => 'Kategorie';

  @override
  String get saveGoal => 'Ziel speichern';

  @override
  String get enterValidNameAndGoalAmount =>
      'Bitte geben Sie einen gültigen Namen und Zielbetrag ein';

  @override
  String get budgetName => 'Budgetname';

  @override
  String get amountLimit => 'Betragsgrenze';

  @override
  String get saveBudget => 'Budget speichern';

  @override
  String get enterValidNameAndAmount =>
      'Bitte geben Sie einen gültigen Namen und Betrag ein';

  @override
  String get customizeCategory => 'Kategorie anpassen';

  @override
  String get categoryName => 'Kategoriename';

  @override
  String get selectIcon => 'Symbol auswählen';

  @override
  String get saveCustomCategory => 'Kategorie speichern';

  @override
  String get customExpenseLimitReached =>
      'Limit für benutzerdefinierte Ausgaben erreicht (max. 10).';

  @override
  String get customIncomeLimitReached =>
      'Limit für benutzerdefinierte Einnahmen erreicht (max. 10).';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'Limit für benutzerdefinierte Ausgaben erreicht (max. 10). Bitte löschen Sie zuerst eine Kategorie.';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'Limit für benutzerdefinierte Einnahmen erreicht (max. 10). Bitte löschen Sie zuerst eine Kategorie.';

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String get addIncome => 'Einkommen hinzufügen';

  @override
  String get customPlus => 'Benutzerdefiniert +';

  @override
  String get dateTime => 'Datum & Uhrzeit';

  @override
  String get whatWasThisFor => 'Wofür war das?';

  @override
  String get saveTransaction => 'Transaktion speichern';

  @override
  String get transactionHistory => 'Transaktionsverlauf';

  @override
  String get noTransactionsOnDate => 'Keine Transaktionen an diesem Datum';

  @override
  String get history => 'Verlauf';

  @override
  String get pastBudgets => 'Vergangene Budgets';

  @override
  String get noPastBudgets => 'Keine vergangenen Budgets.';

  @override
  String get pastSavingGoals => 'Vergangene Sparziele';

  @override
  String get noPastSavingsGoals => 'Keine vergangenen Sparziele.';

  @override
  String get noNote => 'Keine Notiz';

  @override
  String get enterValidAmount => 'Bitte geben Sie einen gültigen Betrag ein';
}
