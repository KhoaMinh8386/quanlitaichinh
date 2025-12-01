import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/number_utils.dart';
import '../../providers/report_provider.dart';
import 'custom_date_range_dialog.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final int? initialTab;
  
  const ReportsScreen({super.key, this.initialTab});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  late ReportDateRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _dateRange = getCurrentMonthRange();
  }
  
  void _updatePeriod(String period) async {
    if (period == 'custom') {
      final result = await showDialog<Map<String, DateTime>>(
        context: context,
        builder: (context) => CustomDateRangeDialog(
          initialStartDate: _dateRange.start,
          initialEndDate: _dateRange.end,
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedPeriod = period;
          _dateRange = ReportDateRange(
            start: result['start']!,
            end: result['end']!,
          );
        });
      }
      return;
    }
    
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'month':
          _dateRange = getCurrentMonthRange();
          break;
        case 'quarter':
          _dateRange = getCurrentQuarterRange();
          break;
        case 'year':
          _dateRange = getCurrentYearRange();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: AppStrings.overview),
            Tab(text: AppStrings.byCategory),
            Tab(text: 'Merchant'),
            Tab(text: 'So sánh'),
            Tab(text: AppStrings.byAccount),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoryTab(),
                _buildMerchantTab(),
                _buildComparisonTab(),
                _buildAccountTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPeriodChip('Tháng này', 'month'),
              const SizedBox(width: 8),
              _buildPeriodChip('Quý này', 'quarter'),
              const SizedBox(width: 8),
              _buildPeriodChip('Năm nay', 'year'),
              const SizedBox(width: 8),
              _buildPeriodChip('Tùy chỉnh', 'custom'),
            ],
          ),
          if (_selectedPeriod == 'custom') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _updatePeriod(value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final reportAsync = ref.watch(reportOverviewProvider(_dateRange));
    
    return reportAsync.when(
      data: (report) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportOverviewProvider(_dateRange));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCardsFromData(report),
              const SizedBox(height: 24),
              Text(
                'Xu hướng chi tiêu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildLineChart(),
              const SizedBox(height: 24),
              Text(
                'Tổng quan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildOverviewCard(report),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(reportOverviewProvider(_dateRange));
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCardsFromData(Map<String, dynamic> report) {
    final totalIncome = NumberUtils.toDouble(report['totalIncome']);
    final totalExpense = NumberUtils.toDouble(report['totalExpense']);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Thu nhập',
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(totalIncome),
            Icons.arrow_downward,
            AppColors.income,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Chi tiêu',
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(totalExpense),
            Icons.arrow_upward,
            AppColors.expense,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewCard(Map<String, dynamic> report) {
    final totalIncome = NumberUtils.toDouble(report['totalIncome']);
    final totalExpense = NumberUtils.toDouble(report['totalExpense']);
    final savings = NumberUtils.toDouble(report['savings']);
    final savingsRate = NumberUtils.toDouble(report['savingsRate']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildOverviewRow('Thu nhập', totalIncome, AppColors.income),
          const Divider(height: 24),
          _buildOverviewRow('Chi tiêu', totalExpense, AppColors.expense),
          const Divider(height: 24),
          _buildOverviewRow('Tiết kiệm', savings, AppColors.success),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tỷ lệ tiết kiệm',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${savingsRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${NumberFormat('#,###').format(amount)} đ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }



  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(1, 4),
                const FlSpot(2, 3.5),
                const FlSpot(3, 5),
                const FlSpot(4, 4),
                const FlSpot(5, 6),
                const FlSpot(6, 5.5),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryTab() {
    final categoryAsync = ref.watch(categoryBreakdownProvider(_dateRange));
    
    return categoryAsync.when(
      data: (categories) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryBreakdownProvider(_dateRange));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top danh mục chi nhiều nhất',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (categories.isNotEmpty) ...[
                _buildCategoryPieChartFromData(categories),
                const SizedBox(height: 24),
                ...categories.map((cat) => _buildCategoryItemFromData(cat)),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Chưa có dữ liệu'),
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(categoryBreakdownProvider(_dateRange));
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryPieChartFromData(List<Map<String, dynamic>> categories) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
    ];
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: List.generate(
            categories.take(6).length,
            (index) {
              final cat = categories[index];
              final percentage = NumberUtils.toDouble(cat['percentage']);
              
              return PieChartSectionData(
                value: percentage,
                title: '${percentage.toStringAsFixed(0)}%',
                color: colors[index % colors.length],
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryItemFromData(Map<String, dynamic> categoryData) {
    final category = categoryData['category'];
    final totalAmount = NumberUtils.toDouble(categoryData['totalAmount']);
    final transactionCount = NumberUtils.toInt(categoryData['transactionCount']);
    final percentage = NumberUtils.toDouble(categoryData['percentage']);
    
    final categoryName = category['name'] ?? 'Unknown';
    final categoryType = category['type'] ?? 'expense';
    
    final color = categoryType == 'income' ? AppColors.income : AppColors.expense;
    final icon = _getCategoryIcon(categoryName);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(categoryName),
        subtitle: Text('$transactionCount giao dịch • ${percentage.toStringAsFixed(1)}%'),
        trailing: Text(
          '${NumberFormat('#,###').format(totalAmount)} đ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('ăn') || name.contains('food')) return Icons.restaurant;
    if (name.contains('di chuyển') || name.contains('transport')) return Icons.directions_car;
    if (name.contains('hóa đơn') || name.contains('bill')) return Icons.receipt;
    if (name.contains('giải trí') || name.contains('entertainment')) return Icons.movie;
    if (name.contains('mua sắm') || name.contains('shopping')) return Icons.shopping_bag;
    if (name.contains('sức khỏe') || name.contains('health')) return Icons.local_hospital;
    if (name.contains('giáo dục') || name.contains('education')) return Icons.school;
    if (name.contains('lương') || name.contains('salary')) return Icons.attach_money;
    return Icons.category;
  }



  Widget _buildMerchantTab() {
    final merchantAsync = ref.watch(merchantBreakdownProvider(_dateRange));
    
    return merchantAsync.when(
      data: (merchants) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(merchantBreakdownProvider(_dateRange));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top merchant chi nhiều nhất',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (merchants.isNotEmpty) ...[
                ...merchants.take(20).map((merchant) => _buildMerchantItem(merchant)),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Chưa có dữ liệu'),
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(merchantBreakdownProvider(_dateRange));
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantItem(Map<String, dynamic> merchant) {
    final merchantName = merchant['merchantName'] ?? 'Unknown';
    final totalSpent = NumberUtils.toDouble(merchant['totalSpent']);
    final transactionCount = NumberUtils.toInt(merchant['transactionCount']);
    final averageAmount = NumberUtils.toDouble(merchant['averageAmount']);
    final percentage = NumberUtils.toDouble(merchant['percentage']);
    final category = merchant['category'] ?? 'Uncategorized';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.store,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          merchantName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$category • $transactionCount giao dịch'),
            Text(
              'TB: ${NumberFormat('#,###').format(averageAmount)} đ • ${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          '${NumberFormat('#,###').format(totalSpent)} đ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.expense,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildComparisonTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Tháng'),
              Tab(text: 'Năm'),
              Tab(text: 'Tùy chỉnh'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMonthComparisonView(),
                _buildYearComparisonView(),
                _buildCustomRangeComparisonView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthComparisonView() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final previousYear = currentMonth == 1 ? currentYear - 1 : currentYear;
    
    final params = MonthComparisonParams(
      month1: previousMonth,
      year1: previousYear,
      month2: currentMonth,
      year2: currentYear,
    );
    
    final comparisonAsync = ref.watch(monthComparisonProvider(params));
    
    return comparisonAsync.when(
      data: (comparison) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthComparisonProvider(params));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'So sánh tháng $previousMonth/$previousYear vs $currentMonth/$currentYear',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildComparisonSummary(comparison),
              const SizedBox(height: 24),
              Text(
                'Thay đổi theo danh mục',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...((comparison['changes'] as List?) ?? [])
                  .map((change) => _buildComparisonChangeItem(change)),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: ${error.toString()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildYearComparisonView() {
    final now = DateTime.now();
    final currentYear = now.year;
    final previousYear = currentYear - 1;
    
    final params = YearComparisonParams(
      year1: previousYear,
      year2: currentYear,
    );
    
    final comparisonAsync = ref.watch(yearComparisonProvider(params));
    
    return comparisonAsync.when(
      data: (comparison) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(yearComparisonProvider(params));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'So sánh năm $previousYear vs $currentYear',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildYearComparisonSummary(comparison),
              const SizedBox(height: 24),
              Text(
                'Xu hướng theo danh mục',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...((comparison['categoryTrends'] as List?) ?? [])
                  .map((trend) => _buildYearTrendItem(trend)),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi: ${error.toString()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRangeComparisonView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.date_range, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'So sánh tùy chỉnh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chọn hai khoảng thời gian để so sánh',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSummary(Map<String, dynamic> comparison) {
    final month1 = comparison['month1'] ?? {};
    final month2 = comparison['month2'] ?? {};
    final month1Total = NumberUtils.toDouble(month1['totalSpent']);
    final month2Total = NumberUtils.toDouble(month2['totalSpent']);
    final difference = month2Total - month1Total;
    final percentageChange = month1Total > 0 ? (difference / month1Total) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tháng trước',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(month1Total)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tháng này',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(month2Total)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                difference >= 0 ? Icons.trending_up : Icons.trending_down,
                color: difference >= 0 ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                '${difference >= 0 ? '+' : ''}${NumberFormat('#,###').format(difference)} đ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: difference >= 0 ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: difference >= 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChangeItem(Map<String, dynamic> change) {
    final categoryName = change['categoryName'] ?? 'Unknown';
    final difference = NumberUtils.toDouble(change['difference']);
    final percentageChange = NumberUtils.toDouble(change['percentageChange']);
    final trend = change['trend'] ?? 'stable';
    
    Color trendColor;
    IconData trendIcon;
    
    switch (trend) {
      case 'increase':
        trendColor = AppColors.error;
        trendIcon = Icons.trending_up;
        break;
      case 'decrease':
        trendColor = AppColors.success;
        trendIcon = Icons.trending_down;
        break;
      default:
        trendColor = AppColors.textSecondary;
        trendIcon = Icons.trending_flat;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(trendIcon, color: trendColor),
        title: Text(categoryName),
        subtitle: Text(
          '${difference >= 0 ? '+' : ''}${NumberFormat('#,###').format(difference)} đ',
          style: TextStyle(color: trendColor),
        ),
        trailing: Text(
          '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: trendColor,
          ),
        ),
      ),
    );
  }

  Widget _buildYearComparisonSummary(Map<String, dynamic> comparison) {
    final year1 = comparison['year1'] ?? {};
    final year2 = comparison['year2'] ?? {};
    final annualChange = comparison['annualChange'] ?? {};
    
    final year1Total = NumberUtils.toDouble(year1['totalSpent']);
    final year2Total = NumberUtils.toDouble(year2['totalSpent']);
    final difference = NumberUtils.toDouble(annualChange['difference']);
    final percentageChange = NumberUtils.toDouble(annualChange['percentageChange']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Năm ${year1['year']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(year1Total)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Năm ${year2['year']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(year2Total)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                difference >= 0 ? Icons.trending_up : Icons.trending_down,
                color: difference >= 0 ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                '${difference >= 0 ? '+' : ''}${NumberFormat('#,###').format(difference)} đ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: difference >= 0 ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: difference >= 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearTrendItem(Map<String, dynamic> trend) {
    final categoryName = trend['categoryName'] ?? 'Unknown';
    final year1Total = NumberUtils.toDouble(trend['year1Total']);
    final year2Total = NumberUtils.toDouble(trend['year2Total']);
    final change = NumberUtils.toDouble(trend['change']);
    final percentageChange = NumberUtils.toDouble(trend['percentageChange']);
    
    final trendColor = change >= 0 ? AppColors.error : AppColors.success;
    final trendIcon = change >= 0 ? Icons.trending_up : Icons.trending_down;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(trendIcon, color: trendColor),
        title: Text(categoryName),
        subtitle: Text(
          '${NumberFormat('#,###').format(year1Total)} đ → ${NumberFormat('#,###').format(year2Total)} đ',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${change >= 0 ? '+' : ''}${NumberFormat('#,###').format(change)} đ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
            Text(
              '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Tính năng đang phát triển',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Báo cáo theo tài khoản sẽ sớm được cập nhật',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
