class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String apiVersion = '/api';

  // Auth endpoints
  static const String authRegister = '$apiVersion/auth/register';
  static const String authLogin = '$apiVersion/auth/login';
  static const String authRefresh = '$apiVersion/auth/refresh';

  // Bank endpoints
  static const String bankProviders = '$apiVersion/banks/providers';
  static const String bankConnectUrl = '$apiVersion/banks/connect-url';
  static const String bankAccounts = '$apiVersion/bank-accounts';

  // Transaction endpoints
  static const String transactions = '$apiVersion/transactions';

  // Budget endpoints
  static const String budgets = '$apiVersion/budgets';
  static const String budgetSummary = '$apiVersion/budgets/summary';

  // Report endpoints
  static const String reportOverview = '$apiVersion/reports/overview';
  static const String reportCategoryBreakdown = '$apiVersion/reports/category-breakdown';

  // Forecast endpoints
  static const String forecastNextMonth = '$apiVersion/forecast/next-month';

  // Alert endpoints
  static const String alerts = '$apiVersion/alerts';
}
