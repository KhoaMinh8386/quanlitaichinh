class AppConfig {
  // Production URL (Render)
  static const String productionUrl = 'https://quanlitaichinh.onrender.com';
  
  // Development URLs
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  // iOS simulator can use localhost directly  
  // Physical device needs your computer's IP address
  static const String developmentUrl = 'http://10.0.2.2:3001';
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production', // Changed to production by default
  );
  
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';
  
  // API Base URL - defaults to production
  // Override with --dart-define=API_BASE_URL=http://your-url for development
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionUrl,
  );
  
  // Sepay webhook info (for reference)
  static const String sepayWebhookUrl = '$productionUrl/api/sepay/webhook/public';
}
