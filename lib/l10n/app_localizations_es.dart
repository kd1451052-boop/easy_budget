// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get chooseLanguageDesc => 'Elige tu idioma preferido para empezar.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languageJapanese => 'Japonés';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get createAccount => 'Crear una cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get rememberMe => 'Recuérdame';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? Regístrate';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Iniciar sesión';

  @override
  String get enterEmailReset =>
      'Por favor, ingresa tu correo electrónico para restablecer la contraseña.';

  @override
  String get resetEmailSent =>
      'Correo electrónico de restablecimiento de contraseña enviado. Por favor, revisa tu bandeja de entrada.';

  @override
  String get failedResetEmail =>
      'Error al enviar el correo electrónico de restablecimiento de contraseña.';

  @override
  String get unexpectedError => 'Ocurrió un error inesperado.';

  @override
  String get authFailed =>
      'Autenticación fallida. Por favor, inténtalo de nuevo.';

  @override
  String get monthJan => 'Ene';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get expenseAnalytics => 'Análisis de gastos';

  @override
  String get totalSpent => 'Total gastado';

  @override
  String get noExpensesYet => '¡Aún no hay gastos!';

  @override
  String get recentTransactions => 'Transacciones recientes';

  @override
  String get yearly => 'Anual';

  @override
  String get monthly => 'Mensual';

  @override
  String get weekly => 'Semanal';

  @override
  String get income => 'Ingresos';

  @override
  String get expense => 'Gastos';

  @override
  String get noRecentTransactions => 'No hay transacciones recientes.';

  @override
  String budgetAlert(String budgetName) {
    return 'Alerta de presupuesto: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return 'Has gastado $currency$spent de tu límite de $currency$limit.';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return 'Ahorros atrasados: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return 'Solo has ahorrado $currency$saved de tu meta de $currency$limit.';
  }

  @override
  String get alertsInsights => 'Alertas y perspectivas';

  @override
  String get settings => 'Ajustes';

  @override
  String get preferences => 'Preferencias';

  @override
  String get currency => 'Moneda';

  @override
  String get language => 'Idioma';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get dataManagement => 'Gestión de datos';

  @override
  String get exportDataCSV => 'Exportar datos (CSV)';

  @override
  String get clearAllData => 'Borrar todos los datos';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get changesApplied => '¡Cambios aplicados con éxito!';

  @override
  String get editProfileName => 'Editar nombre de perfil';

  @override
  String get enterYourName => 'Ingresa tu nombre';

  @override
  String get confirmNameChange => 'Confirmar cambio de nombre';

  @override
  String confirmNameChangeDesc(String newName) {
    return '¿Estás seguro de que quieres cambiar el nombre de tu perfil a $newName?';
  }

  @override
  String get save => 'Guardar';

  @override
  String get selectCurrency => 'Seleccionar moneda';

  @override
  String get confirmCurrency => 'Confirmar moneda';

  @override
  String confirmCurrencyDesc(String currency) {
    return '¿Estás seguro de que quieres cambiar tu moneda predeterminada a $currency?';
  }

  @override
  String get confirmLanguage => 'Confirmar idioma';

  @override
  String confirmLanguageDesc(String lang) {
    return '¿Estás seguro de que quieres cambiar el idioma de la aplicación a $lang?';
  }

  @override
  String get exportData => 'Exportar datos';

  @override
  String get exportDataDesc =>
      '¿Estás seguro de que deseas generar y exportar todos tus datos de transacciones como un archivo CSV?';

  @override
  String get noDataToExport => '¡No hay datos para exportar!';

  @override
  String get clearAllDataPrompt => '¿Borrar todos los datos?';

  @override
  String get clearAllDataDesc =>
      '¿Estás absolutamente seguro? Esto eliminará permanentemente todas tus transacciones. Esta acción no se puede deshacer.';

  @override
  String get deleteAll => 'Borrar todo';

  @override
  String get allDataCleared => 'Todos los datos borrados con éxito';

  @override
  String get proMember => 'Miembro Pro';

  @override
  String get confirmThemeChange => 'Confirmar cambio de tema';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return '¿Estás seguro de que quieres $on_off el Modo Oscuro?';
  }

  @override
  String get on => 'activar';

  @override
  String get off => 'desactivar';

  @override
  String get budgetPageTitle => 'Presupuesto';

  @override
  String get activeBudgets => 'Presupuestos activos';

  @override
  String get addBudget => 'Añadir presupuesto';

  @override
  String get noActiveBudgets => 'No hay presupuestos activos.';

  @override
  String get savingGoals => 'Metas de ahorro';

  @override
  String get newSaving => 'Nuevo ahorro';

  @override
  String get noActiveSavings => 'No hay metas de ahorro activas.';

  @override
  String get budgetAndSavingHistory => 'Historial de presupuesto y ahorro';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount gastado';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount límite';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount ahorrado';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount meta';
  }

  @override
  String get newSavingGoal => 'Nueva meta de ahorro';

  @override
  String get goalName => 'Nombre de la meta';

  @override
  String get note => 'Nota';

  @override
  String get targetAmount => 'Cantidad objetivo';

  @override
  String get timeframe => 'Plazo';

  @override
  String get fixedDate => 'Fecha fija';

  @override
  String get period => 'Período';

  @override
  String get category => 'Categoría';

  @override
  String get saveGoal => 'Guardar meta';

  @override
  String get enterValidNameAndGoalAmount =>
      'Por favor ingresa un nombre válido y una cantidad objetivo';

  @override
  String get budgetName => 'Nombre del presupuesto';

  @override
  String get amountLimit => 'Límite de cantidad';

  @override
  String get saveBudget => 'Guardar presupuesto';

  @override
  String get enterValidNameAndAmount =>
      'Por favor ingresa un nombre y cantidad válidos';

  @override
  String get customizeCategory => 'Personalizar categoría';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get selectIcon => 'Seleccionar icono';

  @override
  String get saveCustomCategory => 'Guardar categoría';

  @override
  String get customExpenseLimitReached =>
      'Límite de gastos personalizados alcanzado (máx. 10).';

  @override
  String get customIncomeLimitReached =>
      'Límite de ingresos personalizados alcanzado (máx. 10).';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'Límite de gastos personalizados alcanzado (máx. 10). Por favor, elimina una categoría primero.';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'Límite de ingresos personalizados alcanzado (máx. 10). Por favor, elimina una categoría primero.';

  @override
  String get addExpense => 'Añadir gasto';

  @override
  String get addIncome => 'Añadir ingreso';

  @override
  String get customPlus => 'Personalizado +';

  @override
  String get dateTime => 'Fecha y hora';

  @override
  String get whatWasThisFor => '¿Para qué fue esto?';

  @override
  String get saveTransaction => 'Guardar transacción';

  @override
  String get transactionHistory => 'Historial de transacciones';

  @override
  String get noTransactionsOnDate => 'No hay transacciones en esta fecha';

  @override
  String get history => 'Historial';

  @override
  String get pastBudgets => 'Presupuestos pasados';

  @override
  String get noPastBudgets => 'No hay presupuestos pasados.';

  @override
  String get pastSavingGoals => 'Metas de ahorro pasadas';

  @override
  String get noPastSavingsGoals => 'No hay metas de ahorro pasadas.';

  @override
  String get noNote => 'Sin nota';

  @override
  String get enterValidAmount => 'Por favor ingresa una cantidad válida';
}
