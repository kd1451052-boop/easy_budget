// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get chooseLanguageDesc => '始めるために希望の言語を選択してください。';

  @override
  String get continueButton => '次へ';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageSpanish => 'スペイン語';

  @override
  String get languageFrench => 'フランス語';

  @override
  String get languageGerman => 'ドイツ語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '韓国語';

  @override
  String get welcomeBack => 'お帰りなさい';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get rememberMe => 'ログイン状態を保持';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get login => 'ログイン';

  @override
  String get signUp => 'サインアップ';

  @override
  String get dontHaveAccount => 'アカウントをお持ちでないですか？ サインアップ';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？ ログイン';

  @override
  String get enterEmailReset => 'パスワードをリセットするためにメールアドレスを入力してください。';

  @override
  String get resetEmailSent => 'パスワードリセットのメールが送信されました。受信トレイを確認してください。';

  @override
  String get failedResetEmail => 'パスワードリセットメールの送信に失敗しました。';

  @override
  String get unexpectedError => '予期せぬエラーが発生しました。';

  @override
  String get authFailed => '認証に失敗しました。もう一度お試しください。';

  @override
  String get monthJan => '1月';

  @override
  String get monthFeb => '2月';

  @override
  String get monthMar => '3月';

  @override
  String get monthApr => '4月';

  @override
  String get monthMay => '5月';

  @override
  String get monthJun => '6月';

  @override
  String get monthJul => '7月';

  @override
  String get monthAug => '8月';

  @override
  String get monthSep => '9月';

  @override
  String get monthOct => '10月';

  @override
  String get monthNov => '11月';

  @override
  String get monthDec => '12月';

  @override
  String get thisWeek => '今週';

  @override
  String get expenseAnalytics => '支出分析';

  @override
  String get totalSpent => '合計支出';

  @override
  String get noExpensesYet => 'まだ支出はありません！';

  @override
  String get recentTransactions => '最近の取引';

  @override
  String get yearly => '毎年';

  @override
  String get monthly => '毎月';

  @override
  String get weekly => '毎週';

  @override
  String get income => '収入';

  @override
  String get expense => '支出';

  @override
  String get noRecentTransactions => '最近の取引はありません。';

  @override
  String budgetAlert(String budgetName) {
    return '予算アラート: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return '$currency$limitの制限のうち$currency$spentを費やしました。';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return '貯金が遅れています: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return '$currency$limitの目標のうち$currency$savedしか節約していません。';
  }

  @override
  String get alertsInsights => 'アラートとインサイト';

  @override
  String get settings => '設定';

  @override
  String get preferences => '環境設定';

  @override
  String get currency => '通貨';

  @override
  String get language => '言語';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get dataManagement => 'データ管理';

  @override
  String get exportDataCSV => 'データのエクスポート (CSV)';

  @override
  String get clearAllData => 'すべてのデータを消去';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get changesApplied => '変更が正常に適用されました！';

  @override
  String get editProfileName => 'プロファイル名の編集';

  @override
  String get enterYourName => '名前を入力';

  @override
  String get confirmNameChange => '名前の変更を確認';

  @override
  String confirmNameChangeDesc(String newName) {
    return 'プロファイル名を$newNameに変更してもよろしいですか？';
  }

  @override
  String get save => '保存';

  @override
  String get selectCurrency => '通貨を選択';

  @override
  String get confirmCurrency => '通貨の確認';

  @override
  String confirmCurrencyDesc(String currency) {
    return 'デフォルトの通貨を$currencyに変更してもよろしいですか？';
  }

  @override
  String get confirmLanguage => '言語の確認';

  @override
  String confirmLanguageDesc(String lang) {
    return 'アプリの言語を$langに変更してもよろしいですか？';
  }

  @override
  String get exportData => 'データのエクスポート';

  @override
  String get exportDataDesc => 'すべての取引データをCSVファイルとして生成し、エクスポートしてもよろしいですか？';

  @override
  String get noDataToExport => 'エクスポートするデータがありません！';

  @override
  String get clearAllDataPrompt => 'すべてのデータを消去しますか？';

  @override
  String get clearAllDataDesc =>
      '本当によろしいですか？これにより、すべての取引が永久に削除されます。この操作は元に戻せません。';

  @override
  String get deleteAll => 'すべて削除';

  @override
  String get allDataCleared => 'すべてのデータが正常に消去されました';

  @override
  String get proMember => 'プロメンバー';

  @override
  String get confirmThemeChange => 'テーマ変更の確認';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return 'ダークモードを$on_offにしてもよろしいですか？';
  }

  @override
  String get on => 'オン';

  @override
  String get off => 'オフ';

  @override
  String get budgetPageTitle => '予算';

  @override
  String get activeBudgets => 'アクティブな予算';

  @override
  String get addBudget => '予算を追加';

  @override
  String get noActiveBudgets => 'アクティブな予算はありません。';

  @override
  String get savingGoals => '貯金の目標';

  @override
  String get newSaving => '新しい貯金';

  @override
  String get noActiveSavings => 'アクティブな貯金目標はありません。';

  @override
  String get budgetAndSavingHistory => '予算と貯金の履歴';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount 支出済み';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount 制限';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount 貯金済み';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount 目標';
  }

  @override
  String get newSavingGoal => '新しい貯金目標';

  @override
  String get goalName => '目標名';

  @override
  String get note => 'メモ';

  @override
  String get targetAmount => '目標額';

  @override
  String get timeframe => '期間';

  @override
  String get fixedDate => '固定日';

  @override
  String get period => '期間';

  @override
  String get category => 'カテゴリー';

  @override
  String get saveGoal => '目標を保存';

  @override
  String get enterValidNameAndGoalAmount => '有効な名前と目標額を入力してください';

  @override
  String get budgetName => '予算名';

  @override
  String get amountLimit => '金額制限';

  @override
  String get saveBudget => '予算を保存';

  @override
  String get enterValidNameAndAmount => '有効な名前と金額を入力してください';

  @override
  String get customizeCategory => 'カテゴリーをカスタマイズ';

  @override
  String get categoryName => 'カテゴリー名';

  @override
  String get selectIcon => 'アイコンを選択';

  @override
  String get saveCustomCategory => 'カテゴリーを保存';

  @override
  String get customExpenseLimitReached => 'カスタム支出の制限に達しました（最大10）。';

  @override
  String get customIncomeLimitReached => 'カスタム収入の制限に達しました（最大10）。';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'カスタム支出の制限に達しました（最大10）。最初にカテゴリーを削除してください。';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'カスタム収入の制限に達しました（最大10）。最初にカテゴリーを削除してください。';

  @override
  String get addExpense => '支出を追加';

  @override
  String get addIncome => '収入を追加';

  @override
  String get customPlus => 'カスタム +';

  @override
  String get dateTime => '日付と時刻';

  @override
  String get whatWasThisFor => 'これは何のためでしたか？';

  @override
  String get saveTransaction => '取引を保存';

  @override
  String get transactionHistory => '取引履歴';

  @override
  String get noTransactionsOnDate => 'この日付の取引はありません';

  @override
  String get history => '履歴';

  @override
  String get pastBudgets => '過去の予算';

  @override
  String get noPastBudgets => '過去の予算はありません。';

  @override
  String get pastSavingGoals => '過去の貯金目標';

  @override
  String get noPastSavingsGoals => '過去の貯金目標はありません。';

  @override
  String get noNote => 'メモなし';

  @override
  String get enterValidAmount => '有効な金額を入力してください';

  @override
  String get categoryFood => '食費';

  @override
  String get categoryTransport => '交通費';

  @override
  String get categoryShopping => '買い物';

  @override
  String get categoryEntertainment => 'エンタメ';

  @override
  String get categoryUtilities => '光熱費';

  @override
  String get categoryHealth => '医療・健康';

  @override
  String get categoryOther => 'その他';

  @override
  String get categoryBill => '支払い';

  @override
  String get categoryRent => '家賃';

  @override
  String get categorySalary => '給与';

  @override
  String get categoryGift => 'お小遣い';

  @override
  String get categoryInvestment => '投資';

  @override
  String get categoryBonus => 'ボーナス';

  @override
  String get achTitleFirstStep => '最初の一歩';

  @override
  String get achDescFirstStep => '最初の取引を記録する。';

  @override
  String get achRewardBronzeStarter => 'アバターフレーム: ブロンズスターター';

  @override
  String get achTitleReceiptMaster => 'レシートマスター';

  @override
  String get achDescReceiptMaster => 'AIを使って10枚のレシートをスキャンする。';

  @override
  String get achRewardSilverScanner => 'アバターフレーム: シルバースキャナー';

  @override
  String get achTitleConsistency => '継続は力なり';

  @override
  String get achDescConsistency => '7日間の連続記録を達成する。';

  @override
  String get achRewardGoldenFlame => 'アバターフレーム: ゴールデンフレーム';

  @override
  String get reward => '報酬';

  @override
  String get scanWithCamera => 'カメラでスキャン';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String errorScanningReceipt(String error) {
    return 'レシートのスキャンエラー: $error';
  }

  @override
  String get scanResult => 'スキャン結果';

  @override
  String get merchant => '店舗';

  @override
  String get totalAmount => '合計金額';

  @override
  String get date => '日付';

  @override
  String get items => '商品:';

  @override
  String get unknownItem => '不明な商品';

  @override
  String get confirmAndSave => '確認して保存';

  @override
  String get retake => '再撮影';

  @override
  String get scanningReceipt => 'レシートをスキャン中...';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get useGallery => 'ギャラリーを使用';
}
