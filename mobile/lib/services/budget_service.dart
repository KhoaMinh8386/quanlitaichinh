import 'package:dio/dio.dart';
import '../models/budget.dart';
import 'api_client.dart';

class BudgetService {
  final ApiClient _apiClient;

  BudgetService(this._apiClient);

  Future<BudgetSummary> getBudgetSummary({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiClient.get(
        '/budgets/summary',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );
      return BudgetSummary.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createOrUpdateBudget({
    required int month,
    required int year,
    required int categoryId,
    required double amountLimit,
  }) async {
    try {
      await _apiClient.post(
        '/budgets',
        data: {
          'month': month,
          'year': year,
          'categoryId': categoryId,
          'amountLimit': amountLimit,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _apiClient.delete('/api/budgets/$budgetId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetHistory> getBudgetHistory({int months = 6}) async {
    try {
      final response = await _apiClient.get(
        '/budgets/history',
        queryParameters: {
          'months': months,
        },
      );
      return BudgetHistory.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetComparison> compareBudgets({
    required int month1,
    required int year1,
    required int month2,
    required int year2,
  }) async {
    try {
      final response = await _apiClient.get(
        '/budgets/compare',
        queryParameters: {
          'month1': month1,
          'year1': year1,
          'month2': month2,
          'year2': year2,
        },
      );
      return BudgetComparison.fromJson(response.data);
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
