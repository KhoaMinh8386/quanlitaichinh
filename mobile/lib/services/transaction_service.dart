import 'package:dio/dio.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class TransactionService {
  final ApiClient _apiClient;

  TransactionService(this._apiClient);

  Future<Map<String, dynamic>> getTransactions({
    DateTime? from,
    DateTime? to,
    String? type,
    int? categoryId,
    String? accountId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (accountId != null) queryParams['accountId'] = accountId;

      print('🔍 Fetching transactions with params: $queryParams');
      
      final response = await _apiClient.get(
        '/api/transactions',
        queryParameters: queryParams,
      );

      print('✅ Response received: ${response.statusCode}');

      final transactions = (response.data['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();

      print('📊 Parsed ${transactions.length} transactions');

      return {
        'transactions': transactions,
        'pagination': response.data['pagination'],
      };
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      throw _handleError(e);
    }
  }

  Future<Transaction> getTransactionById(String id) async {
    try {
      final response = await _apiClient.get('/api/transactions/$id');
      return Transaction.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTransactionCategory(String id, int categoryId) async {
    try {
      await _apiClient.patch(
        '/api/categorization/transactions/$id/category',
        data: {'categoryId': categoryId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTransactionNotes(String id, String notes) async {
    try {
      await _apiClient.patch(
        '/api/transactions/$id',
        data: {'notes': notes},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTransactionStats({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/transactions/stats',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get('/api/categories');
      return (response.data as List)
          .map((c) => Category.fromJson(c))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Transaction> createTransaction({
    required double amount,
    required String type,
    required int categoryId,
    String? description,
    DateTime? postedAt,
    String? accountId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/transactions',
        data: {
          'amount': amount,
          'type': type,
          'categoryId': categoryId,
          'description': description,
          'postedAt': (postedAt ?? DateTime.now()).toIso8601String(),
          if (accountId != null) 'accountId': accountId,
        },
      );
      return Transaction.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> bulkUpdateCategory({
    required List<String> transactionIds,
    required int categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/transactions/bulk-update-category',
        data: {
          'transactionIds': transactionIds,
          'categoryId': categoryId,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Simulate a webhook for testing purposes
  Future<Map<String, dynamic>> simulateWebhook({
    required double amount,
    required String type, // 'in' or 'out'
    String? content,
    String bankCode = 'MBBANK',
    String accountNumber = '0123456789',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/sepay/webhook/simulate',
        data: {
          'amount': amount,
          'type': type,
          'content': content ?? 'Test transaction ${DateTime.now().millisecondsSinceEpoch}',
          'bankCode': bankCode,
          'accountNumber': accountNumber,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Link a bank account for receiving webhooks
  Future<Map<String, dynamic>> linkBankAccount({
    required String accountNumber,
    required String bankCode,
    String? alias,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/sepay/link-account',
        data: {
          'accountNumber': accountNumber,
          'bankCode': bankCode,
          if (alias != null) 'alias': alias,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get webhook logs (recent transactions from webhooks)
  Future<Map<String, dynamic>> getWebhookLogs() async {
    try {
      final response = await _apiClient.get('/api/sepay/webhook/logs');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'];
        
        // Handle specific status codes
        if (statusCode == 401) {
          return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
        }
        if (statusCode == 403) {
          return 'Bạn không có quyền truy cập.';
        }
        if (statusCode == 404) {
          return 'Không tìm thấy dữ liệu.';
        }
        if (statusCode == 500) {
          return 'Lỗi máy chủ. Vui lòng thử lại sau.';
        }
        
        return message ?? 'Đã xảy ra lỗi';
      }
      
      // Handle connection errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối quá chậm. Vui lòng thử lại.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng.';
      }
      
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối.';
    }
    return error.toString();
  }
}
