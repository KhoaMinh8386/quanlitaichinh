# Fix Lỗi Type Casting Trong Reports Screen

## Vấn Đề
Khi vào trang báo cáo, ứng dụng bị crash với lỗi:
```
type 'int' is not a subtype of type 'double'
```

## Nguyên Nhân
- Dữ liệu từ API backend (Node.js/PostgreSQL) có thể trả về kiểu `int` hoặc `double`
- Code Flutter expect tất cả số là `double`
- Khi gọi `.toDouble()` trực tiếp trên giá trị có thể là `int`, sẽ gây lỗi runtime

### Ví Dụ Lỗi
```dart
// ❌ Lỗi khi value là int
final totalSpent = (merchant['totalSpent'] ?? 0.0).toDouble();

// Nếu API trả về: { "totalSpent": 1000 } (int)
// Thì (1000 ?? 0.0) = 1000 (vẫn là int)
// Gọi 1000.toDouble() sẽ lỗi vì 1000 đã là int, không phải num
```

## Giải Pháp

### 1. Tạo NumberUtils Helper (mobile/lib/core/utils/number_utils.dart)

```dart
class NumberUtils {
  /// Safely converts a dynamic value to double
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }

  /// Safely converts a dynamic value to int
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    
    return defaultValue;
  }
}
```

### 2. Cập Nhật Reports Screen

**Trước:**
```dart
final totalSpent = (merchant['totalSpent'] ?? 0.0).toDouble();
final transactionCount = merchant['transactionCount'] ?? 0;
final percentage = (merchant['percentage'] ?? 0.0).toDouble();
```

**Sau:**
```dart
final totalSpent = NumberUtils.toDouble(merchant['totalSpent']);
final transactionCount = NumberUtils.toInt(merchant['transactionCount']);
final percentage = NumberUtils.toDouble(merchant['percentage']);
```

### 3. Cập Nhật Dashboard Screen

**Trước:**
```dart
final totalIncome = (report['totalIncome'] as num?)?.toDouble() ?? 0.0;
final totalExpense = (report['totalExpense'] as num?)?.toDouble() ?? 0.0;
```

**Sau:**
```dart
final totalIncome = NumberUtils.toDouble(report['totalIncome']);
final totalExpense = NumberUtils.toDouble(report['totalExpense']);
```

## Các File Đã Sửa

### 1. mobile/lib/core/utils/number_utils.dart (NEW)
- ✅ Tạo helper class cho safe type conversion
- ✅ Hỗ trợ convert từ int, double, String
- ✅ Có default value
- ✅ Bonus: formatCurrency và formatNumber methods

### 2. mobile/lib/screens/reports/reports_screen.dart
Cập nhật các methods:
- ✅ `_buildSummaryCardsFromData()` - totalIncome, totalExpense
- ✅ `_buildOverviewCard()` - totalIncome, totalExpense, savings, savingsRate
- ✅ `_buildCategoryPieChartFromData()` - percentage
- ✅ `_buildCategoryItemFromData()` - totalAmount, transactionCount, percentage
- ✅ `_buildMerchantItem()` - totalSpent, transactionCount, averageAmount, percentage
- ✅ `_buildComparisonSummary()` - month1Total, month2Total
- ✅ `_buildComparisonChangeItem()` - difference, percentageChange
- ✅ `_buildYearComparisonSummary()` - year1Total, year2Total, difference, percentageChange
- ✅ `_buildYearTrendItem()` - year1Total, year2Total, change, percentageChange

### 3. mobile/lib/screens/dashboard/dashboard_screen.dart
- ✅ `_buildBalanceCard()` - totalIncome, totalExpense, netSavings

## Lợi Ích

### 1. Robust Type Handling
- ✅ Xử lý an toàn cả int và double
- ✅ Không crash khi type không match
- ✅ Có default value hợp lý

### 2. Cleaner Code
```dart
// Trước: Dài dòng và dễ lỗi
final value = (data['field'] ?? 0.0).toDouble();

// Sau: Ngắn gọn và an toàn
final value = NumberUtils.toDouble(data['field']);
```

### 3. Consistent Behavior
- Tất cả số đều được xử lý giống nhau
- Dễ maintain và debug
- Tránh duplicate code

### 4. Future-Proof
- Dễ dàng thêm format methods
- Có thể handle thêm các type khác
- Centralized number handling logic

## Testing

### Test Cases

#### 1. Int Value
```dart
final result = NumberUtils.toDouble(1000);
// Expected: 1000.0 (double)
```

#### 2. Double Value
```dart
final result = NumberUtils.toDouble(1000.5);
// Expected: 1000.5 (double)
```

#### 3. Null Value
```dart
final result = NumberUtils.toDouble(null);
// Expected: 0.0 (default)
```

#### 4. String Value
```dart
final result = NumberUtils.toDouble("1000.5");
// Expected: 1000.5 (double)
```

#### 5. Invalid String
```dart
final result = NumberUtils.toDouble("invalid");
// Expected: 0.0 (default)
```

### Manual Testing
1. ✅ Vào trang Reports
2. ✅ Kiểm tra tab Overview
3. ✅ Kiểm tra tab By Category
4. ✅ Kiểm tra tab Merchant
5. ✅ Kiểm tra tab Comparison (Month/Year)
6. ✅ Kiểm tra Dashboard

## Bonus Features

### Format Currency
```dart
final formatted = NumberUtils.formatCurrency(1000000);
// Output: "1000000 đ"

final formatted = NumberUtils.formatCurrency(1000000, symbol: '$', decimals: 2);
// Output: "1000000.00 $"
```

### Format Number with Separators
```dart
final formatted = NumberUtils.formatNumber(1000000);
// Output: "1,000,000"

final formatted = NumberUtils.formatNumber(1000000.5, decimals: 2);
// Output: "1,000,000.50"
```

## Best Practices

### ✅ DO
```dart
// Use NumberUtils for all dynamic number conversions
final amount = NumberUtils.toDouble(data['amount']);
final count = NumberUtils.toInt(data['count']);
```

### ❌ DON'T
```dart
// Don't cast directly without checking type
final amount = (data['amount'] ?? 0.0).toDouble(); // ❌ Can crash

// Don't use as num? unless you're sure
final amount = (data['amount'] as num?)?.toDouble() ?? 0.0; // ❌ Verbose
```

## Future Enhancements

### Planned Features
1. **Decimal Precision Control**
   ```dart
   NumberUtils.toDouble(value, precision: 2)
   ```

2. **Range Validation**
   ```dart
   NumberUtils.toDouble(value, min: 0, max: 1000000)
   ```

3. **Currency Conversion**
   ```dart
   NumberUtils.convertCurrency(amount, from: 'USD', to: 'VND')
   ```

4. **Percentage Formatting**
   ```dart
   NumberUtils.formatPercentage(0.15) // "15%"
   ```

## Summary

✅ **Fixed**: Type casting error trong Reports screen
✅ **Created**: NumberUtils helper class
✅ **Updated**: Reports screen và Dashboard screen
✅ **Improved**: Code quality và maintainability
✅ **Prevented**: Future type casting errors

Ứng dụng giờ đây có thể xử lý an toàn mọi kiểu số từ API mà không bị crash! 🎉
