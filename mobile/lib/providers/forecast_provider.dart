import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forecast.dart';
import '../services/forecast_service.dart';
import '../services/api_client.dart';

final forecastServiceProvider = Provider<ForecastService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ForecastService(apiClient);
});

final forecastProvider = FutureProvider.autoDispose<ForecastResult>((ref) async {
  final service = ref.watch(forecastServiceProvider);
  return await service.getNextMonthForecast();
});
