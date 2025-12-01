class AppConfig {
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  // iOS simulator can use localhost directly
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';
}
