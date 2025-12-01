import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../core/constants/app_colors.dart';

class BudgetHistoryScreen extends ConsumerStatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  ConsumerState<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends ConsumerState<BudgetHistoryScreen> {
  int _selectedMonths = 6;
  MonthYear? _comparisonMonth1;
  MonthYear? _comparisonMonth2;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(budgetHistoryProvider(_selectedMonths));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget History'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedMonths,
            onSelected: (value) {
              setState(() {
                _selectedMonths = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 3, child: Text('Last 3 months')),
              const PopupMenuItem(value: 6, child: Text('Last 6 months')),
              const PopupMenuItem(value: 12, child: Text('Last 12 months')),
            ],
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(budgetHistoryProvider(_selectedMonths));
          },
          child: _buildHistoryContent(history),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(budgetHistoryProvider(_selectedMonths)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(BudgetHistory history) {
    if (history.history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No budget history available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.hasInsufficientData)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Limited data available. More history will appear as you use the app.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          _buildTrendChart(history),
          const SizedBox(height: 24),
          _buildComparisonSelector(history),
          const SizedBox(height: 24),
          _buildMonthlyCards(history),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BudgetHistory history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Usage Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < history.history.length) {
                            final summary = history.history[history.history.length - 1 - index];
                            return Text(
                              '${summary.month}/${summary.year.toString().substring(2)}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.history.reversed.toList().asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.usagePercentage.clamp(0, 100),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSelector(BudgetHistory history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare Months',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMonthSelector(
                    label: 'Month 1',
                    selectedMonth: _comparisonMonth1,
                    history: history,
                    onChanged: (month) {
                      setState(() {
                        _comparisonMonth1 = month;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMonthSelector(
                    label: 'Month 2',
                    selectedMonth: _comparisonMonth2,
                    history: history,
                    onChanged: (month) {
                      setState(() {
                        _comparisonMonth2 = month;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _comparisonMonth1 != null && _comparisonMonth2 != null
                    ? () => _showComparison()
                    : null,
                child: const Text('Compare'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector({
    required String label,
    required MonthYear? selectedMonth,
    required BudgetHistory history,
    required Function(MonthYear?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<MonthYear>(
          value: selectedMonth,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Select month'),
          items: history.history.map((summary) {
            final monthYear = MonthYear(month: summary.month, year: summary.year);
            return DropdownMenuItem(
              value: monthYear,
              child: Text('${_getMonthName(summary.month)} ${summary.year}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showComparison() {
    if (_comparisonMonth1 == null || _comparisonMonth2 == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetComparisonScreen(
          month1: _comparisonMonth1!,
          month2: _comparisonMonth2!,
        ),
      ),
    );
  }

  Widget _buildMonthlyCards(BudgetHistory history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...history.history.map((summary) => _buildMonthCard(summary)),
      ],
    );
  }

  Widget _buildMonthCard(BudgetSummary summary) {
    final usageColor = summary.usagePercentage >= 100
        ? Colors.red
        : summary.usagePercentage >= 80
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getMonthName(summary.month)} ${summary.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: usageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summary.usagePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: usageColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Budget', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      _formatCurrency(summary.totalBudget),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Spent', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      _formatCurrency(summary.totalSpent),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: usageColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (summary.usagePercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₫', decimalDigits: 0);
    return formatter.format(amount);
  }
}

// Budget Comparison Screen (for subtask 12.5)
class BudgetComparisonScreen extends ConsumerWidget {
  final MonthYear month1;
  final MonthYear month2;

  const BudgetComparisonScreen({
    super.key,
    required this.month1,
    required this.month2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(
      budgetComparisonProvider(
        ComparisonParams(
          month1: month1.month,
          year1: month1.year,
          month2: month2.month,
          year2: month2.year,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Comparison'),
      ),
      body: comparisonAsync.when(
        data: (comparison) => _buildComparisonContent(context, comparison),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonContent(BuildContext context, BudgetComparison comparison) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallComparison(comparison),
          const SizedBox(height: 24),
          _buildCategoryChanges(comparison),
        ],
      ),
    );
  }

  Widget _buildOverallComparison(BudgetComparison comparison) {
    final isIncrease = comparison.overallChange.difference > 0;
    final changeColor = isIncrease ? Colors.red : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Change',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMonthSummaryCard(
                    '${_getMonthName(comparison.month1.month)} ${comparison.month1.year}',
                    comparison.month1.totalSpent,
                    comparison.month1.usagePercentage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMonthSummaryCard(
                    '${_getMonthName(comparison.month2.month)} ${comparison.month2.year}',
                    comparison.month2.totalSpent,
                    comparison.month2.usagePercentage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIncrease ? '+' : ''}${_formatCurrency(comparison.overallChange.difference)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${comparison.overallChange.percentageChange.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 16,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSummaryCard(String title, double spent, double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(spent),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% used',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChanges(BudgetComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...comparison.categoryChanges.map((change) => _buildCategoryChangeItem(change)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChangeItem(CategoryChange change) {
    final isIncrease = change.difference > 0;
    final changeColor = isIncrease ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change.isSignificant
            ? changeColor.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: change.isSignificant
              ? changeColor.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                change.categoryName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (change.isSignificant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Significant',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCurrency(change.month1Spent),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Text(
                    'Previous',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Icon(
                isIncrease ? Icons.arrow_forward : Icons.arrow_forward,
                color: changeColor,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(change.month2Spent),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                  const Text(
                    'Current',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                color: changeColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isIncrease ? '+' : ''}${_formatCurrency(change.difference)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${change.percentageChange.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₫', decimalDigits: 0);
    return formatter.format(amount);
  }
}
