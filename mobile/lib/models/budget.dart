import 'transaction.dart';

class Budget {
  final String id;
  final int month;
  final int year;
  final Category category;
  final double limit;
  final double spent;
  final double remaining;
  final double percentage;
  final String status; // 'normal', 'warning', 'exceeded'

  Budget({
    required this.id,
    required this.month,
    required this.year,
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['budgetId'] ?? json['id'],
      month: json['month'] is int ? json['month'] : int.parse(json['month'].toString()),
      year: json['year'] is int ? json['year'] : int.parse(json['year'].toString()),
      category: Category.fromJson(json['category']),
      limit: (json['limit'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      status: json['status'],
    );
  }

  bool get isWarning => status == 'warning';
  bool get isExceeded => status == 'exceeded';
  bool get isNormal => status == 'normal';
}

class BudgetSummary {
  final int month;
  final int year;
  final double totalBudget;
  final double totalSpent;
  final double usagePercentage;
  final List<Budget> categories;

  BudgetSummary({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.usagePercentage,
    required this.categories,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      month: json['month'] is int ? json['month'] : int.parse(json['month'].toString()),
      year: json['year'] is int ? json['year'] : int.parse(json['year'].toString()),
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      usagePercentage: (json['usagePercentage'] as num).toDouble(),
      categories: (json['categories'] as List)
          .map((cat) => Budget.fromJson(cat))
          .toList(),
    );
  }
}

class BudgetHistory {
  final int months;
  final bool hasInsufficientData;
  final List<BudgetSummary> history;

  BudgetHistory({
    required this.months,
    required this.hasInsufficientData,
    required this.history,
  });

  factory BudgetHistory.fromJson(Map<String, dynamic> json) {
    return BudgetHistory(
      months: json['months'] as int,
      hasInsufficientData: json['hasInsufficientData'] as bool,
      history: (json['history'] as List)
          .map((item) => BudgetSummary.fromJson(item))
          .toList(),
    );
  }
}

class BudgetMonthSummary {
  final int month;
  final int year;
  final double totalBudget;
  final double totalSpent;
  final double usagePercentage;

  BudgetMonthSummary({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.usagePercentage,
  });

  factory BudgetMonthSummary.fromJson(Map<String, dynamic> json) {
    return BudgetMonthSummary(
      month: json['month'] as int,
      year: json['year'] as int,
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      usagePercentage: (json['usagePercentage'] as num).toDouble(),
    );
  }
}

class CategoryChange {
  final int categoryId;
  final String categoryName;
  final double month1Spent;
  final double month2Spent;
  final double difference;
  final double percentageChange;
  final bool isSignificant;

  CategoryChange({
    required this.categoryId,
    required this.categoryName,
    required this.month1Spent,
    required this.month2Spent,
    required this.difference,
    required this.percentageChange,
    required this.isSignificant,
  });

  factory CategoryChange.fromJson(Map<String, dynamic> json) {
    return CategoryChange(
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      month1Spent: (json['month1Spent'] as num).toDouble(),
      month2Spent: (json['month2Spent'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      isSignificant: json['isSignificant'] as bool,
    );
  }
}

class BudgetComparison {
  final BudgetMonthSummary month1;
  final BudgetMonthSummary month2;
  final List<CategoryChange> categoryChanges;
  final OverallChange overallChange;

  BudgetComparison({
    required this.month1,
    required this.month2,
    required this.categoryChanges,
    required this.overallChange,
  });

  factory BudgetComparison.fromJson(Map<String, dynamic> json) {
    return BudgetComparison(
      month1: BudgetMonthSummary.fromJson(json['month1']),
      month2: BudgetMonthSummary.fromJson(json['month2']),
      categoryChanges: (json['categoryChanges'] as List)
          .map((item) => CategoryChange.fromJson(item))
          .toList(),
      overallChange: OverallChange.fromJson(json['overallChange']),
    );
  }
}

class OverallChange {
  final double difference;
  final double percentageChange;

  OverallChange({
    required this.difference,
    required this.percentageChange,
  });

  factory OverallChange.fromJson(Map<String, dynamic> json) {
    return OverallChange(
      difference: (json['difference'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
    );
  }
}
