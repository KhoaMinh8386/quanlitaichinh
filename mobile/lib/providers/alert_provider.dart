import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/alert_service.dart';

// Alert state
class AlertState {
  final List<AlertItem> alerts;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  AlertState({
    this.alerts = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  AlertState copyWith({
    List<AlertItem>? alerts,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Alert notifier
class AlertNotifier extends StateNotifier<AlertState> {
  final AlertService _alertService;

  AlertNotifier(this._alertService) : super(AlertState());

  Future<void> loadAlerts({bool unreadOnly = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _alertService.getAlerts(unreadOnly: unreadOnly);
      state = state.copyWith(
        alerts: response.alerts,
        unreadCount: response.unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _alertService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> markAsRead(String alertId) async {
    final success = await _alertService.markAsRead(alertId);
    if (success) {
      final updatedAlerts = state.alerts.map((alert) {
        if (alert.id == alertId) {
          return AlertItem(
            id: alert.id,
            alertType: alert.alertType,
            message: alert.message,
            payload: alert.payload,
            readFlag: true,
            createdAt: alert.createdAt,
          );
        }
        return alert;
      }).toList();
      
      final newUnreadCount = updatedAlerts.where((a) => !a.readFlag).length;
      state = state.copyWith(
        alerts: updatedAlerts,
        unreadCount: newUnreadCount,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _alertService.markAllAsRead();
    if (success) {
      final updatedAlerts = state.alerts.map((alert) {
        return AlertItem(
          id: alert.id,
          alertType: alert.alertType,
          message: alert.message,
          payload: alert.payload,
          readFlag: true,
          createdAt: alert.createdAt,
        );
      }).toList();
      
      state = state.copyWith(
        alerts: updatedAlerts,
        unreadCount: 0,
      );
    }
  }

  Future<void> deleteAlert(String alertId) async {
    final success = await _alertService.deleteAlert(alertId);
    if (success) {
      final updatedAlerts = state.alerts.where((a) => a.id != alertId).toList();
      final newUnreadCount = updatedAlerts.where((a) => !a.readFlag).length;
      state = state.copyWith(
        alerts: updatedAlerts,
        unreadCount: newUnreadCount,
      );
    }
  }
}

// Providers
final alertNotifierProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  final alertService = ref.read(alertServiceProvider);
  return AlertNotifier(alertService);
});

final unreadAlertCountProvider = Provider<int>((ref) {
  return ref.watch(alertNotifierProvider).unreadCount;
});

