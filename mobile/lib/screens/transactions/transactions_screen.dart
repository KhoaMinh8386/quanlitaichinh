import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart' as models;

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCategoryId;
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};
  
  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }
  
  @override
  Widget build(BuildContext context) {
    final filters = TransactionFilters(
      from: _startDate,
      to: _endDate,
      type: _selectedType,
      categoryId: _selectedCategoryId,
    );
    
    final transactionsAsync = ref.watch(transactionsProvider(filters));
    
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedTransactionIds.length} đã chọn')
            : const Text(AppStrings.transactions),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _selectAll(transactionsAsync),
                ),
                IconButton(
                  icon: const Icon(Icons.category),
                  onPressed: _selectedTransactionIds.isEmpty
                      ? null
                      : _showBulkCategoryDialog,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _enterSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                ),
              ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode) _buildFilterChips(),
          Expanded(
            child: transactionsAsync.when(
              data: (data) {
                final transactions = data['transactions'] as List<models.Transaction>;
                if (transactions.isEmpty) {
                  return _buildEmpty();
                }
                return _buildTransactionsList(transactions);
              },
              loading: () => _buildLoading(),
              error: (error, stack) => _buildError(error),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _showSyncOptions,
              icon: const Icon(Icons.sync),
              label: const Text('Đồng bộ'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', null),
            const SizedBox(width: 8),
            _buildFilterChip('Thu nhập', 'income'),
            const SizedBox(width: 8),
            _buildFilterChip('Chi tiêu', 'expense'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = value);
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildTransactionsList(List<models.Transaction> transactions) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(models.Transaction transaction) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final isSelected = _selectedTransactionIds.contains(transaction.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(transaction.id);
          } else {
            _showTransactionDetail(transaction);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode();
            _toggleSelection(transaction.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSelection(transaction.id),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (transaction.isIncome ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: transaction.isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (transaction.category != null) ...[
                          Text(
                            transaction.category!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Text(' • '),
                        ],
                        Text(
                          DateFormat('dd/MM/yyyy').format(transaction.postedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${transaction.isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 150,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có giao dịch',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kết nối ngân hàng để tự động đồng bộ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    final errorMessage = error.toString();
    final isAuthError = errorMessage.contains('đăng nhập') || 
                        errorMessage.contains('401') ||
                        errorMessage.contains('Unauthorized');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuthError ? Icons.lock_outline : Icons.error_outline, 
              size: 64, 
              color: isAuthError ? AppColors.primary : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isAuthError ? 'Cần đăng nhập' : 'Lỗi tải dữ liệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isAuthError 
                  ? 'Vui lòng đăng nhập để xem giao dịch'
                  : errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isAuthError)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(transactionsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.filterTransactions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text(AppStrings.selectDateRange),
                subtitle: _startDate != null && _endDate != null
                    ? Text('${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}')
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showDateRangePicker,
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text(AppStrings.selectCategory),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showCategoryPicker,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                          _selectedCategoryId = null;
                          final now = DateTime.now();
                          _startDate = DateTime(now.year, now.month, 1);
                          _endDate = DateTime(now.year, now.month + 1, 0);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _showCategoryPicker() async {
    final categoriesAsync = ref.read(categoriesProvider);
    
    categoriesAsync.when(
      data: (categories) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chọn danh mục'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Tất cả'),
                    leading: const Icon(Icons.all_inclusive),
                    onTap: () {
                      setState(() => _selectedCategoryId = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...categories.map((cat) => ListTile(
                    title: Text(cat.name),
                    leading: const Icon(Icons.category),
                    onTap: () {
                      setState(() => _selectedCategoryId = cat.id);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {},
      error: (e, s) {},
    );
  }

  void _showTransactionDetail(models.Transaction transaction) {
    final categoriesAsync = ref.read(categoriesProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TransactionDetailSheet(
        transaction: transaction,
        categories: categoriesAsync,
        onUpdate: () {
          ref.invalidate(transactionsProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactionIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _selectAll(AsyncValue<Map<String, dynamic>> transactionsAsync) {
    transactionsAsync.whenData((data) {
      final transactions = data['transactions'] as List<models.Transaction>;
      setState(() {
        if (_selectedTransactionIds.length == transactions.length) {
          _selectedTransactionIds.clear();
        } else {
          _selectedTransactionIds.clear();
          _selectedTransactionIds.addAll(transactions.map((t) => t.id));
        }
      });
    });
  }

  Future<void> _showBulkCategoryDialog() async {
    final categoriesAsync = ref.read(categoriesProvider);
    
    categoriesAsync.when(
      data: (categories) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chọn danh mục'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: categories.map((cat) => ListTile(
                  title: Text(cat.name),
                  leading: const Icon(Icons.category),
                  onTap: () {
                    Navigator.pop(context);
                    _performBulkUpdate(cat.id);
                  },
                )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ],
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh mục...')),
        );
      },
      error: (e, s) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      },
    );
  }

  Future<void> _performBulkUpdate(int categoryId) async {
    if (_selectedTransactionIds.isEmpty) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final service = ref.read(transactionServiceProvider);
      final result = await service.bulkUpdateCategory(
        transactionIds: _selectedTransactionIds.toList(),
        categoryId: categoryId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        final successCount = result['successCount'] as int;
        final failedCount = result['failedCount'] as int;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount > 0
                  ? 'Đã cập nhật $successCount giao dịch, $failedCount thất bại'
                  : 'Đã cập nhật $successCount giao dịch',
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );

        // Refresh transactions list
        ref.invalidate(transactionsProvider);

        // Exit selection mode
        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔄 Đồng bộ & Test Webhook',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn hành động để test tích hợp Sepay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, color: AppColors.primary),
                ),
                title: const Text('Làm mới giao dịch'),
                subtitle: const Text('Tải lại danh sách từ server'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _refreshTransactions();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle, color: AppColors.income),
                ),
                title: const Text('Test: Tiền vào'),
                subtitle: const Text('Giả lập nhận tiền từ Sepay'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showSimulateDialog('in');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_circle, color: AppColors.expense),
                ),
                title: const Text('Test: Tiền ra'),
                subtitle: const Text('Giả lập chi tiền từ Sepay'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showSimulateDialog('out');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.blue),
                ),
                title: const Text('Liên kết tài khoản'),
                subtitle: const Text('Thêm tài khoản ngân hàng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showLinkAccountDialog();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.orange),
                ),
                title: const Text('Webhook Logs'),
                subtitle: const Text('Xem lịch sử webhook'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showWebhookLogs();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code, color: Colors.purple),
                ),
                title: const Text('Raw Webhook JSON'),
                subtitle: const Text('Xem JSON từ Sepay'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showRawWebhookLogs();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshTransactions() async {
    ref.invalidate(transactionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm mới danh sách giao dịch'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSimulateDialog(String type) {
    final amountController = TextEditingController(text: '100000');
    final contentController = TextEditingController(
      text: type == 'in' ? 'CHUYEN TIEN TEST' : 'GRAB FOOD thanh toan',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'in' ? '💰 Test: Tiền vào' : '💸 Test: Tiền ra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung chuyển khoản',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateWebhook(
                type: type,
                amount: double.tryParse(amountController.text) ?? 100000,
                content: contentController.text,
              );
            },
            child: const Text('Gửi Test'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateWebhook({
    required String type,
    required double amount,
    required String content,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(transactionServiceProvider);
      final result = await service.simulateWebhook(
        amount: amount,
        type: type,
        content: content,
      );

      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message'] ?? 'Webhook đã gửi thành công!'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh transactions after 1 second
        await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(transactionsProvider);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLinkAccountDialog() {
    final accountController = TextEditingController();
    String selectedBank = 'MBBANK';

    final banks = [
      {'code': 'MBBANK', 'name': 'MB Bank'},
      {'code': 'VCB', 'name': 'Vietcombank'},
      {'code': 'TCB', 'name': 'Techcombank'},
      {'code': 'BIDV', 'name': 'BIDV'},
      {'code': 'ACB', 'name': 'ACB'},
      {'code': 'VPB', 'name': 'VPBank'},
      {'code': 'TPB', 'name': 'TPBank'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🏦 Liên kết tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Chọn ngân hàng',
                  border: OutlineInputBorder(),
                ),
                items: banks.map((bank) => DropdownMenuItem(
                  value: bank['code'],
                  child: Text(bank['name']!),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedBank = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                  hintText: 'VD: 0123456789',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (accountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập số tài khoản')),
                  );
                  return;
                }
                Navigator.pop(context);
                _linkAccount(accountController.text, selectedBank);
              },
              child: const Text('Liên kết'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkAccount(String accountNumber, String bankCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(transactionServiceProvider);
      final result = await service.linkBankAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
      );

      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message'] ?? 'Đã liên kết tài khoản!'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showRawWebhookLogs() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(transactionServiceProvider);
      final result = await service.getRawWebhookLogs();

      if (mounted) {
        Navigator.pop(context);
        
        final webhooks = result['webhooks'] as List? ?? [];
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📦 Raw Webhook JSON'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: webhooks.isEmpty
                  ? const Center(
                      child: Text('Chưa có webhook nào được nhận'),
                    )
                  : ListView.builder(
                      itemCount: webhooks.length,
                      itemBuilder: (context, index) {
                        final webhook = webhooks[index];
                        final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
                        final createdAt = webhook['createdAt'] != null
                            ? DateTime.parse(webhook['createdAt'])
                            : null;
                        
                        return ExpansionTile(
                          leading: Icon(
                            webhook['processed'] == true
                                ? Icons.check_circle
                                : Icons.pending,
                            color: webhook['processed'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(
                            webhook['accountNumber'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: createdAt != null
                              ? Text(dateFormat.format(createdAt))
                              : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Raw JSON:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      _formatJson(webhook['rawPayload']),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (webhook['errorMessage'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: ${webhook['errorMessage']}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _formatJson(dynamic json) {
    try {
      if (json is Map || json is List) {
        // Convert to pretty JSON string
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(json);
      }
      return json.toString();
    } catch (e) {
      return json.toString();
    }
  }

  Future<void> _showWebhookLogs() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(transactionServiceProvider);
      final result = await service.getWebhookLogs();

      if (mounted) {
        Navigator.pop(context);
        
        final transactions = result['transactions'] as List? ?? [];
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📋 Webhook Logs'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: transactions.isEmpty
                  ? const Center(
                      child: Text('Chưa có webhook nào được nhận'),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final formatter = NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                          decimalDigits: 0,
                        );
                        return ListTile(
                          leading: Icon(
                            tx['type'] == 'income'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: tx['type'] == 'income'
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                          title: Text(
                            tx['rawDescription'] ?? 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${tx['bankAccount']?['bankName'] ?? 'Unknown'} • ${tx['createdAt']?.toString().substring(0, 16) ?? ''}',
                          ),
                          trailing: Text(
                            formatter.format(tx['amount'] ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx['type'] == 'income'
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _TransactionDetailSheet extends ConsumerStatefulWidget {
  final models.Transaction transaction;
  final AsyncValue<List<models.Category>> categories;
  final VoidCallback onUpdate;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.categories,
    required this.onUpdate,
  });

  @override
  ConsumerState<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends ConsumerState<_TransactionDetailSheet> {
  late int? _selectedCategoryId;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.transaction.category?.id;
    _notesController = TextEditingController(text: widget.transaction.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chi tiết giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Mô tả', widget.transaction.description),
                _buildDetailRow('Số tiền', formatter.format(widget.transaction.amount)),
                _buildDetailRow('Loại', widget.transaction.isIncome ? 'Thu nhập' : 'Chi tiêu'),
                _buildDetailRow('Danh mục', widget.transaction.category?.name ?? 'Chưa phân loại'),
                _buildDetailRow('Ngày', DateFormat('dd/MM/yyyy HH:mm').format(widget.transaction.postedAt)),
                const SizedBox(height: 24),
                Text(
                  AppStrings.changeCategory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                widget.categories.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Lỗi: $e'),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.notes,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Thêm ghi chú...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(transactionServiceProvider);

      // Update category if changed
      if (_selectedCategoryId != null && _selectedCategoryId != widget.transaction.category?.id) {
        await service.updateTransactionCategory(widget.transaction.id, _selectedCategoryId!);
      }

      // Update notes if changed
      if (_notesController.text != (widget.transaction.notes ?? '')) {
        await service.updateTransactionNotes(widget.transaction.id, _notesController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thay đổi')),
        );
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
