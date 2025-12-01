import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/api_client.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionService(apiClient);
});

final transactionsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, TransactionFilters>(
  (ref, filters) async {
    final service = ref.watch(transactionServiceProvider);
    return await service.getTransactions(
      from: filters.from,
      to: filters.to,
      type: filters.type,
      categoryId: filters.categoryId,
      accountId: filters.accountId,
      page: filters.page,
      limit: filters.limit,
    );
  },
);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(transactionServiceProvider);
  return await service.getCategories();
});

final transactionStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, DateRange>(
  (ref, dateRange) async {
    final service = ref.watch(transactionServiceProvider);
    return await service.getTransactionStats(
      from: dateRange.from,
      to: dateRange.to,
    );
  },
);

class TransactionFilters {
  final DateTime? from;
  final DateTime? to;
  final String? type;
  final int? categoryId;
  final String? accountId;
  final int page;
  final int limit;

  TransactionFilters({
    this.from,
    this.to,
    this.type,
    this.categoryId,
    this.accountId,
    this.page = 1,
    this.limit = 20,
  });
}

class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({required this.from, required this.to});
}
