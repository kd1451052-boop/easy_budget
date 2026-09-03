// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get chooseLanguageDesc => '시작하려면 선호하는 언어를 선택하세요.';

  @override
  String get continueButton => '계속하기';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageSpanish => '스페인어';

  @override
  String get languageFrench => '프랑스어';

  @override
  String get languageGerman => '독일어';

  @override
  String get languageJapanese => '일본어';

  @override
  String get languageKorean => '한국어';

  @override
  String get welcomeBack => '환영합니다';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get rememberMe => '로그인 유지';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get login => '로그인';

  @override
  String get signUp => '가입하기';

  @override
  String get dontHaveAccount => '계정이 없으신가요? 가입하기';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get enterEmailReset => '비밀번호를 재설정하려면 이메일을 입력하세요.';

  @override
  String get resetEmailSent => '비밀번호 재설정 이메일이 발송되었습니다. 받은 편지함을 확인하세요.';

  @override
  String get failedResetEmail => '비밀번호 재설정 이메일 전송에 실패했습니다.';

  @override
  String get unexpectedError => '예기치 않은 오류가 발생했습니다.';

  @override
  String get authFailed => '인증에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get monthJan => '1월';

  @override
  String get monthFeb => '2월';

  @override
  String get monthMar => '3월';

  @override
  String get monthApr => '4월';

  @override
  String get monthMay => '5월';

  @override
  String get monthJun => '6월';

  @override
  String get monthJul => '7월';

  @override
  String get monthAug => '8월';

  @override
  String get monthSep => '9월';

  @override
  String get monthOct => '10월';

  @override
  String get monthNov => '11월';

  @override
  String get monthDec => '12월';

  @override
  String get thisWeek => '이번 주';

  @override
  String get expenseAnalytics => '지출 분석';

  @override
  String get totalSpent => '총 지출';

  @override
  String get noExpensesYet => '아직 지출이 없습니다!';

  @override
  String get recentTransactions => '최근 거래';

  @override
  String get yearly => '매년';

  @override
  String get monthly => '매월';

  @override
  String get weekly => '매주';

  @override
  String get income => '수입';

  @override
  String get expense => '지출';

  @override
  String get noRecentTransactions => '최근 거래가 없습니다.';

  @override
  String budgetAlert(String budgetName) {
    return '예산 경고: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return '$currency$limit 한도 중 $currency$spent을 지출했습니다.';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return '저축 뒤처짐: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return '$currency$limit 목표 중 $currency$saved만 저축했습니다.';
  }

  @override
  String get alertsInsights => '경고 및 통찰력';

  @override
  String get settings => '설정';

  @override
  String get preferences => '환경설정';

  @override
  String get currency => '통화';

  @override
  String get language => '언어';

  @override
  String get darkMode => '다크 모드';

  @override
  String get dataManagement => '데이터 관리';

  @override
  String get exportDataCSV => '데이터 내보내기 (CSV)';

  @override
  String get clearAllData => '모든 데이터 지우기';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get changesApplied => '변경 사항이 성공적으로 적용되었습니다!';

  @override
  String get editProfileName => '프로필 이름 편집';

  @override
  String get enterYourName => '이름을 입력하세요';

  @override
  String get confirmNameChange => '이름 변경 확인';

  @override
  String confirmNameChangeDesc(String newName) {
    return '프로필 이름을 $newName(으)로 변경하시겠습니까?';
  }

  @override
  String get save => '저장';

  @override
  String get selectCurrency => '통화 선택';

  @override
  String get confirmCurrency => '통화 확인';

  @override
  String confirmCurrencyDesc(String currency) {
    return '기본 통화를 $currency(으)로 변경하시겠습니까?';
  }

  @override
  String get confirmLanguage => '언어 확인';

  @override
  String confirmLanguageDesc(String lang) {
    return '앱 언어를 $lang(으)로 변경하시겠습니까?';
  }

  @override
  String get exportData => '데이터 내보내기';

  @override
  String get exportDataDesc => '모든 거래 데이터를 CSV 파일로 생성하여 내보내시겠습니까?';

  @override
  String get noDataToExport => '내보낼 데이터가 없습니다!';

  @override
  String get clearAllDataPrompt => '모든 데이터를 지우시겠습니까?';

  @override
  String get clearAllDataDesc =>
      '정말 확실합니까? 이렇게 하면 모든 거래가 영구적으로 삭제됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get deleteAll => '모두 삭제';

  @override
  String get allDataCleared => '모든 데이터가 성공적으로 지워졌습니다';

  @override
  String get proMember => '프로 멤버';

  @override
  String get confirmThemeChange => '테마 변경 확인';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return '다크 모드를 $on_off로 하시겠습니까?';
  }

  @override
  String get on => '켜기';

  @override
  String get off => '끄기';

  @override
  String get budgetPageTitle => '예산';

  @override
  String get activeBudgets => '활성 예산';

  @override
  String get addBudget => '예산 추가';

  @override
  String get noActiveBudgets => '활성 예산이 없습니다.';

  @override
  String get savingGoals => '저축 목표';

  @override
  String get newSaving => '새 저축';

  @override
  String get noActiveSavings => '활성 저축 목표가 없습니다.';

  @override
  String get budgetAndSavingHistory => '예산 및 저축 내역';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount 지출';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount 한도';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount 저축됨';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount 목표';
  }

  @override
  String get newSavingGoal => '새로운 저축 목표';

  @override
  String get goalName => '목표 이름';

  @override
  String get note => '메모';

  @override
  String get targetAmount => '목표 금액';

  @override
  String get timeframe => '기간';

  @override
  String get fixedDate => '고정 날짜';

  @override
  String get period => '기간';

  @override
  String get category => '범주';

  @override
  String get saveGoal => '목표 저장';

  @override
  String get enterValidNameAndGoalAmount => '유효한 이름과 목표 금액을 입력하세요';

  @override
  String get budgetName => '예산 이름';

  @override
  String get amountLimit => '금액 한도';

  @override
  String get saveBudget => '예산 저장';

  @override
  String get enterValidNameAndAmount => '유효한 이름과 금액을 입력하세요';

  @override
  String get customizeCategory => '범주 사용자 지정';

  @override
  String get categoryName => '범주 이름';

  @override
  String get selectIcon => '아이콘 선택';

  @override
  String get saveCustomCategory => '범주 저장';

  @override
  String get customExpenseLimitReached => '맞춤 지출 한도에 도달했습니다(최대 10개).';

  @override
  String get customIncomeLimitReached => '맞춤 수입 한도에 도달했습니다(최대 10개).';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      '맞춤 지출 한도에 도달했습니다(최대 10개). 먼저 범주를 삭제하세요.';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      '맞춤 수입 한도에 도달했습니다(최대 10개). 먼저 범주를 삭제하세요.';

  @override
  String get addExpense => '지출 추가';

  @override
  String get addIncome => '수입 추가';

  @override
  String get customPlus => '맞춤 +';

  @override
  String get dateTime => '날짜 및 시간';

  @override
  String get whatWasThisFor => '이것은 무엇을 위한 것이었나요?';

  @override
  String get saveTransaction => '거래 저장';

  @override
  String get transactionHistory => '거래 내역';

  @override
  String get noTransactionsOnDate => '이 날짜의 거래 없음';

  @override
  String get history => '내역';

  @override
  String get pastBudgets => '과거 예산';

  @override
  String get noPastBudgets => '과거 예산이 없습니다.';

  @override
  String get pastSavingGoals => '과거 저축 목표';

  @override
  String get noPastSavingsGoals => '과거 저축 목표가 없습니다.';

  @override
  String get noNote => '메모 없음';

  @override
  String get enterValidAmount => '유효한 금액을 입력하세요';
}
