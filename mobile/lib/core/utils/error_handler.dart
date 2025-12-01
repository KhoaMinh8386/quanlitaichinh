import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    return error.toString().replaceAll('Exception: ', '');
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối timeout. Vui lòng kiểm tra mạng và thử lại.';
      
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu timeout. Vui lòng thử lại.';
      
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu timeout. Vui lòng thử lại.';
      
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);
      
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      
      case DioExceptionType.connectionError:
        return 'Lỗi kết nối. Vui lòng kiểm tra mạng.';
      
      case DioExceptionType.badCertificate:
        return 'Lỗi chứng chỉ bảo mật.';
      
      case DioExceptionType.unknown:
        return 'Lỗi không xác định. Vui lòng thử lại.';
    }
  }

  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract error message from response
    if (data != null) {
      if (data is Map<String, dynamic>) {
        // Check for message field
        if (data.containsKey('message')) {
          return _translateErrorMessage(data['message'].toString());
        }
        
        // Check for error field
        if (data.containsKey('error')) {
          return _translateErrorMessage(data['error'].toString());
        }
      }
    }

    // Fallback to status code messages
    switch (statusCode) {
      case 400:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền truy cập.';
      case 404:
        return 'Không tìm thấy dữ liệu.';
      case 409:
        return 'Dữ liệu đã tồn tại.';
      case 422:
        return 'Dữ liệu không hợp lệ.';
      case 500:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng.';
      default:
        return 'Đã xảy ra lỗi (${statusCode ?? 'unknown'}). Vui lòng thử lại.';
    }
  }

  static String _translateErrorMessage(String message) {
    // Translate common error messages to Vietnamese
    final translations = {
      // Authentication errors
      'Email not found': 'Email không tồn tại. Vui lòng kiểm tra lại hoặc đăng ký tài khoản mới.',
      'Email not found. Please check your email or register for a new account.': 
          'Email không tồn tại. Vui lòng kiểm tra lại hoặc đăng ký tài khoản mới.',
      'Incorrect password': 'Mật khẩu không đúng. Vui lòng thử lại hoặc đặt lại mật khẩu.',
      'Incorrect password. Please try again or reset your password.': 
          'Mật khẩu không đúng. Vui lòng thử lại hoặc đặt lại mật khẩu.',
      'Invalid email or password': 'Email hoặc mật khẩu không đúng.',
      'Invalid email format': 'Định dạng email không hợp lệ.',
      'Email and password are required': 'Email và mật khẩu là bắt buộc.',
      'User with this email already exists': 'Email này đã được đăng ký.',
      'Password must be at least 8 characters long': 'Mật khẩu phải có ít nhất 8 ký tự.',
      
      // Token errors
      'Refresh token is required': 'Token làm mới là bắt buộc.',
      'Refresh token expired': 'Token làm mới đã hết hạn. Vui lòng đăng nhập lại.',
      'Invalid refresh token': 'Token làm mới không hợp lệ.',
      'User not found': 'Không tìm thấy người dùng.',
      
      // Network errors
      'Network error': 'Lỗi mạng. Vui lòng kiểm tra kết nối.',
      'Connection timeout': 'Kết nối timeout.',
      'Server error': 'Lỗi máy chủ.',
    };

    // Check for exact match
    if (translations.containsKey(message)) {
      return translations[message]!;
    }

    // Check for partial match
    for (var entry in translations.entries) {
      if (message.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Return original message if no translation found
    return message;
  }

  // Specific error types for better handling
  static bool isAuthenticationError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  static bool isValidationError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 400 || 
             error.response?.statusCode == 422;
    }
    return false;
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout;
    }
    return false;
  }
}
