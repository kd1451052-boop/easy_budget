import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Easy Budget'**
  String get appTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @chooseLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language to get started.'**
  String get chooseLanguageDesc;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @enterEmailReset.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email to reset password.'**
  String get enterEmailReset;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Please check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @failedResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email.'**
  String get failedResetEmail;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @expenseAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Expense Analytics'**
  String get expenseAnalytics;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet!'**
  String get noExpensesYet;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get noRecentTransactions;

  /// No description provided for @budgetAlert.
  ///
  /// In en, this message translates to:
  /// **'Budget Alert: {budgetName}'**
  String budgetAlert(String budgetName);

  /// No description provided for @budgetSpentWarning.
  ///
  /// In en, this message translates to:
  /// **'You have spent {currency}{spent} of your {currency}{limit} limit.'**
  String budgetSpentWarning(String currency, String spent, String limit);

  /// No description provided for @savingsFallingBehind.
  ///
  /// In en, this message translates to:
  /// **'Savings Falling Behind: {goalName}'**
  String savingsFallingBehind(String goalName);

  /// No description provided for @savingsWarning.
  ///
  /// In en, this message translates to:
  /// **'You have only saved {currency}{saved} of your {currency}{limit} goal.'**
  String savingsWarning(String currency, String saved, String limit);

  /// No description provided for @alertsInsights.
  ///
  /// In en, this message translates to:
  /// **'Alerts & Insights'**
  String get alertsInsights;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportDataCSV.
  ///
  /// In en, this message translates to:
  /// **'Export Data (CSV)'**
  String get exportDataCSV;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @changesApplied.
  ///
  /// In en, this message translates to:
  /// **'Changes applied successfully!'**
  String get changesApplied;

  /// No description provided for @editProfileName.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Name'**
  String get editProfileName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @confirmNameChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Name Change'**
  String get confirmNameChange;

  /// No description provided for @confirmNameChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change your profile name to {newName}?'**
  String confirmNameChangeDesc(String newName);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @confirmCurrency.
  ///
  /// In en, this message translates to:
  /// **'Confirm Currency'**
  String get confirmCurrency;

  /// No description provided for @confirmCurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change your default currency to {currency}?'**
  String confirmCurrencyDesc(String currency);

  /// No description provided for @confirmLanguage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Language'**
  String get confirmLanguage;

  /// No description provided for @confirmLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the app language to {lang}?'**
  String confirmLanguageDesc(String lang);

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to generate and export all your transaction data as a CSV file?'**
  String get exportDataDesc;

  /// No description provided for @noDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export!'**
  String get noDataToExport;

  /// No description provided for @clearAllDataPrompt.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataPrompt;

  /// No description provided for @clearAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure? This will permanently delete all your transactions. This action cannot be undone.'**
  String get clearAllDataDesc;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared successfully'**
  String get allDataCleared;

  /// No description provided for @proMember.
  ///
  /// In en, this message translates to:
  /// **'Pro Member'**
  String get proMember;

  /// No description provided for @confirmThemeChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Theme Change'**
  String get confirmThemeChange;

  /// No description provided for @confirmThemeChangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to turn {on_off} Dark Mode?'**
  String confirmThemeChangeDesc(String on_off);

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @budgetPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetPageTitle;

  /// No description provided for @activeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Active Budgets'**
  String get activeBudgets;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get addBudget;

  /// No description provided for @noActiveBudgets.
  ///
  /// In en, this message translates to:
  /// **'No active budgets.'**
  String get noActiveBudgets;

  /// No description provided for @savingGoals.
  ///
  /// In en, this message translates to:
  /// **'Saving Goals'**
  String get savingGoals;

  /// No description provided for @newSaving.
  ///
  /// In en, this message translates to:
  /// **'New Saving'**
  String get newSaving;

  /// No description provided for @noActiveSavings.
  ///
  /// In en, this message translates to:
  /// **'No active savings goals.'**
  String get noActiveSavings;

  /// No description provided for @budgetAndSavingHistory.
  ///
  /// In en, this message translates to:
  /// **'Budget and Saving History'**
  String get budgetAndSavingHistory;

  /// No description provided for @spentText.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount} spent'**
  String spentText(String currency, String amount);

  /// No description provided for @limitText.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount} limit'**
  String limitText(String currency, String amount);

  /// No description provided for @savedText.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount} saved'**
  String savedText(String currency, String amount);

  /// No description provided for @goalText.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount} goal'**
  String goalText(String currency, String amount);

  /// No description provided for @newSavingGoal.
  ///
  /// In en, this message translates to:
  /// **'New Saving Goal'**
  String get newSavingGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goalName;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get targetAmount;

  /// No description provided for @timeframe.
  ///
  /// In en, this message translates to:
  /// **'Timeframe'**
  String get timeframe;

  /// No description provided for @fixedDate.
  ///
  /// In en, this message translates to:
  /// **'Fixed Date'**
  String get fixedDate;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// No description provided for @enterValidNameAndGoalAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name and goal amount'**
  String get enterValidNameAndGoalAmount;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budgetName;

  /// No description provided for @amountLimit.
  ///
  /// In en, this message translates to:
  /// **'Amount Limit'**
  String get amountLimit;

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save Budget'**
  String get saveBudget;

  /// No description provided for @enterValidNameAndAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name and amount'**
  String get enterValidNameAndAmount;

  /// No description provided for @customizeCategory.
  ///
  /// In en, this message translates to:
  /// **'Customize Category'**
  String get customizeCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @saveCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Save Custom Category'**
  String get saveCustomCategory;

  /// No description provided for @customExpenseLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Custom expense limit reached (10 max).'**
  String get customExpenseLimitReached;

  /// No description provided for @customIncomeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Custom income limit reached (10 max).'**
  String get customIncomeLimitReached;

  /// No description provided for @customExpenseLimitReachedDeleteFirst.
  ///
  /// In en, this message translates to:
  /// **'Custom expense limit reached (10 max). Please delete a category first.'**
  String get customExpenseLimitReachedDeleteFirst;

  /// No description provided for @customIncomeLimitReachedDeleteFirst.
  ///
  /// In en, this message translates to:
  /// **'Custom income limit reached (10 max). Please delete a category first.'**
  String get customIncomeLimitReachedDeleteFirst;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @customPlus.
  ///
  /// In en, this message translates to:
  /// **'Custom +'**
  String get customPlus;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @whatWasThisFor.
  ///
  /// In en, this message translates to:
  /// **'What was this for?'**
  String get whatWasThisFor;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactionsOnDate.
  ///
  /// In en, this message translates to:
  /// **'No transactions on this date'**
  String get noTransactionsOnDate;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @pastBudgets.
  ///
  /// In en, this message translates to:
  /// **'Past Budgets'**
  String get pastBudgets;

  /// No description provided for @noPastBudgets.
  ///
  /// In en, this message translates to:
  /// **'No past budgets.'**
  String get noPastBudgets;

  /// No description provided for @pastSavingGoals.
  ///
  /// In en, this message translates to:
  /// **'Past Saving Goals'**
  String get pastSavingGoals;

  /// No description provided for @noPastSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'No past savings goals.'**
  String get noPastSavingsGoals;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get categoryBill;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get categoryGift;

  /// No description provided for @categoryInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get categoryInvestment;

  /// No description provided for @categoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get categoryBonus;

  /// No description provided for @achTitleFirstStep.
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get achTitleFirstStep;

  /// No description provided for @achDescFirstStep.
  ///
  /// In en, this message translates to:
  /// **'Log your very first transaction.'**
  String get achDescFirstStep;

  /// No description provided for @achRewardBronzeStarter.
  ///
  /// In en, this message translates to:
  /// **'Avatar Frame: Bronze Starter'**
  String get achRewardBronzeStarter;

  /// No description provided for @achTitleReceiptMaster.
  ///
  /// In en, this message translates to:
  /// **'Receipt Master'**
  String get achTitleReceiptMaster;

  /// No description provided for @achDescReceiptMaster.
  ///
  /// In en, this message translates to:
  /// **'Scan 10 receipts using AI.'**
  String get achDescReceiptMaster;

  /// No description provided for @achRewardSilverScanner.
  ///
  /// In en, this message translates to:
  /// **'Avatar Frame: Silver Scanner'**
  String get achRewardSilverScanner;

  /// No description provided for @achTitleConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency is Key'**
  String get achTitleConsistency;

  /// No description provided for @achDescConsistency.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day streak.'**
  String get achDescConsistency;

  /// No description provided for @achRewardGoldenFlame.
  ///
  /// In en, this message translates to:
  /// **'Avatar Frame: Golden Flame'**
  String get achRewardGoldenFlame;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @scanWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with Camera'**
  String get scanWithCamera;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @errorScanningReceipt.
  ///
  /// In en, this message translates to:
  /// **'Error scanning receipt: {error}'**
  String errorScanningReceipt(String error);

  /// No description provided for @scanResult.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get scanResult;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get items;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown item'**
  String get unknownItem;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save'**
  String get confirmAndSave;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @scanningReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scanning Receipt...'**
  String get scanningReceipt;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @useGallery.
  ///
  /// In en, this message translates to:
  /// **'Use Gallery'**
  String get useGallery;

  /// No description provided for @merchantShopName.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Shop name'**
  String get merchantShopName;

  /// No description provided for @merchantHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Walmart, Starbucks'**
  String get merchantHint;

  /// No description provided for @itemsOptional.
  ///
  /// In en, this message translates to:
  /// **'Items (optional)'**
  String get itemsOptional;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameHint;

  /// No description provided for @itemPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get itemPriceHint;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
