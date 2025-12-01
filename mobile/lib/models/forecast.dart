class ForecastResult {
  final bool hasEnoughData;
  final String? warningMessage;
  final HistoricalData? historicalData;
  final MonthlyPrediction? prediction;
  final List<String> recommendations;
  final ChartData? chartData;

  ForecastResult({
    required this.hasEnoughData,
    this.warningMessage,
    this.historicalData,
    this.prediction,
    required this.recommendations,
    this.chartData,
  });

  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    return ForecastResult(
      hasEnoughData: json['hasEnoughData'],
      warningMessage: json['warningMessage'],
      historicalData: json['historicalData'] != null
          ? HistoricalData.fromJson(json['historicalData'])
          : null,
      prediction: json['prediction'] != null
          ? MonthlyPrediction.fromJson(json['prediction'])
          : null,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      chartData: json['chartData'] != null
          ? ChartData.fromJson(json['chartData'])
          : null,
    );
  }
}

class HistoricalData {
  final List<MonthlyData> months;
  final HistoricalAverage averages;

  HistoricalData({
    required this.months,
    required this.averages,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      months: (json['months'] as List)
          .map((m) => MonthlyData.fromJson(m))
          .toList(),
      averages: HistoricalAverage.fromJson(json['averages']),
    );
  }
}

class MonthlyData {
  final int month;
  final int year;
  final double income;
  final double expense;
  final double savings;

  MonthlyData({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.savings,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] is int ? json['month'] : int.parse(json['month'].toString()),
      year: json['year'] is int ? json['year'] : int.parse(json['year'].toString()),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
    );
  }
}

class HistoricalAverage {
  final double income;
  final double expense;
  final double savings;
  final double savingsRate;

  HistoricalAverage({
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingsRate,
  });

  factory HistoricalAverage.fromJson(Map<String, dynamic> json) {
    return HistoricalAverage(
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      savingsRate: (json['savingsRate'] as num).toDouble(),
    );
  }
}

class MonthlyPrediction {
  final int month;
  final int year;
  final double predictedIncome;
  final double predictedExpense;
  final double predictedSavings;

  MonthlyPrediction({
    required this.month,
    required this.year,
    required this.predictedIncome,
    required this.predictedExpense,
    required this.predictedSavings,
  });

  factory MonthlyPrediction.fromJson(Map<String, dynamic> json) {
    return MonthlyPrediction(
      month: json['month'] is int ? json['month'] : int.parse(json['month'].toString()),
      year: json['year'] is int ? json['year'] : int.parse(json['year'].toString()),
      predictedIncome: (json['predictedIncome'] as num).toDouble(),
      predictedExpense: (json['predictedExpense'] as num).toDouble(),
      predictedSavings: (json['predictedSavings'] as num).toDouble(),
    );
  }
}

class ChartData {
  final List<ChartPoint> historical;
  final List<ChartPoint> predicted;

  ChartData({
    required this.historical,
    required this.predicted,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      historical: (json['historical'] as List)
          .map((p) => ChartPoint.fromJson(p))
          .toList(),
      predicted: (json['predicted'] as List)
          .map((p) => ChartPoint.fromJson(p))
          .toList(),
    );
  }
}

class ChartPoint {
  final String x;
  final double y;

  ChartPoint({required this.x, required this.y});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      x: json['x'],
      y: (json['y'] as num).toDouble(),
    );
  }
}
