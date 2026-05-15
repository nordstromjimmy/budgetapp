/// All Swedish UI strings in one place.
/// Never hardcode text directly in widgets — always reference this class.
/// This makes future localisation (if needed) trivial.
abstract class AppStrings {
  // ── App ───────────────────────────────────────────────────────
  static const appName = 'Budgetappen';

  // ── Bottom navigation ─────────────────────────────────────────
  static const navHome = 'Hem';
  static const navTransactions = 'Transaktioner';
  static const navBudget = 'Budget';
  static const navSettings = 'Inställningar';

  // ── Home screen ───────────────────────────────────────────────
  static const homeGreetingMorning = 'God morgon';
  static const homeGreetingDay = 'Hej';
  static const homeGreetingEvening = 'God kväll';
  static const homeMonthSummary = 'Månadsöversikt';
  static const homeBalance = 'Saldo';
  static const homeIncome = 'Inkomster';
  static const homeExpenses = 'Utgifter';
  static const homeRecentTransactions = 'Senaste transaktioner';
  static const homeSeeAll = 'Visa alla';
  static const homeNoTransactions =
      'Inga transaktioner än.\nTryck på + för att lägga till.';
  static const homeBudgetOverview = 'Budgetöversikt';

  // ── Transactions ──────────────────────────────────────────────
  static const transactionsTitle = 'Transaktioner';
  static const transactionsEmpty = 'Inga transaktioner hittades.';
  static const transactionIncome = 'Inkomst';
  static const transactionExpense = 'Utgift';
  static const transactionAll = 'Alla';
  static const transactionDeleteConfirm = 'Ta bort transaktion?';
  static const transactionDeleteBody = 'Denna åtgärd kan inte ångras.';

  // ── Add / Edit transaction ────────────────────────────────────
  static const addTransactionTitle = 'Ny transaktion';
  static const editTransactionTitle = 'Redigera transaktion';
  static const fieldAmount = 'Belopp';
  static const fieldAmountHint = '0,00';
  static const fieldDescription = 'Beskrivning';
  static const fieldDescriptionHint = 'T.ex. ICA Maxi';
  static const fieldCategory = 'Kategori';
  static const fieldDate = 'Datum';
  static const fieldType = 'Typ';
  static const buttonSave = 'Spara';
  static const buttonCancel = 'Avbryt';
  static const buttonDelete = 'Ta bort';
  static const buttonEdit = 'Redigera';
  static const buttonAdd = 'Lägg till';

  // ── Validation ────────────────────────────────────────────────
  static const validationRequired = 'Detta fält är obligatoriskt';
  static const validationInvalidAmount = 'Ange ett giltigt belopp';
  static const validationSelectCategory = 'Välj en kategori';

  // ── Budget screen ─────────────────────────────────────────────
  static const budgetTitle = 'Budget';
  static const budgetMonthly = 'Månadsbudget';
  static const budgetEmpty =
      'Ingen budget satt.\nTryck på + för att lägga till.';
  static const budgetAdd = 'Lägg till budget';
  static const budgetEdit = 'Redigera budget';
  static const budgetLimit = 'Budgetgräns';
  static const budgetSpent = 'Spenderat';
  static const budgetRemaining = 'Kvar';
  static const budgetOver = 'Överskriden';
  static const budgetOf = 'av';

  // ── Settings screen ───────────────────────────────────────────
  static const settingsTitle = 'Inställningar';
  static const settingsCurrency = 'Valuta';
  static const settingsCurrencyValue = 'SEK – Svensk krona';
  static const settingsCategories = 'Kategorier';
  static const settingsManageCategories = 'Hantera kategorier';
  static const settingsAbout = 'Om appen';
  static const settingsVersion = 'Version';
  static const settingsClearData = 'Rensa all data';
  static const settingsClearDataConfirm =
      'Är du säker? All data kommer att tas bort permanent.';
  static const settingsDarkMode = 'Mörkt läge';
  static const settingsAppearance = 'Utseende';
  static const settingsData = 'Data';

  // ── Months (Swedish) ─────────────────────────────────────────
  static const months = [
    'Januari',
    'Februari',
    'Mars',
    'April',
    'Maj',
    'Juni',
    'Juli',
    'Augusti',
    'September',
    'Oktober',
    'November',
    'December',
  ];

  static String monthName(int month) => months[month - 1];

  // ── Snackbars / feedback ──────────────────────────────────────
  static const snackTransactionAdded = 'Transaktion tillagd';
  static const snackTransactionUpdated = 'Transaktion uppdaterad';
  static const snackTransactionDeleted = 'Transaktion borttagen';
  static const snackBudgetSaved = 'Budget sparad';
  static const snackBudgetDeleted = 'Budget borttagen';
  static const snackError = 'Något gick fel. Försök igen.';
  static const snackDataCleared = 'All data har rensats';
}
