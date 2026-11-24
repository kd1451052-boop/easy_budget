// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => 'ဘာသာစကား ရွေးချယ်ပါ';

  @override
  String get chooseLanguageDesc =>
      'စတင်အသုံးပြုရန် သင်နှစ်သက်ရာ ဘာသာစကားကို ရွေးချယ်ပါ။';

  @override
  String get continueButton => 'ဆက်သွားမည်';

  @override
  String get languageEnglish => 'အင်္ဂလိပ် (English)';

  @override
  String get languageSpanish => 'စပိန် (Spanish)';

  @override
  String get languageFrench => 'ပြင်သစ် (French)';

  @override
  String get languageGerman => 'ဂျာမန် (German)';

  @override
  String get languageJapanese => 'ဂျပန် (日本語)';

  @override
  String get languageKorean => 'ကိုရီးယား (Korean)';

  @override
  String get languageMyanmar => 'မြန်မာ (Burmese)';

  @override
  String get welcomeBack => 'ပြန်လည်ကြိုဆိုပါတယ်';

  @override
  String get createAccount => 'အကောင့်အသစ်ပြုလုပ်ရန်';

  @override
  String get email => 'အီးမေးလ်';

  @override
  String get password => 'စကားဝှက်';

  @override
  String get rememberMe => 'အကောင့်မှတ်ထားမည်';

  @override
  String get forgotPassword => 'စကားဝှက် မေ့နေပါသလား?';

  @override
  String get login => 'အကောင့်ဝင်မည်';

  @override
  String get signUp => 'အကောင့်ဖွင့်မည်';

  @override
  String get dontHaveAccount => 'အကောင့်မရှိသေးဘူးလား? အကောင့်ဖွင့်ပါ';

  @override
  String get alreadyHaveAccount => 'အကောင့်ရှိပြီးသားလား? အကောင့်ဝင်ပါ';

  @override
  String get enterEmailReset =>
      'စကားဝှက်ပြန်လည်သတ်မှတ်ရန် သင့်အီးမေးလ်ကို ထည့်သွင်းပါ။';

  @override
  String get resetEmailSent =>
      'စကားဝှက်ပြန်လည်သတ်မှတ်ရန် အီးမေးလ်ပို့ပြီးပါပြီ။ သင့်အီးမေးလ်ကို စစ်ဆေးပါ။';

  @override
  String get failedResetEmail =>
      'စကားဝှက်ပြန်လည်သတ်မှတ်သည့် အီးမေးလ်ပေးပို့ခြင်း မအောင်မြင်ပါ။';

  @override
  String get unexpectedError => 'မမျှော်လင့်ထားသော အမှားတစ်ခု ဖြစ်ပွားခဲ့သည်။';

  @override
  String get authFailed =>
      'အထောက်အထားစစ်ဆေးခြင်း မအောင်မြင်ပါ။ ထပ်မံကြိုးစားပါ။';

  @override
  String get monthJan => 'ဇန်နဝါရီ';

  @override
  String get monthFeb => 'ဖေဖော်ဝါရီ';

  @override
  String get monthMar => 'မတ်';

  @override
  String get monthApr => 'ဧပြီ';

  @override
  String get monthMay => 'မေ';

  @override
  String get monthJun => 'ဇွန်';

  @override
  String get monthJul => 'ဇူလိုင်';

  @override
  String get monthAug => 'ဩဂုတ်';

  @override
  String get monthSep => 'စက်တင်ဘာ';

  @override
  String get monthOct => 'အောက်တိုဘာ';

  @override
  String get monthNov => 'နိုဝင်ဘာ';

  @override
  String get monthDec => 'ဒီဇင်ဘာ';

  @override
  String get thisWeek => 'ယခုအပတ်';

  @override
  String get expenseAnalytics => 'အသုံးစရိတ် သုံးသပ်ချက်';

  @override
  String get noExpensesYet => 'အသုံးစရိတ် မရှိသေးပါ!';

  @override
  String get yearly => 'နှစ်စဉ်';

  @override
  String get monthly => 'လစဉ်';

  @override
  String get weekly => 'အပတ်စဉ်';

  @override
  String get income => 'ဝင်ငွေ';

  @override
  String get expense => 'ထွက်ငွေ';

  @override
  String budgetAlert(String budgetName) {
    return 'ဘတ်ဂျက် သတိပေးချက်: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return 'သတ်မှတ်ထားသော $currency$limit အနက် $currency$spent ကို သုံးစွဲထားပါသည်။';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return 'စုငွေ နောက်ကျနေပါသည်: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return 'ရည်မှန်းချက် $currency$limit အနက် $currency$saved သာ စုဆောင်းမိသေးသည်။';
  }

  @override
  String get alertsInsights => 'သတိပေးချက်နှင့် သုံးသပ်ချက်များ';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get preferences => 'ဦးစားပေး 설정များ';

  @override
  String get currency => 'ငွေကြေး';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get darkMode => 'အမှောင်မုဒ်';

  @override
  String get dataManagement => 'ဒေတာ စီမံခန့်ခွဲမှု';

  @override
  String get exportDataCSV => 'ဒေတာထုတ်ယူရန် (CSV)';

  @override
  String get clearAllData => 'ဒေတာအားလုံး ဖျက်ရန်';

  @override
  String get cancel => 'မလုပ်တော့ပါ';

  @override
  String get confirm => 'အတည်ပြုမည်';

  @override
  String get changesApplied =>
      'ပြောင်းလဲမှုများကို အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ!';

  @override
  String get enterYourName => 'သင့်အမည် ထည့်ပါ';

  @override
  String get save => 'သိမ်းမည်';

  @override
  String get selectCurrency => 'ငွေကြေး ရွေးချယ်ပါ';

  @override
  String get confirmCurrency => 'ငွေကြေး အတည်ပြုပါ';

  @override
  String confirmCurrencyDesc(String currency) {
    return 'သင်၏ ပုံသေငွေကြေးကို $currency သို့ ပြောင်းလဲရန် သေချာပါသလား?';
  }

  @override
  String get confirmLanguage => 'ဘာသာစကား အတည်ပြုပါ';

  @override
  String confirmLanguageDesc(String lang) {
    return 'အက်ပ်ဘာသာစကားကို $lang သို့ ပြောင်းလဲရန် သေချာပါသလား?';
  }

  @override
  String get exportData => 'ဒေတာ ထုတ်ယူရန်';

  @override
  String get exportDataDesc =>
      'သင်၏ ငွေစာရင်းဒေတာအားလုံးကို CSV ဖိုင်အဖြစ် ထုတ်ယူရန် သေချာပါသလား?';

  @override
  String get noDataToExport => 'ထုတ်ယူရန် ဒေတာမရှိပါ!';

  @override
  String get clearAllDataPrompt => 'ဒေတာအားလုံးကို ဖျက်မည်လား?';

  @override
  String get clearAllDataDesc =>
      'သေချာပါသလား? ဤလုပ်ဆောင်ချက်သည် သင်၏ ငွေစာရင်းမှတ်တမ်းအားလုံးကို အပြီးတိုင် ဖျက်ပစ်ပါမည်။ ပြန်လည်ရယူနိုင်မည် မဟုတ်ပါ။';

  @override
  String get deleteAll => 'အားလုံးဖျက်မည်';

  @override
  String get allDataCleared => 'ဒေတာအားလုံးကို အောင်မြင်စွာ ဖျက်ပြီးပါပြီ';

  @override
  String get proMember => 'ပရိုမန်ဘာ';

  @override
  String get budgetPageTitle => 'ဘတ်ဂျက်';

  @override
  String get activeBudgets => 'လက်ရှိ ဘတ်ဂျက်များ';

  @override
  String get addBudget => 'ဘတ်ဂျက်အသစ်ထည့်ရန်';

  @override
  String get noActiveBudgets => 'လက်ရှိ ဘတ်ဂျက် မရှိပါ။';

  @override
  String get savingGoals => 'စုငွေ ရည်မှန်းချက်များ';

  @override
  String get newSaving => 'စုငွေအသစ်';

  @override
  String get noActiveSavings => 'လက်ရှိ စုငွေရည်မှန်းချက် မရှိပါ။';

  @override
  String get budgetAndSavingHistory => 'ဘတ်ဂျက်နှင့် စုငွေ မှတ်တမ်း';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount သုံးစွဲပြီး';
  }

  @override
  String limitText(String currency, String amount) {
    return 'ကန့်သတ်ချက် $currency$amount';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount စုဆောင်းပြီး';
  }

  @override
  String goalText(String currency, String amount) {
    return 'ရည်မှန်းချက် $currency$amount';
  }

  @override
  String get newSavingGoal => 'စုငွေ ရည်မှန်းချက်အသစ်';

  @override
  String get goalName => 'ရည်မှန်းချက် အမည်';

  @override
  String get note => 'မှတ်စု';

  @override
  String get targetAmount => 'ရည်မှန်းချက် ပမာဏ';

  @override
  String get timeframe => 'အချိန်ကာလ';

  @override
  String get fixedDate => 'သတ်မှတ်ရက်';

  @override
  String get period => 'ကာလအပိုင်းအခြား';

  @override
  String get category => 'အမျိုးအစား';

  @override
  String get saveGoal => 'ရည်မှန်းချက် သိမ်းမည်';

  @override
  String get enterValidNameAndGoalAmount =>
      'ကျေးဇူးပြု၍ မှန်ကန်သော အမည်နှင့် ပမာဏကို ထည့်သွင်းပါ';

  @override
  String get budgetName => 'ဘတ်ဂျက် အမည်';

  @override
  String get amountLimit => 'သုံးစွဲမည့် ပမာဏကန့်သတ်ချက်';

  @override
  String get saveBudget => 'ဘတ်ဂျက် သိမ်းမည်';

  @override
  String get enterValidNameAndAmount =>
      'ကျေးဇူးပြု၍ မှန်ကန်သော အမည်နှင့် ပမာဏကို ထည့်သွင်းပါ';

  @override
  String get customizeCategory => 'အမျိုးအစား စိတ်ကြိုက်ပြင်ဆင်ရန်';

  @override
  String get categoryName => 'အမျိုးအစား အမည်';

  @override
  String get selectIcon => 'အိုင်ကွန် ရွေးချယ်ပါ';

  @override
  String get saveCustomCategory => 'အမျိုးအစား သိမ်းမည်';

  @override
  String get customExpenseLimitReached =>
      'စိတ်ကြိုက် ထွက်ငွေအမျိုးအစား အများဆုံး (၁၀ ခု) ပြည့်သွားပါပြီ။';

  @override
  String get customIncomeLimitReached =>
      'စိတ်ကြိုက် ဝင်ငွေအမျိုးအစား အများဆုံး (၁၀ ခု) ပြည့်သွားပါပြီ။';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'စိတ်ကြိုက် ထွက်ငွေအမျိုးအစား အများဆုံး (၁၀ ခု) ပြည့်သွားပါပြီ။ ကျေးဇူးပြု၍ တစ်ခုအရင်ဖျက်ပါ။';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'စိတ်ကြိုက် ဝင်ငွေအမျိုးအစား အများဆုံး (၁၀ ခု) ပြည့်သွားပါပြီ။ ကျေးဇူးပြု၍ တစ်ခုအရင်ဖျက်ပါ။';

  @override
  String get addExpense => 'ထွက်ငွေ ထည့်ရန်';

  @override
  String get addIncome => 'ဝင်ငွေ ထည့်ရန်';

  @override
  String get customPlus => 'စိတ်ကြိုက် +';

  @override
  String get dateTime => 'ရက်စွဲနှင့် အချိန်';

  @override
  String get whatWasThisFor => 'ဘာအတွက် သုံးစွဲခဲ့သလဲ?';

  @override
  String get saveTransaction => 'စာရင်း သိမ်းမည်';

  @override
  String get transactionHistory => 'ငွေစာရင်း မှတ်တမ်း';

  @override
  String get noTransactionsOnDate => 'ဤရက်စွဲတွင် ငွေစာရင်းမှတ်တမ်း မရှိပါ';

  @override
  String get history => 'မှတ်တမ်း';

  @override
  String get pastBudgets => 'ယခင် ဘတ်ဂျက်များ';

  @override
  String get noPastBudgets => 'ယခင် ဘတ်ဂျက်များ မရှိပါ။';

  @override
  String get pastSavingGoals => 'ယခင် စုငွေရည်မှန်းချက်များ';

  @override
  String get noPastSavingsGoals => 'ယခင် စုငွေရည်မှန်းချက်များ မရှိပါ။';

  @override
  String get noNote => 'မှတ်စု မရှိပါ';

  @override
  String get enterValidAmount => 'ကျေးဇူးပြု၍ မှန်ကန်သော ပမာဏကို ထည့်သွင်းပါ';

  @override
  String get categoryFood => 'အစားအသောက်';

  @override
  String get categoryTransport => 'သယ်ယူပို့ဆောင်ရေး';

  @override
  String get categoryShopping => 'ဈေးဝယ်';

  @override
  String get categoryEntertainment => 'ဖျော်ဖြေရေး';

  @override
  String get categoryUtilities => 'မီတာနှင့် ဝန်ဆောင်ခ';

  @override
  String get categoryHealth => 'ကျန်းမာရေး';

  @override
  String get categoryOther => 'အခြား';

  @override
  String get categoryBill => 'ဘေလ်';

  @override
  String get categoryRent => 'အိမ်လခ';

  @override
  String get categorySalary => 'လစာ';

  @override
  String get categoryGift => 'လက်ဆောင်';

  @override
  String get categoryInvestment => 'ရင်းနှီးမြှုပ်နှံမှု';

  @override
  String get categoryBonus => 'ဘောနပ်စ်';

  @override
  String get achTitleFirstStep => 'ပထမဆုံး ခြေလှမ်း';

  @override
  String get achDescFirstStep => 'သင်၏ ပထမဆုံး ငွေစာရင်းကို မှတ်တမ်းတင်ပါ။';

  @override
  String get achRewardBronzeStarter => 'ပရိုဖိုင်ဘောင်: ကြေးနီရောင် အစပြုသူ';

  @override
  String get achTitleReceiptMaster => 'ဘောင်ချာ မာစတာ';

  @override
  String get achDescReceiptMaster => 'AI ဖြင့် ဘောင်ချာ ၁၀ စောင်ကို စကန်ဖတ်ပါ။';

  @override
  String get achRewardSilverScanner => 'ပရိုဖိုင်ဘောင်: ငွေရောင် စကန်နာ';

  @override
  String get achTitleConsistency => 'ဇွဲရှိမှုသည် အဓိက';

  @override
  String get achDescConsistency => '၇ ရက်ဆက်တိုက် မှတ်တမ်းတင်မှု ပြည့်မီပါစေ။';

  @override
  String get achRewardGoldenFlame => 'ပရိုဖိုင်ဘောင်: ရွှေရောင် မီးတောက်';

  @override
  String get reward => 'ဆုလာဘ်';

  @override
  String get scanWithCamera => 'ကင်မရာဖြင့် စကန်ဖတ်မည်';

  @override
  String get chooseFromGallery => 'ဖုန်းထဲမှ ပုံရွေးမည်';

  @override
  String errorScanningReceipt(String error) {
    return 'ဘောင်ချာ စကန်ဖတ်ရာတွင် အမှားဖြစ်ပွားသည်: $error';
  }

  @override
  String get scanResult => 'စကန်ဖတ်ထားသော ရလဒ်';

  @override
  String get merchant => 'ဆိုင်အမည်';

  @override
  String get totalAmount => 'စုစုပေါင်း ပမာဏ';

  @override
  String get date => 'ရက်စွဲ';

  @override
  String get items => 'ပစ္စည်းများ:';

  @override
  String get unknownItem => 'အမည်မသိ ပစ္စည်း';

  @override
  String get confirmAndSave => 'အတည်ပြုပြီး သိမ်းမည်';

  @override
  String get retake => 'ပြန်ရိုက်မည်';

  @override
  String get scanningReceipt => 'ဘောင်ချာကို စကန်ဖတ်နေသည်...';

  @override
  String get takePhoto => 'ဓာတ်ပုံရိုက်မည်';

  @override
  String get useGallery => 'ပုံရွေးချယ်မည်';

  @override
  String get merchantShopName => 'ဆိုင် / လုပ်ငန်းအမည်';

  @override
  String get merchantHint => 'ဥပမာ - City Mart, Starbucks';

  @override
  String get itemsOptional => 'ပစ္စည်းများ (ထည့်လိုက ထည့်ရန်)';

  @override
  String get itemNameHint => 'ပစ္စည်းအမည်';

  @override
  String get itemPriceHint => 'ဈေးနှုန်း';

  @override
  String get addItem => 'ပစ္စည်းထပ်ထည့်ရန်';

  @override
  String get dailyStreak => 'နေ့စဉ် ဆက်တိုက်မှတ်တမ်း';

  @override
  String streakDaysCount(int count) {
    return '$count ရက်';
  }

  @override
  String dayStreakBanner(int count) {
    return '$count ရက် ဆက်တိုက်!';
  }

  @override
  String get achievementsAndBadges => 'အောင်မြင်မှုများနှင့် တံဆိပ်များ';

  @override
  String get backupDataZip => 'ဒေတာ အရန်သိမ်းရန် (ZIP)';

  @override
  String get backupDataTitle => 'ဒေတာ အရန်သိမ်းရန်';

  @override
  String get backupDataConfirmDesc =>
      'သင်၏ ဒေတာအားလုံးကို အရန်သိမ်းဆည်းရန် သေချာပါသလား? ဖိုင်ကို သင့်စက်ထဲတွင် သိမ်းဆည်းပေးပါမည်။';

  @override
  String get noDataToBackup => 'အရန်သိမ်းရန် ဒေတာမရှိပါ!';

  @override
  String get backupSuccessful => 'အရန်သိမ်းဆည်းမှု အောင်မြင်ပါသည်';

  @override
  String backupSavedTo(String path) {
    return 'သင်၏ အရန်သိမ်းဖိုင်ကို အောက်ပါနေရာတွင် သိမ်းဆည်းပြီးပါပြီ:\n\n$path';
  }

  @override
  String get shareExport => 'မျှဝေရန် / ထုတ်ယူရန်';

  @override
  String get accountSection => 'အကောင့်';

  @override
  String get switchAccount => 'အကောင့် ပြောင်းရန်';

  @override
  String get switchAccountConfirmDesc => 'အကောင့်ပြောင်းလဲရန် သေချာပါသလား?';

  @override
  String get loginAccountConfirmDesc => 'အကောင့်ဝင်ရောက်ရန် သေချာပါသလား?';

  @override
  String get logOut => 'အကောင့်မှ ထွက်ရန်';

  @override
  String get logOutConfirmDesc => 'အကောင့်မှ ထွက်ရန် သေချာပါသလား?';

  @override
  String get calendarMonth => 'လ';

  @override
  String get calendarTwoWeeks => '၂ ပတ်';

  @override
  String get calendarWeek => '၁ ပတ်';

  @override
  String get addTransaction => 'စာရင်းအသစ်ထည့်ရန်';

  @override
  String get tapToAdd => 'ထည့်သွင်းရန် နှိပ်ပါ';

  @override
  String otherTransactionsInPeriod(String period) {
    return '$period အတွင်း အခြားငွေစာရင်းများ';
  }

  @override
  String get deleteTransactionConfirm => 'ဤငွေစာရင်းကို ဖျက်ရန် သေချာပါသလား?';

  @override
  String get transactionDeleted => 'ငွေစာရင်းကို ဖျက်ပြီးပါပြီ။';

  @override
  String get delete => 'ဖျက်မည်';

  @override
  String get incomeVsExpense => 'ဝင်ငွေ နှင့် ထွက်ငွေ';

  @override
  String daysLeftCount(int count) {
    return '$count ရက် ကျန်သေးသည်';
  }

  @override
  String get goalReached => 'ရည်မှန်းချက် ပြည့်မီပါပြီ!';

  @override
  String savedSoFar(String amount) {
    return 'လက်ရှိ စုဆောင်းမိငွေ: $amount';
  }

  @override
  String extraDaysNegativeBalance(int count) {
    return 'လက်ကျန်ငွေ အနုတ်ပြနေသဖြင့် +$count ရက် ထပ်တိုးထားသည်';
  }

  @override
  String get timeOptional => 'အချိန် (ထည့်လိုက ထည့်ရန်)';

  @override
  String get optionalHint => 'ချန်လှပ်နိုင်သည်';

  @override
  String get continueAsGuest => 'ဧည့်သည်အဖြစ် ဆက်သွားမည်';

  @override
  String get editProfile => 'ပရိုဖိုင် ပြင်ဆင်ရန်';

  @override
  String get nameLabel => 'အမည်';

  @override
  String get profileFrame => 'ပရိုဖိုင်ဘောင်';

  @override
  String get expired => 'သက်တမ်းကုန်ဆုံးပြီ';

  @override
  String get equipFrame => 'ဘောင် တပ်ဆင်မည်';

  @override
  String get equipped => 'တပ်ဆင်ထားသည်';
}
