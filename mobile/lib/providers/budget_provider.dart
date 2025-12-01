import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../services/api_client.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BudgetService(apiClient);
});

final budgetSummaryProvider = FutureProvider.autoDispose.family<BudgetSummary, MonthYear>(
  (ref, monthYear) async {
    final service = ref.watch(budgetServiceProvider);
    return await service.getBudgetSummary(
      month: monthYear.month,
      year: monthYear.year,
    );
  },
);

class MonthYear {
  final int month;
  final int year;

  MonthYear({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

final budgetHistoryProvider = FutureProvider.autoDispose.family<BudgetHistory, int>(
  (ref, months) async {
    final service = ref.watch(budgetServiceProvider);
    return await service.getBudgetHistory(months: months);
  },
);

class ComparisonParams {
  final int month1;
  final int year1;
  final int month2;
  final int year2;

  ComparisonParams({
    required this.month1,
    required this.year1,
    required this.month2,
    required this.year2,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonParams &&
          runtimeType == other.runtimeType &&
          month1 == other.month1 &&
          year1 == other.year1 &&
          month2 == other.month2 &&
          year2 == other.year2;

  @override
  int get hashCode =>
      month1.hashCode ^ year1.hashCode ^ month2.hashCode ^ year2.hashCode;
}

final budgetComparisonProvider = FutureProvider.autoDispose.family<BudgetComparison, ComparisonParams>(
  (ref, params) async {
    final service = ref.watch(budgetServiceProvider);
    return await service.compareBudgets(
      month1: params.month1,
      year1: params.year1,
      month2: params.month2,
      year2: params.year2,
    );
  },
);
