import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import 'package:intl/intl.dart';
import 'budget_history_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = MonthYear(
      month: _selectedDate.month,
      year: _selectedDate.year,
    );
    final budgetSummaryAsync = ref.watch(budgetSummaryProvider(monthYear));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.budgets),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetSummaryProvider(monthYear));
        },
        child: budgetSummaryAsync.when(
          data: (summary) => _buildContent(summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(budgetSummaryProvider(monthYear)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BudgetSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 24),
          _buildOverallSummary(summary),
          const SizedBox(height: 24),
          Text(
            'Ngân sách theo danh mục',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (summary.categories.isEmpty)
            _buildEmptyState()
          else
            ...summary.categories.map((budget) => _buildBudgetItem(budget)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi').format(_selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary(BudgetSummary summary) {
    final remaining = summary.totalBudget - summary.totalSpent;
    final percentage = summary.usagePercentage / 100.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng ngân sách',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(summary.totalBudget)} đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đã chi',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(summary.totalSpent)} đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Còn lại',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(remaining)} đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage > 1 ? 1 : percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.usagePercentage.toStringAsFixed(1)}% đã sử dụng',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có ngân sách',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo ngân sách để quản lý chi tiêu của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tạo ngân sách'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(Budget budget) {
    final percentage = budget.percentage / 100.0;
    final statusInfo = _getBudgetStatus(budget.status);
    final categoryIcon = _getCategoryIcon(budget.category.name);
    final categoryColor = _getCategoryColor(budget.category.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              statusInfo['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusInfo['color'] as Color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showBudgetOptions(budget),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat('#,###').format(budget.spent)} đ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(budget.limit)} đ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage > 1 ? 1 : percentage,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color'] as Color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${budget.percentage.toStringAsFixed(1)}% đã sử dụng',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getBudgetStatus(String status) {
    switch (status) {
      case 'exceeded':
        return {
          'label': AppStrings.exceeded,
          'color': AppColors.error,
        };
      case 'warning':
        return {
          'label': AppStrings.warning,
          'color': AppColors.warning,
        };
      default:
        return {
          'label': AppStrings.normal,
          'color': AppColors.success,
        };
    }
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
    if (name.contains('lương') || name.contains('salary')) return Icons.account_balance_wallet;
    return Icons.category;
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('ăn') || name.contains('food')) return const Color(0xFF7C3AED);
    if (name.contains('di chuyển') || name.contains('transport')) return const Color(0xFF06B6D4);
    if (name.contains('hóa đơn') || name.contains('bill')) return const Color(0xFFF59E0B);
    if (name.contains('giải trí') || name.contains('entertainment')) return const Color(0xFFEC4899);
    if (name.contains('mua sắm') || name.contains('shopping')) return const Color(0xFF10B981);
    if (name.contains('sức khỏe') || name.contains('health')) return const Color(0xFFEF4444);
    if (name.contains('giáo dục') || name.contains('education')) return const Color(0xFF3B82F6);
    if (name.contains('lương') || name.contains('salary')) return const Color(0xFF22C55E);
    return AppColors.primary;
  }

  void _showAddBudgetDialog(BuildContext context, [Budget? existingBudget]) {
    final categoriesAsync = ref.read(expenseCategoriesProvider);
    
    categoriesAsync.when(
      data: (expenseCategories) {
        
        Category? selectedCategory = existingBudget?.category;
        final amountController = TextEditingController(
          text: existingBudget?.limit.toStringAsFixed(0) ?? '',
        );

        showDialog(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(existingBudget == null ? AppStrings.addBudget : AppStrings.edit),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Category>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: AppStrings.selectCategory,
                            border: OutlineInputBorder(),
                          ),
                          items: expenseCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(cat.name),
                                    size: 20,
                                    color: _getCategoryColor(cat.name),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.budgetLimit,
                            suffixText: 'đ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedCategory == null || amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                          );
                          return;
                        }

                        try {
                          final amount = double.parse(amountController.text);
                          final service = ref.read(budgetServiceProvider);
                          
                          await service.createOrUpdateBudget(
                            month: _selectedDate.month,
                            year: _selectedDate.year,
                            categoryId: selectedCategory!.id,
                            amountLimit: amount,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã lưu ngân sách')),
                            );
                            
                            // Refresh data
                            ref.invalidate(budgetSummaryProvider(MonthYear(
                              month: _selectedDate.month,
                              year: _selectedDate.year,
                            )));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      child: const Text(AppStrings.save),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh mục...')),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${error.toString()}')),
        );
      },
    );
  }

  void _showBudgetOptions(Budget budget) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text(AppStrings.edit),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showAddBudgetDialog(context, budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _confirmDeleteBudget(budget);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa ngân sách'),
          content: Text('Bạn có chắc muốn xóa ngân sách cho "${budget.category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final service = ref.read(budgetServiceProvider);
                  await service.deleteBudget(budget.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa ngân sách')),
                    );
                    
                    // Refresh data
                    ref.invalidate(budgetSummaryProvider(MonthYear(
                      month: _selectedDate.month,
                      year: _selectedDate.year,
                    )));
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );
  }
}
