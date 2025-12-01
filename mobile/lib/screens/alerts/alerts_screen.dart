import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/alert_provider.dart';
import '../../services/alert_service.dart';
import '../../core/theme/app_theme.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertNotifierProvider.notifier).loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (alertState.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(alertNotifierProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Đọc tất cả'),
            ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _showUnreadOnly = value;
              });
              ref.read(alertNotifierProvider.notifier).loadAlerts(
                unreadOnly: value,
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      _showUnreadOnly ? Icons.radio_button_off : Icons.radio_button_on,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tất cả'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      _showUnreadOnly ? Icons.radio_button_on : Icons.radio_button_off,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Chưa đọc'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(alertNotifierProvider.notifier).loadAlerts(
            unreadOnly: _showUnreadOnly,
          );
        },
        child: alertState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : alertState.error != null
                ? _buildErrorState(alertState.error!)
                : alertState.alerts.isEmpty
                    ? _buildEmptyState()
                    : _buildAlertList(alertState.alerts, isDark),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              ref.read(alertNotifierProvider.notifier).loadAlerts();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly ? 'Không có thông báo chưa đọc' : 'Không có thông báo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các cảnh báo chi tiêu sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(List<AlertItem> alerts, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertItem(alert, isDark);
      },
    );
  }

  Widget _buildAlertItem(AlertItem alert, bool isDark) {
    final backgroundColor = alert.readFlag
        ? (isDark ? Colors.grey[900] : Colors.white)
        : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05));

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(alertNotifierProvider.notifier).deleteAlert(alert.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!alert.readFlag) {
              ref.read(alertNotifierProvider.notifier).markAsRead(alert.id);
            }
            _showAlertDetail(alert);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlertIcon(alert),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getAlertColor(alert.alertType).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              alert.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getAlertColor(alert.alertType),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!alert.readFlag)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alert.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: alert.readFlag ? FontWeight.normal : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(alert.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertIcon(AlertItem alert) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getAlertColor(alert.alertType).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          alert.typeIcon,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Color _getAlertColor(String alertType) {
    switch (alertType) {
      case 'BUDGET_WARNING':
        return Colors.orange;
      case 'BUDGET_EXCEEDED':
        return Colors.red;
      case 'LARGE_TRANSACTION':
        return Colors.purple;
      case 'UNUSUAL_SPENDING':
        return Colors.amber;
      case 'CATEGORY_SPIKE':
        return Colors.deepOrange;
      case 'SUCCESS':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  void _showAlertDetail(AlertItem alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      _buildAlertIcon(alert),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.typeLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(alert.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    alert.message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (alert.payload.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...alert.payload.entries.map((entry) {
                      if (entry.key == 'type') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPayloadKey(entry.key),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              _formatPayloadValue(entry.value),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPayloadKey(String key) {
    final keyMap = {
      'amount': 'Số tiền',
      'averageAmount': 'Trung bình',
      'multiplier': 'Hệ số',
      'description': 'Mô tả',
      'categoryName': 'Danh mục',
      'currentSpending': 'Chi tiêu hiện tại',
      'averageSpending': 'Chi tiêu trung bình',
      'spikePercentage': 'Tỷ lệ tăng',
      'spent': 'Đã chi',
      'limit': 'Hạn mức',
      'percentage': 'Phần trăm',
    };
    return keyMap[key] ?? key;
  }

  String _formatPayloadValue(dynamic value) {
    if (value is num) {
      if (value > 1000) {
        return NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
          decimalDigits: 0,
        ).format(value);
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

