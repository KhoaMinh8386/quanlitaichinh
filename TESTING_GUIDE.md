# Testing Guide - Advanced Financial Management System

## 🧪 Hướng dẫn Test Hệ thống

### Prerequisites

1. **Backend đang chạy:**
```bash
cd backend
npm run dev
# Server should be running on http://localhost:3000
```

2. **Database đã được seed:**
```bash
cd backend
npx prisma db seed
```

## 📋 Test Scenarios

### 1. Authentication Flow

#### Test Register
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

**Expected Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "test@example.com",
    "fullName": "Test User"
  },
  "tokens": {
    "accessToken": "jwt-token",
    "refreshToken": "jwt-refresh-token",
    "expiresIn": "15m"
  }
}
```

#### Test Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### Test Refresh Token
```bash
curl -X POST http://localhost:3000/api/auth/refresh-token \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "your-refresh-token"
  }'
```

### 2. Transaction Management

#### Get Transactions (với authentication)
```bash
curl -X GET "http://localhost:3000/api/transactions?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Transaction Stats
```bash
curl -X GET "http://localhost:3000/api/transactions/stats?from=2024-01-01&to=2024-12-31" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Update Transaction Category
```bash
curl -X PATCH http://localhost:3000/api/categorization/transactions/TRANSACTION_ID/category \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "categoryId": 1
  }'
```

### 3. Auto-Categorization

#### Auto-categorize All Pending
```bash
curl -X POST http://localhost:3000/api/categorization/auto-categorize \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "message": "Auto-categorization completed",
  "categorizedCount": 15
}
```

#### Get Categorization Patterns
```bash
curl -X GET http://localhost:3000/api/categorization/patterns \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Budget Management

#### Get Budget Summary
```bash
curl -X GET "http://localhost:3000/api/budgets/summary?month=12&year=2024" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "month": 12,
  "year": 2024,
  "totalBudget": 10000000,
  "totalSpent": 7500000,
  "usagePercentage": 75,
  "categories": [
    {
      "budgetId": "uuid",
      "category": {
        "id": 1,
        "name": "Food",
        "icon": "restaurant",
        "color": "#FF6B6B"
      },
      "limit": 3000000,
      "spent": 2500000,
      "remaining": 500000,
      "percentage": 83.33,
      "status": "warning"
    }
  ]
}
```

#### Create/Update Budget
```bash
curl -X POST http://localhost:3000/api/budgets \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "month": 12,
    "year": 2024,
    "categoryId": 1,
    "amountLimit": 3000000
  }'
```

### 5. Budget Alerts

#### Check Budgets and Create Alerts
```bash
curl -X POST "http://localhost:3000/api/alerts/check-budgets?month=12&year=2024" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get All Alerts
```bash
curl -X GET http://localhost:3000/api/alerts \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Unread Count
```bash
curl -X GET http://localhost:3000/api/alerts/unread-count \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "count": 3
}
```

#### Mark Alert as Read
```bash
curl -X PATCH http://localhost:3000/api/alerts/ALERT_ID/read \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6. Financial Forecast

#### Get Next Month Forecast
```bash
curl -X GET http://localhost:3000/api/forecast/next-month \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (with enough data):**
```json
{
  "hasEnoughData": true,
  "historicalData": {
    "months": [
      {
        "month": 6,
        "year": 2024,
        "income": 15000000,
        "expense": 12000000,
        "savings": 3000000
      }
    ],
    "averages": {
      "income": 15000000,
      "expense": 12000000,
      "savings": 3000000,
      "savingsRate": 20
    }
  },
  "prediction": {
    "month": 1,
    "year": 2025,
    "predictedIncome": 15500000,
    "predictedExpense": 12300000,
    "predictedSavings": 3200000
  },
  "recommendations": [
    "Good start! Aim to increase your savings rate to 20% or more for better financial health.",
    "Your financial health looks good. Continue monitoring your spending and saving regularly."
  ],
  "chartData": {
    "historical": [
      {"x": "2024-06", "y": 12000000}
    ],
    "predicted": [
      {"x": "2025-01", "y": 12300000}
    ]
  }
}
```

**Expected Response (insufficient data):**
```json
{
  "hasEnoughData": false,
  "warningMessage": "Insufficient data for forecast. Need at least 3 months of transaction history. Currently have 1 months.",
  "recommendations": [
    "Continue tracking your transactions for more accurate predictions",
    "Connect your bank accounts to automatically sync transactions"
  ]
}
```

### 7. Reports & Analytics

#### Get Overview
```bash
curl -X GET "http://localhost:3000/api/reports/overview?from=2024-01-01&to=2024-12-31" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "totalIncome": 180000000,
  "totalExpense": 144000000,
  "netSavings": 36000000,
  "savingsRate": 20,
  "categoryBreakdown": [
    {
      "categoryId": 1,
      "categoryName": "Food",
      "color": "#FF6B6B",
      "amount": 45000000,
      "percentage": 31.25
    },
    {
      "categoryId": 2,
      "categoryName": "Transport",
      "color": "#4ECDC4",
      "amount": 30000000,
      "percentage": 20.83
    }
  ]
}
```

