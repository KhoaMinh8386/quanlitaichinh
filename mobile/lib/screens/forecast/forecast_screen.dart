import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/forecast_provider.dart';
import '../../models/forecast.dart';
import 'package:intl/intl.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.forecast),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(forecastProvider);
            },
          ),
        ],
      ),
      body: forecastAsync.when(
        data: (forecast) {
          if (!forecast.hasEnoughData) {
            return _buildInsufficientDataView(forecast.warningMessage);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(forecastProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildForecastCard(context, forecast),
                  const SizedBox(height: 24),
                  _buildHistoricalAverages(context, forecast),
                  const SizedBox(height: 24),
                  _buildForecastChart(context, forecast),
                  const SizedBox(height: 24),
                  _buildRecommendations(context, forecast),
                ],
              ),
            ),
          );
        },
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
                  ref.invalidate(forecastProvider);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInsufficientDataView(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa đủ dữ liệu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Cần ít nhất 3 tháng dữ liệu giao dịch để tạo dự báo chính xác.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Hãy tiếp tục sử dụng ứng dụng để ghi nhận các giao dịch của bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, ForecastResult forecast) {
    final prediction = forecast.prediction;
    if (prediction == null) return const SizedBox.shrink();
    
    final monthName = _getMonthName(prediction.month);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF4F46E5),
            Color(0xFF06B6D4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Dự báo tháng $monthName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildForecastRow(
            'Thu nhập dự kiến',
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(prediction.predictedIncome),
            Icons.arrow_downward,
            Colors.white,
          ),
          const SizedBox(height: 16),
          _buildForecastRow(
            'Chi tiêu dự kiến',
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(prediction.predictedExpense),
            Icons.arrow_upward,
            Colors.white,
          ),
          const SizedBox(height: 16),
          _buildForecastRow(
            'Tiết kiệm dự kiến',
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(prediction.predictedSavings),
            Icons.savings,
            Colors.white,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dự báo dựa trên ${forecast.historicalData?.months.length ?? 0} tháng gần nhất',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMonthName(int month) {
    const months = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    return months[month - 1];
  }

  Widget _buildForecastRow(
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalAverages(BuildContext context, ForecastResult forecast) {
    final averages = forecast.historicalData?.averages;
    if (averages == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.historicalAverage,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAverageCard(
                'Thu nhập TB',
                NumberFormat.compact(locale: 'vi_VN').format(averages.income),
                AppColors.income,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAverageCard(
                'Chi tiêu TB',
                NumberFormat.compact(locale: 'vi_VN').format(averages.expense),
                AppColors.expense,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAverageCard(
                'Tiết kiệm TB',
                NumberFormat.compact(locale: 'vi_VN').format(averages.savings),
                AppColors.success,
                Icons.savings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAverageCard(
                'Tỷ lệ tiết kiệm',
                '${averages.savingsRate.toStringAsFixed(1)}%',
                AppColors.primary,
                Icons.percent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAverageCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(BuildContext context, ForecastResult forecast) {
    final historical = forecast.historicalData?.months ?? [];
    final prediction = forecast.prediction;
    
    if (historical.isEmpty || prediction == null) {
      return const SizedBox.shrink();
    }
    
    // Prepare chart data
    final incomeSpots = List.generate(
      historical.length,
      (index) => FlSpot(index.toDouble(), historical[index].income / 1000000),
    );
    
    final expenseSpots = List.generate(
      historical.length,
      (index) => FlSpot(index.toDouble(), historical[index].expense / 1000000),
    );
    
    // Add prediction
    final lastIndex = historical.length - 1;
    final predictionIndex = historical.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xu hướng ${historical.length} tháng & Dự báo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}M',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < historical.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'T${historical[index].month}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      } else if (index == predictionIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'T${prediction.month}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Historical income
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: AppColors.income,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.income.withValues(alpha: 0.1),
                  ),
                ),
                // Forecast income (dashed line)
                LineChartBarData(
                  spots: [
                    FlSpot(lastIndex.toDouble(), historical[lastIndex].income / 1000000),
                    FlSpot(predictionIndex.toDouble(), prediction.predictedIncome / 1000000),
                  ],
                  isCurved: true,
                  color: AppColors.income,
                  barWidth: 3,
                  dashArray: [5, 5],
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.income,
                      );
                    },
                  ),
                ),
                // Historical expense
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: AppColors.expense,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                // Forecast expense
                LineChartBarData(
                  spots: [
                    FlSpot(lastIndex.toDouble(), historical[lastIndex].expense / 1000000),
                    FlSpot(predictionIndex.toDouble(), prediction.predictedExpense / 1000000),
                  ],
                  isCurved: true,
                  color: AppColors.expense,
                  barWidth: 3,
                  dashArray: [5, 5],
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.expense,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Thu nhập', AppColors.income, false),
            const SizedBox(width: 16),
            _buildLegendItem('Chi tiêu', AppColors.expense, false),
            const SizedBox(width: 16),
            _buildLegendItem('Dự báo', AppColors.primary, true),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context, ForecastResult forecast) {
    final recommendations = forecast.recommendations;
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recommendations,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...List.generate(recommendations.length, (index) {
          final recommendation = recommendations[index];
          
          // Determine icon and color based on content
          IconData icon = Icons.lightbulb_outline;
          Color color = AppColors.info;
          
          if (recommendation.toLowerCase().contains('giảm') || 
              recommendation.toLowerCase().contains('reduce')) {
            icon = Icons.trending_down;
            color = AppColors.warning;
          } else if (recommendation.toLowerCase().contains('tăng') || 
                     recommendation.toLowerCase().contains('increase') ||
                     recommendation.toLowerCase().contains('tiết kiệm') ||
                     recommendation.toLowerCase().contains('saving')) {
            icon = Icons.savings;
            color = AppColors.success;
          }
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < recommendations.length - 1 ? 12 : 0),
            child: _buildRecommendationCard(
              icon: icon,
              color: color,
              title: 'Gợi ý ${index + 1}',
              description: recommendation,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
