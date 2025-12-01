import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';
import 'auth_provider.dart';

// Report Service Provider
final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

// Date Range class for parameters
class ReportDateRange {
  final DateTime start;
  final DateTime end;

  ReportDateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// Report Overview Provider
final reportOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, ReportDateRange>(
  (ref, dateRange) async {
    final service = ref.watch(reportServiceProvider);
    return await service.getOverview(
      from: dateRange.start,
      to: dateRange.end,
    );
  },
);

// Category Breakdown Provider
final categoryBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ReportDateRange>(
  (ref, dateRange) async {
    final service = ref.watch(reportServiceProvider);
    return await service.getCategoryBreakdown(
      from: dateRange.start,
      to: dateRange.end,
    );
  },
);

// Merchant Breakdown Provider
final merchantBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ReportDateRange>(
  (ref, dateRange) async {
    final service = ref.watch(reportServiceProvider);
    return await service.getMerchantBreakdown(
      from: dateRange.start,
      to: dateRange.end,
    );
  },
);

// Month Comparison Parameters
class MonthComparisonParams {
  final int month1;
  final int year1;
  final int month2;
  final int year2;

  MonthComparisonParams({
    required this.month1,
    required this.year1,
    required this.month2,
    required this.year2,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthComparisonParams &&
          runtimeType == other.runtimeType &&
          month1 == other.month1 &&
          year1 == other.year1 &&
          month2 == other.month2 &&
          year2 == other.year2;

  @override
  int get hashCode =>
      month1.hashCode ^ year1.hashCode ^ month2.hashCode ^ year2.hashCode;
}

// Month Comparison Provider
final monthComparisonProvider =
    FutureProvider.family<Map<String, dynamic>, MonthComparisonParams>(
  (ref, params) async {
    final service = ref.watch(reportServiceProvider);
    return await service.compareMonths(
      month1: params.month1,
      year1: params.year1,
      month2: params.month2,
      year2: params.year2,
    );
  },
);

// Year Comparison Parameters
class YearComparisonParams {
  final int year1;
  final int year2;

  YearComparisonParams({
    required this.year1,
    required this.year2,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearComparisonParams &&
          runtimeType == other.runtimeType &&
          year1 == other.year1 &&
          year2 == other.year2;

  @override
  int get hashCode => year1.hashCode ^ year2.hashCode;
}

// Year Comparison Provider
final yearComparisonProvider =
    FutureProvider.family<Map<String, dynamic>, YearComparisonParams>(
  (ref, params) async {
    final service = ref.watch(reportServiceProvider);
    return await service.compareYears(
      year1: params.year1,
      year2: params.year2,
    );
  },
);

// Custom Range Comparison Parameters
class CustomRangeComparisonParams {
  final DateTime range1Start;
  final DateTime range1End;
  final DateTime range2Start;
  final DateTime range2End;

  CustomRangeComparisonParams({
    required this.range1Start,
    required this.range1End,
    required this.range2Start,
    required this.range2End,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomRangeComparisonParams &&
          runtimeType == other.runtimeType &&
          range1Start == other.range1Start &&
          range1End == other.range1End &&
          range2Start == other.range2Start &&
          range2End == other.range2End;

  @override
  int get hashCode =>
      range1Start.hashCode ^
      range1End.hashCode ^
      range2Start.hashCode ^
      range2End.hashCode;
}

// Custom Range Comparison Provider
final customRangeComparisonProvider =
    FutureProvider.family<Map<String, dynamic>, CustomRangeComparisonParams>(
  (ref, params) async {
    final service = ref.watch(reportServiceProvider);
    return await service.compareCustomRanges(
      range1Start: params.range1Start,
      range1End: params.range1End,
      range2Start: params.range2Start,
      range2End: params.range2End,
    );
  },
);

// Helper to get current month date range
ReportDateRange getCurrentMonthRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ReportDateRange(start: start, end: end);
}

// Helper to get current quarter date range
ReportDateRange getCurrentQuarterRange() {
  final now = DateTime.now();
  final quarter = ((now.month - 1) ~/ 3) + 1;
  final startMonth = (quarter - 1) * 3 + 1;
  final start = DateTime(now.year, startMonth, 1);
  final end = DateTime(now.year, startMonth + 3, 0, 23, 59, 59);
  return ReportDateRange(start: start, end: end);
}

// Helper to get current year date range
ReportDateRange getCurrentYearRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, 1, 1);
  final end = DateTime(now.year, 12, 31, 23, 59, 59);
  return ReportDateRange(start: start, end: end);
}
