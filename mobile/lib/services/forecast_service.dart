import 'package:dio/dio.dart';
import '../models/forecast.dart';
import 'api_client.dart';

class ForecastService {
  final ApiClient _apiClient;

  ForecastService(this._apiClient);

  Future<ForecastResult> getNextMonthForecast() async {
    try {
      final response = await _apiClient.get('/api/forecast/next-month');
      return ForecastResult.fromJson(response.data);
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
