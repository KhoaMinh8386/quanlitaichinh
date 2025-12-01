import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final alertServiceProvider = Provider<AlertService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AlertService(apiClient);
});

class AlertService {
  final ApiClient _apiClient;

  AlertService(this._apiClient);

  /// Get all alerts for current user
  Future<AlertsResponse> getAlerts({bool unreadOnly = false}) async {
    try {
      final response = await _apiClient.get(
        '/api/alerts',
        queryParameters: {
          'unreadOnly': unreadOnly.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return AlertsResponse.fromJson(data);
      }
      throw Exception('Failed to fetch alerts');
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread alert count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/api/alerts/count');

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark an alert as read
  Future<bool> markAsRead(String alertId) async {
    try {
      final response = await _apiClient.patch('/api/alerts/$alertId/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Mark all alerts as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.patch('/api/alerts/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete an alert
  Future<bool> deleteAlert(String alertId) async {
    try {
      final response = await _apiClient.delete('/api/alerts/$alertId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Response models
class AlertsResponse {
  final List<AlertItem> alerts;
  final int unreadCount;

  AlertsResponse({
    required this.alerts,
    required this.unreadCount,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    return AlertsResponse(
      alerts: (json['alerts'] as List?)
          ?.map((e) => AlertItem.fromJson(e))
          .toList() ?? [],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class AlertItem {
  final String id;
  final String alertType;
  final String message;
  final Map<String, dynamic> payload;
  final bool readFlag;
  final DateTime createdAt;

  AlertItem({
    required this.id,
    required this.alertType,
    required this.message,
    required this.payload,
    required this.readFlag,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] ?? '',
      alertType: json['alertType'] ?? '',
      message: json['message'] ?? '',
      payload: json['payload'] ?? {},
      readFlag: json['readFlag'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get typeIcon {
    switch (alertType) {
      case 'BUDGET_WARNING':
        return '⚠️';
      case 'BUDGET_EXCEEDED':
        return '🔴';
      case 'LARGE_TRANSACTION':
        return '💰';
      case 'UNUSUAL_SPENDING':
        return '⚡';
      case 'CATEGORY_SPIKE':
        return '📈';
      case 'INFO':
        return 'ℹ️';
      case 'SUCCESS':
        return '✅';
      default:
        return '🔔';
    }
  }

  String get typeLabel {
    switch (alertType) {
      case 'BUDGET_WARNING':
        return 'Cảnh báo ngân sách';
      case 'BUDGET_EXCEEDED':
        return 'Vượt ngân sách';
      case 'LARGE_TRANSACTION':
        return 'Giao dịch lớn';
      case 'UNUSUAL_SPENDING':
        return 'Chi tiêu bất thường';
      case 'CATEGORY_SPIKE':
        return 'Tăng đột biến';
      case 'INFO':
        return 'Thông báo';
      case 'SUCCESS':
        return 'Thành công';
      default:
        return 'Thông báo';
    }
  }
}

