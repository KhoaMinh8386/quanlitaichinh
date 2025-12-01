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
    defaultValue: 'development', // Changed to development for local backend
  );
  
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';
  
  // API Base URL - defaults to development (local) for Google Sheets integration
  // Override with --dart-define=API_BASE_URL=http://your-url for production
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: developmentUrl, // Use local backend by default
  );
  
  // Sepay webhook info (for reference)
  static const String sepayWebhookUrl = '$productionUrl/api/sepay/webhook/public';
}
