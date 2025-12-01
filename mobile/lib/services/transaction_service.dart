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

      final response = await _apiClient.get(
        '/api/transactions',
        queryParameters: queryParams,
      );

      final transactions = (response.data['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();

      return {
        'transactions': transactions,
        'pagination': response.data['pagination'],
      };
    } catch (e) {
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

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return error.response?.data['message'] ?? 'An error occurred';
      }
      return 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}
