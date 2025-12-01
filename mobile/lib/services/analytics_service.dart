import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AnalyticsService(apiClient);
});

class AnalyticsService {
  final ApiClient _apiClient;

  AnalyticsService(this._apiClient);

  /// Get spending summary for a date range
  Future<AnalyticsSummary> getSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (from != null) {
        params['from'] = from.toIso8601String().split('T')[0];
      }
      if (to != null) {
        params['to'] = to.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/api/analytics/summary',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return AnalyticsSummary.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch summary');
    } catch (e) {
      rethrow;
    }
  }

  /// Get time series data for charts
  Future<List<TimeSeriesData>> getTimeSeries({
    String groupBy = 'month',
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'groupBy': groupBy,
      };
      if (from != null) {
        params['from'] = from.toIso8601String().split('T')[0];
      }
      if (to != null) {
        params['to'] = to.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/api/analytics/timeseries',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => TimeSeriesData.fromJson(e)).toList();
      }
      throw Exception('Failed to fetch time series');
    } catch (e) {
      rethrow;
    }
  }

  /// Get spending forecast
  Future<SpendingForecast> getForecast() async {
    try {
      final response = await _apiClient.get('/api/analytics/forecast');

      if (response.statusCode == 200) {
        return SpendingForecast.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch forecast');
    } catch (e) {
      rethrow;
    }
  }

  /// Get top spending categories
  Future<List<CategoryBreakdown>> getTopCategories({int limit = 5}) async {
    try {
      final response = await _apiClient.get(
        '/api/analytics/top-categories',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => CategoryBreakdown.fromJson(e)).toList();
      }
      throw Exception('Failed to fetch top categories');
    } catch (e) {
      rethrow;
    }
  }

  /// Get period comparison
  Future<PeriodComparison> getPeriodComparison({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (from != null) {
        params['from'] = from.toIso8601String().split('T')[0];
      }
      if (to != null) {
        params['to'] = to.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/api/analytics/comparison',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return PeriodComparison.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch comparison');
    } catch (e) {
      rethrow;
    }
  }
}

// Response models
class AnalyticsSummary {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final int transactionCount;
  final List<CategoryBreakdown> categoryBreakdown;

  AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.transactionCount,
    required this.categoryBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      netSavings: (json['netSavings'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List?)
          ?.map((e) => CategoryBreakdown.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CategoryBreakdown {
  final int categoryId;
  final String categoryName;
  final String? icon;
  final String? color;
  final double total;
  final double percentage;
  final int count;

  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    this.color,
    required this.total,
    required this.percentage,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      icon: json['icon'],
      color: json['color'],
      total: (json['total'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class TimeSeriesData {
  final String label;
  final double totalExpense;
  final double totalIncome;
  final double netSavings;

  TimeSeriesData({
    required this.label,
    required this.totalExpense,
    required this.totalIncome,
    required this.netSavings,
  });

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      label: json['label'] ?? '',
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      netSavings: (json['netSavings'] ?? 0).toDouble(),
    );
  }
}

class SpendingForecast {
  final double expectedTotalExpenseNextMonth;
  final List<CategoryForecast> expectedByCategory;
  final int confidence;
  final int basedOnMonths;

  SpendingForecast({
    required this.expectedTotalExpenseNextMonth,
    required this.expectedByCategory,
    required this.confidence,
    required this.basedOnMonths,
  });

  factory SpendingForecast.fromJson(Map<String, dynamic> json) {
    return SpendingForecast(
      expectedTotalExpenseNextMonth:
          (json['expectedTotalExpenseNextMonth'] ?? 0).toDouble(),
      expectedByCategory: (json['expectedByCategory'] as List?)
          ?.map((e) => CategoryForecast.fromJson(e))
          .toList() ?? [],
      confidence: json['confidence'] ?? 0,
      basedOnMonths: json['basedOnMonths'] ?? 0,
    );
  }
}

class CategoryForecast {
  final int categoryId;
  final String categoryName;
  final double expectedAmount;
  final double averageAmount;
  final String trend;

  CategoryForecast({
    required this.categoryId,
    required this.categoryName,
    required this.expectedAmount,
    required this.averageAmount,
    required this.trend,
  });

  factory CategoryForecast.fromJson(Map<String, dynamic> json) {
    return CategoryForecast(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      expectedAmount: (json['expectedAmount'] ?? 0).toDouble(),
      averageAmount: (json['averageAmount'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
    );
  }
}

class PeriodComparison {
  final PeriodData currentPeriod;
  final PeriodData previousPeriod;
  final ComparisonChanges changes;

  PeriodComparison({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.changes,
  });

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      currentPeriod: PeriodData.fromJson(json['currentPeriod'] ?? {}),
      previousPeriod: PeriodData.fromJson(json['previousPeriod'] ?? {}),
      changes: ComparisonChanges.fromJson(json['changes'] ?? {}),
    );
  }
}

class PeriodData {
  final double income;
  final double expense;
  final double savings;

  PeriodData({
    required this.income,
    required this.expense,
    required this.savings,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
    );
  }
}

class ComparisonChanges {
  final double incomeChange;
  final double expenseChange;
  final double savingsChange;
  final double incomeChangePercent;
  final double expenseChangePercent;
  final double savingsChangePercent;

  ComparisonChanges({
    required this.incomeChange,
    required this.expenseChange,
    required this.savingsChange,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.savingsChangePercent,
  });

  factory ComparisonChanges.fromJson(Map<String, dynamic> json) {
    return ComparisonChanges(
      incomeChange: (json['incomeChange'] ?? 0).toDouble(),
      expenseChange: (json['expenseChange'] ?? 0).toDouble(),
      savingsChange: (json['savingsChange'] ?? 0).toDouble(),
      incomeChangePercent: (json['incomeChangePercent'] ?? 0).toDouble(),
      expenseChangePercent: (json['expenseChangePercent'] ?? 0).toDouble(),
      savingsChangePercent: (json['savingsChangePercent'] ?? 0).toDouble(),
    );
  }
}