#### Get Category Breakdown
```bash
curl -X GET "http://localhost:3000/api/reports/category-breakdown?from=2024-01-01&to=2024-12-31" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 8. Categories

#### Get All Categories
```bash
curl -X GET http://localhost:3000/api/categories \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Categories by Type
```bash
curl -X GET "http://localhost:3000/api/categories?type=expense" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 🧪 Mobile App Testing

### 1. Setup Test Environment

Update `mobile/lib/core/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String apiBaseUrl = 'http://localhost:3000/api'; // iOS simulator
  // static const String apiBaseUrl = 'http://YOUR_IP:3000/api'; // Physical device
}
```

### 2. Test Authentication Flow

1. **Launch app** - Should show onboarding screen
2. **Navigate to Register** - Fill form and submit
3. **Verify registration** - Should navigate to main screen
4. **Logout** - Should return to login screen
5. **Login** - Use registered credentials
6. **Verify token refresh** - Wait 15+ minutes, app should auto-refresh token

### 3. Test Dashboard

1. **View dashboard** - Should show:
   - User name in header
   - Balance card with real data
   - Category spending chart
   - Recent transactions

2. **Pull to refresh** - Should reload data

3. **Error handling** - Turn off backend, should show error message

### 4. Test Transactions

1. **View transactions list** - Should show paginated list
2. **Filter transactions** - Test date range, type, category filters
3. **Update category** - Change transaction category
4. **Add notes** - Add notes to transaction
5. **Verify auto-categorization** - New transactions should be auto-categorized

### 5. Test Budgets

1. **View budget summary** - Should show current month budgets
2. **Create budget** - Add new budget for category
3. **Update budget** - Modify existing budget
4. **Delete budget** - Remove budget
5. **Check status colors** - Warning (orange) at 80%, Exceeded (red) at 100%

### 6. Test Alerts

1. **View alerts** - Should show list of alerts
2. **Mark as read** - Alert should update
3. **Delete alert** - Alert should be removed
4. **Unread count** - Badge should show correct count

### 7. Test Forecast

1. **View forecast** - Should show predictions or warning
2. **Check recommendations** - Should display actionable advice
3. **View chart** - Historical and predicted data should render

### 8. Test Reports

1. **View overview** - Should show income/expense/savings
2. **Category breakdown** - Should show pie chart
3. **Date range filter** - Should update data

## 🐛 Common Issues & Solutions

### Issue 1: "Network Error"
**Solution:** Check if backend is running and API URL is correct

### Issue 2: "401 Unauthorized"
**Solution:** Token expired, logout and login again

### Issue 3: "Insufficient data for forecast"
**Solution:** Add more transactions (need at least 3 months)

### Issue 4: "Category not found"
**Solution:** Run database seed to create default categories

### Issue 5: Mobile app can't connect to backend
**Solution:** 
- Android emulator: Use `10.0.2.2` instead of `localhost`
- iOS simulator: Use `localhost`
- Physical device: Use your computer's IP address

## 📊 Test Data Generation

### Create Test Transactions (SQL)
```sql
-- Insert test transactions for current month
INSERT INTO transactions (user_id, bank_account_id, posted_at, amount, type, raw_description, normalized_description, category_id, classification_source)
SELECT 
  'YOUR_USER_ID',
  'YOUR_ACCOUNT_ID',
  NOW() - (random() * interval '30 days'),
  (random() * 1000000)::numeric(15,2),
  CASE WHEN random() > 0.7 THEN 'income' ELSE 'expense' END,
  'Test transaction',
  'Test transaction',
  (SELECT id FROM categories WHERE is_default = true ORDER BY random() LIMIT 1),
  'AUTO'
FROM generate_series(1, 50);
```

### Create Test Budgets (SQL)
```sql
-- Insert test budgets for current month
INSERT INTO budgets (user_id, month, year, category_id, amount_limit)
SELECT 
  'YOUR_USER_ID',
  EXTRACT(MONTH FROM NOW())::integer,
  EXTRACT(YEAR FROM NOW())::integer,
  id,
  3000000
FROM categories 
WHERE is_default = true AND type = 'expense'
LIMIT 5;
```

## ✅ Test Checklist

### Backend API:
- [ ] Authentication (register, login, refresh)
- [ ] Transaction CRUD operations
- [ ] Auto-categorization
- [ ] Budget management
- [ ] Alert generation
- [ ] Forecast calculation
- [ ] Reports generation
- [ ] Error handling
- [ ] Input validation
- [ ] Token expiration

### Mobile App:
- [ ] Authentication flow
- [ ] Dashboard data loading
- [ ] Transaction list & filters
- [ ] Budget management
- [ ] Alert notifications
- [ ] Forecast display
- [ ] Reports & charts
- [ ] Error handling
- [ ] Loading states
- [ ] Offline behavior

### Integration:
- [ ] End-to-end user flow
- [ ] Token refresh mechanism
- [ ] Real-time data updates
- [ ] Cross-platform compatibility
- [ ] Performance under load

## 📝 Test Report Template

```markdown
## Test Report - [Date]

### Environment:
- Backend: Running on port 3000
- Database: PostgreSQL 14
- Mobile: Flutter 3.x on [Device/Emulator]

### Test Results:

#### Authentication: ✅ PASS
- Register: ✅
- Login: ✅
- Token Refresh: ✅

#### Transactions: ✅ PASS
- List: ✅
- Filter: ✅
- Update: ✅

#### Auto-Categorization: ✅ PASS
- Pattern Matching: ✅
- Learning: ✅
- MCC-based: ✅

#### Budgets: ✅ PASS
- Create: ✅
- Summary: ✅
- Status: ✅

#### Alerts: ✅ PASS
- Generation: ✅
- Read/Unread: ✅

#### Forecast: ✅ PASS
- Calculation: ✅
- Recommendations: ✅

#### Reports: ✅ PASS
- Overview: ✅
- Breakdown: ✅

### Issues Found:
1. [Issue description]
2. [Issue description]

### Recommendations:
1. [Recommendation]
2. [Recommendation]
```

---

**Happy Testing! 🚀**
