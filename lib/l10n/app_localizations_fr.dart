// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Easy Budget';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get chooseLanguageDesc =>
      'Choisissez votre langue préférée pour commencer.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageJapanese => 'Japonais';

  @override
  String get languageKorean => 'Coréen';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'S\'\'inscrire';

  @override
  String get dontHaveAccount => 'Vous n\'\'avez pas de compte ? S\'\'inscrire';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? Connexion';

  @override
  String get enterEmailReset =>
      'Veuillez saisir votre e-mail pour réinitialiser le mot de passe.';

  @override
  String get resetEmailSent =>
      'E-mail de réinitialisation du mot de passe envoyé. Veuillez vérifier votre boîte de réception.';

  @override
  String get failedResetEmail =>
      'Échec de l\'\'envoi de l\'\'e-mail de réinitialisation du mot de passe.';

  @override
  String get unexpectedError => 'Une erreur inattendue s\'\'est produite.';

  @override
  String get authFailed =>
      'L\'\'authentification a échoué. Veuillez réessayer.';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Fév';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Avr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juil';

  @override
  String get monthAug => 'Aoû';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Déc';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get expenseAnalytics => 'Analyse des dépenses';

  @override
  String get totalSpent => 'Total dépensé';

  @override
  String get noExpensesYet => 'Aucune dépense pour le moment!';

  @override
  String get recentTransactions => 'Transactions récentes';

  @override
  String get yearly => 'Annuel';

  @override
  String get monthly => 'Mensuel';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get income => 'Revenus';

  @override
  String get expense => 'Dépenses';

  @override
  String get noRecentTransactions => 'Aucune transaction récente.';

  @override
  String budgetAlert(String budgetName) {
    return 'Alerte de budget: $budgetName';
  }

  @override
  String budgetSpentWarning(String currency, String spent, String limit) {
    return 'Vous avez dépensé $currency$spent sur votre limite de $currency$limit.';
  }

  @override
  String savingsFallingBehind(String goalName) {
    return 'Épargne en retard: $goalName';
  }

  @override
  String savingsWarning(String currency, String saved, String limit) {
    return 'Vous n\'\'avez économisé que $currency$saved sur votre objectif de $currency$limit.';
  }

  @override
  String get alertsInsights => 'Alertes et aperçus';

  @override
  String get settings => 'Paramètres';

  @override
  String get preferences => 'Préférences';

  @override
  String get currency => 'Devise';

  @override
  String get language => 'Langue';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get dataManagement => 'Gestion des données';

  @override
  String get exportDataCSV => 'Exporter les données (CSV)';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get changesApplied => 'Modifications appliquées avec succès !';

  @override
  String get editProfileName => 'Modifier le nom du profil';

  @override
  String get enterYourName => 'Entrez votre nom';

  @override
  String get confirmNameChange => 'Confirmer le changement de nom';

  @override
  String confirmNameChangeDesc(String newName) {
    return 'Êtes-vous sûr de vouloir changer le nom de votre profil en $newName ?';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get selectCurrency => 'Sélectionner la devise';

  @override
  String get confirmCurrency => 'Confirmer la devise';

  @override
  String confirmCurrencyDesc(String currency) {
    return 'Êtes-vous sûr de vouloir changer votre devise par défaut en $currency ?';
  }

  @override
  String get confirmLanguage => 'Confirmer la langue';

  @override
  String confirmLanguageDesc(String lang) {
    return 'Êtes-vous sûr de vouloir changer la langue de l\'\'application en $lang ?';
  }

  @override
  String get exportData => 'Exporter les données';

  @override
  String get exportDataDesc =>
      'Êtes-vous sûr de vouloir générer et exporter toutes vos données de transaction sous forme de fichier CSV ?';

  @override
  String get noDataToExport => 'Aucune donnée à exporter !';

  @override
  String get clearAllDataPrompt => 'Effacer toutes les données ?';

  @override
  String get clearAllDataDesc =>
      'Êtes-vous absolument sûr ? Cela supprimera définitivement toutes vos transactions. Cette action est irréversible.';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get allDataCleared =>
      'Toutes les données ont été effacées avec succès';

  @override
  String get proMember => 'Membre Pro';

  @override
  String get confirmThemeChange => 'Confirmer le changement de thème';

  @override
  String confirmThemeChangeDesc(String on_off) {
    return 'Êtes-vous sûr de vouloir $on_off le mode sombre ?';
  }

  @override
  String get on => 'activer';

  @override
  String get off => 'désactiver';

  @override
  String get budgetPageTitle => 'Budget';

  @override
  String get activeBudgets => 'Budgets actifs';

  @override
  String get addBudget => 'Ajouter un budget';

  @override
  String get noActiveBudgets => 'Aucun budget actif.';

  @override
  String get savingGoals => 'Objectifs d\'\'épargne';

  @override
  String get newSaving => 'Nouvelle épargne';

  @override
  String get noActiveSavings => 'Aucun objectif d\'\'épargne actif.';

  @override
  String get budgetAndSavingHistory => 'Historique de budget et d\'\'épargne';

  @override
  String spentText(String currency, String amount) {
    return '$currency$amount dépensé';
  }

  @override
  String limitText(String currency, String amount) {
    return '$currency$amount limite';
  }

  @override
  String savedText(String currency, String amount) {
    return '$currency$amount économisé';
  }

  @override
  String goalText(String currency, String amount) {
    return '$currency$amount objectif';
  }

  @override
  String get newSavingGoal => 'Nouvel objectif d\'\'épargne';

  @override
  String get goalName => 'Nom de l\'\'objectif';

  @override
  String get note => 'Note';

  @override
  String get targetAmount => 'Montant cible';

  @override
  String get timeframe => 'Délai';

  @override
  String get fixedDate => 'Date fixe';

  @override
  String get period => 'Période';

  @override
  String get category => 'Catégorie';

  @override
  String get saveGoal => 'Enregistrer l\'\'objectif';

  @override
  String get enterValidNameAndGoalAmount =>
      'Veuillez entrer un nom et un montant d\'\'objectif valides';

  @override
  String get budgetName => 'Nom du budget';

  @override
  String get amountLimit => 'Limite de montant';

  @override
  String get saveBudget => 'Enregistrer le budget';

  @override
  String get enterValidNameAndAmount =>
      'Veuillez entrer un nom et un montant valides';

  @override
  String get customizeCategory => 'Personnaliser la catégorie';

  @override
  String get categoryName => 'Nom de la catégorie';

  @override
  String get selectIcon => 'Sélectionner une icône';

  @override
  String get saveCustomCategory => 'Enregistrer la catégorie';

  @override
  String get customExpenseLimitReached =>
      'Limite des dépenses personnalisées atteinte (max 10).';

  @override
  String get customIncomeLimitReached =>
      'Limite des revenus personnalisés atteinte (max 10).';

  @override
  String get customExpenseLimitReachedDeleteFirst =>
      'Limite des dépenses personnalisées atteinte (max 10). Veuillez d\'\'abord supprimer une catégorie.';

  @override
  String get customIncomeLimitReachedDeleteFirst =>
      'Limite des revenus personnalisés atteinte (max 10). Veuillez d\'\'abord supprimer une catégorie.';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get addIncome => 'Ajouter un revenu';

  @override
  String get customPlus => 'Personnalisé +';

  @override
  String get dateTime => 'Date et heure';

  @override
  String get whatWasThisFor => 'Pour quoi était-ce ?';

  @override
  String get saveTransaction => 'Enregistrer la transaction';

  @override
  String get transactionHistory => 'Historique des transactions';

  @override
  String get noTransactionsOnDate => 'Aucune transaction à cette date';

  @override
  String get history => 'Historique';

  @override
  String get pastBudgets => 'Budgets passés';

  @override
  String get noPastBudgets => 'Aucun budget passé.';

  @override
  String get pastSavingGoals => 'Objectifs d\'\'épargne passés';

  @override
  String get noPastSavingsGoals => 'Aucun objectif d\'\'épargne passé.';

  @override
  String get noNote => 'Pas de note';

  @override
  String get enterValidAmount => 'Veuillez entrer un montant valide';
}
