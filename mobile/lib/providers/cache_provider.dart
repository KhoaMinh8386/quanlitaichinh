import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple in-memory cache for comparison data
class CacheService {
  final Map<String, CachedData> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  T? get<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;
    
    if (DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }
    
    return cached.data as T?;
  }

  void set<T>(String key, T data) {
    _cache[key] = CachedData(data: data, timestamp: DateTime.now());
  }

  void clear([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) {
      return now.difference(value.timestamp) > _cacheDuration;
    });
  }
}

class CachedData {
  final dynamic data;
  final DateTime timestamp;

  CachedData({required this.data, required this.timestamp});
}

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// Cached providers for comparison data
final cachedMonthComparisonProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, cacheKey) async {
    final cache = ref.watch(cacheServiceProvider);
    return cache.get<Map<String, dynamic>>(cacheKey);
  },
);

final cachedYearComparisonProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, cacheKey) async {
    final cache = ref.watch(cacheServiceProvider);
    return cache.get<Map<String, dynamic>>(cacheKey);
  },
);

final cachedBudgetComparisonProvider = FutureProvider.family<dynamic, String>(
  (ref, cacheKey) async {
    final cache = ref.watch(cacheServiceProvider);
    return cache.get(cacheKey);
  },
);
