import 'package:dio/dio.dart';
import 'api_client.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<Map<String, dynamic>> getOverview({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/reports/overview',
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

  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/reports/category-breakdown',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMerchantBreakdown({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/reports/merchants',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> compareMonths({
    required int month1,
    required int year1,
    required int month2,
    required int year2,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/reports/compare-months',
        queryParameters: {
          'month1': month1,
          'year1': year1,
          'month2': month2,
          'year2': year2,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> compareYears({
    required int year1,
    required int year2,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/reports/compare-years',
        queryParameters: {
          'year1': year1,
          'year2': year2,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> compareCustomRanges({
    required DateTime range1Start,
    required DateTime range1End,
    required DateTime range2Start,
    required DateTime range2End,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/reports/compare-ranges',
        data: {
          'range1Start': range1Start.toIso8601String(),
          'range1End': range1End.toIso8601String(),
          'range2Start': range2Start.toIso8601String(),
          'range2End': range2End.toIso8601String(),
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
