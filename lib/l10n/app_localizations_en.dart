// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chooseLanguageDesc =>
      'Choose your preferred language to get started.';

  @override
  String get continueButton => 'Continue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageKorean => 'Korean';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccount => 'Create an account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'\'t have an account? Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get enterEmailReset => 'Please enter your email to reset password.';

  @override
  String get resetEmailSent =>
      'Password reset email sent. Please check your inbox.';

  @override
  String get failedResetEmail => 'Failed to send password reset email.';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get thisWeek => 'This Week';

  @override
  String get expenseAnalytics => 'Expense Analytics';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get noExpensesYet => 'No expenses yet!';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get weekly => 'Weekly';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get noRecentTransactions => 'No recent transactions.';

  @override
  String budgetAlert(String budgetName) {
    return 'Budget Alert: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return 'You have spent $currency$spent of your $currency$limit limit.';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return 'Savings Falling Behind: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return 'You have only saved $currency$saved of your $currency$limit goal.';
  }

  @override
  String get alertsInsights => 'Alerts & Insights';

  @override
  String get settings => 'Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get currency => 'Currency';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportDataCSV => 'Export Data (CSV)';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get changesApplied => 'Changes applied successfully!';

  @override
  String get editProfileName => 'Edit Profile Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get confirmNameChange => 'Confirm Name Change';

  @override
  String confirmNameChangeDesc(String newName) {
    return 'Are you sure you want to change your profile name to $newName?';
  }

  @override
  String get save => 'Save';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get confirmCurrency => 'Confirm Currency';

  @override
  String confirmCurrencyDesc(String currency) {
    return 'Are you sure you want to change your default currency to $currency?';
  }

  @override
  String get confirmLanguage => 'Confirm Language';

  @override
  String confirmLanguageDesc(String lang) {
    return 'Are you sure you want to change the app language to $lang?';
  }

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDesc =>
      'Are you sure you want to generate and export all your transaction data as a CSV file?';

  @override
  String get noDataToExport => 'No data to export!';

  @override
  String get clearAllDataPrompt => 'Clear All Data?';

  @override
  String get clearAllDataDesc =>
      'Are you absolutely sure? This will permanently delete all your transactions. This action cannot be undone.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get allDataCleared => 'All data cleared successfully';

  @override
  String get proMember => 'Pro Member';

  @override
  String get confirmThemeChange => 'Confirm Theme Change';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return 'Are you sure you want to turn $on_off Dark Mode?';
  }

  @override
  String get on => 'on';

  @override
  String get off => 'off';

  @override
  String get budgetPageTitle => 'Budget';

  @override
  String get activeBudgets => 'Active Budgets';

  @override
  String get addBudget => 'Add Budget';

  @override
  String get noActiveBudgets => 'No active budgets.';

  @override
  String get savingGoals => 'Saving Goals';

  @override
  String get newSaving => 'New Saving';

  @override
  String get noActiveSavings => 'No active savings goals.';

  @override
  String get budgetAndSavingHistory => 'Budget and Saving History';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount spent';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount limit';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount saved';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount goal';
  }

  @override
  String get newSavingGoal => 'New Saving Goal';

  @override
  String get goalName => 'Goal Name';

  @override
  String get note => 'Note';

  @override
  String get targetAmount => 'Target Amount';

  @override
  String get timeframe => 'Timeframe';

  @override
  String get fixedDate => 'Fixed Date';

  @override
  String get period => 'Period';

  @override
  String get category => 'Category';

  @override
  String get saveGoal => 'Save Goal';

  @override
  String get enterValidNameAndGoalAmount =>
      'Please enter a valid name and goal amount';

  @override
  String get budgetName => 'Budget Name';

  @override
  String get amountLimit => 'Amount Limit';

  @override
  String get saveBudget => 'Save Budget';

  @override
  String get enterValidNameAndAmount => 'Please enter a valid name and amount';

  @override
  String get customizeCategory => 'Customize Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get saveCustomCategory => 'Save Custom Category';

  @override
  String get customExpenseLimitReached =>
      'Custom expense limit reached (10 max).';

  @override
  String get customIncomeLimitReached =>
      'Custom income limit reached (10 max).';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'Custom expense limit reached (10 max). Please delete a category first.';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'Custom income limit reached (10 max). Please delete a category first.';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get addIncome => 'Add Income';

  @override
  String get customPlus => 'Custom +';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get whatWasThisFor => 'What was this for?';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get noTransactionsOnDate => 'No transactions on this date';

  @override
  String get history => 'History';

  @override
  String get pastBudgets => 'Past Budgets';

  @override
  String get noPastBudgets => 'No past budgets.';

  @override
  String get pastSavingGoals => 'Past Saving Goals';

  @override
  String get noPastSavingsGoals => 'No past savings goals.';

  @override
  String get noNote => 'No note';

  @override
  String get enterValidAmount => 'Please enter a valid amount';
}
