/// Utility functions for safe number conversions
class NumberUtils {
  /// Safely converts a dynamic value to double
  /// Handles both int and double types from JSON
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Safely converts a dynamic value to int
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Formats a number as currency
  static String formatCurrency(dynamic value, {String symbol = 'đ', int decimals = 0}) {
    final doubleValue = toDouble(value);
    final formatted = doubleValue.toStringAsFixed(decimals);
    return '$formatted $symbol';
  }

  /// Formats a number with thousand separators
  static String formatNumber(dynamic value, {int decimals = 0}) {
    final doubleValue = toDouble(value);
    final parts = doubleValue.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';
    
    // Add thousand separators
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    
    if (decimals > 0 && decPart.isNotEmpty) {
      buffer.write('.');
      buffer.write(decPart);
    }
    
    return buffer.toString();
  }
}
