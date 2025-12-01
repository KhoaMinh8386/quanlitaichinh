# API URL Configuration Fix

## 🐛 Problem

Backend was returning **404 errors** for all API calls:

```
POST /api/api/auth/login 404    ❌ Double /api prefix
GET /api/health 404             ❌ Health check not found
```

## 🔍 Root Cause

**Double `/api` prefix issue:**
- Backend routes: `app.use('/api/auth', authRoutes)` 
- Mobile base URL: `http://10.0.2.2:3001/api`
- Service calls: `/api/auth/login`
- **Result**: `/api` + `/api/auth/login` = `/api/api/auth/login` ❌

## ✅ Solution

### 1. Fixed Mobile Base URL
**File:** `mobile/lib/core/config/app_config.dart`

**Before:**
```dart
defaultValue: 'http://10.0.2.2:3001/api',
```

**After:**
```dart
defaultValue: 'http://10.0.2.2:3001',
```

### 2. Added Health Check with /api Prefix
**File:** `backend/src/index.ts`

**Before:**
```typescript
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

**After:**
```typescript
// Health check (both with and without /api prefix for compatibility)
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

### 3. Increased API Timeouts
**File:** `mobile/lib/services/api_client.dart`

**Changed:**
- `connectTimeout`: 30s → 60s
- `receiveTimeout`: 30s → 60s
- Added `sendTimeout`: 60s

## 📊 URL Structure

### Correct Flow:
```
Mobile Base URL:    http://10.0.2.2:3001
Service Call:       /api/auth/login
Final URL:          http://10.0.2.2:3001/api/auth/login ✅
Backend Route:      app.use('/api/auth', authRoutes) ✅
```

### Backend Routes:
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
GET    /api/transactions
POST   /api/transactions
GET    /api/budgets/summary
POST   /api/budgets
DELETE /api/budgets/:id
GET    /api/categories
GET    /api/reports/overview
GET    /api/categorization/patterns
POST   /api/categorization/auto-categorize
GET    /api/forecast
GET    /api/alerts
GET    /health
GET    /api/health
```

## 🧪 Testing

### Test Backend Health:
```bash
curl http://localhost:3001/health
# Response: {"status":"ok","timestamp":"..."}

curl http://localhost:3001/api/health
# Response: {"status":"ok","timestamp":"..."}
```

### Test Auth Endpoint:
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Test from Mobile:
1. Run backend: `cd backend && npm run dev`
2. Run mobile: `cd mobile && flutter run`
3. Try to login/register
4. Should work without 404 errors

## 📝 Configuration Summary

### Backend (.env):
```env
PORT=3001
DATABASE_URL=postgresql://postgres:zzz@localhost:5432/financial_management
```

### Mobile (app_config.dart):
```dart
apiBaseUrl = 'http://10.0.2.2:3001'  // No /api suffix
```

### Service Calls (all services):
```dart
await _apiClient.post('/api/auth/login', ...)  // With /api prefix
await _apiClient.get('/api/budgets/summary', ...)
await _apiClient.get('/api/categories', ...)
```

## ✅ Verification Checklist

- [x] Backend running on port 3001
- [x] Health check accessible at `/health` and `/api/health`
- [x] Mobile base URL set to `http://10.0.2.2:3001`
- [x] All service calls include `/api` prefix
- [x] No double `/api/api` in logs
- [x] Timeouts increased to 60s
- [x] No compilation errors

## 🚀 Next Steps

1. **Start Backend:**
   ```bash
   cd backend
   npm run dev
   ```

2. **Start Mobile:**
   ```bash
   cd mobile
   flutter run
   ```

3. **Test Features:**
   - Login/Register
   - View Dashboard
   - View Transactions
   - View Budgets
   - All API calls should work

## 🔧 Troubleshooting

### Still Getting 404?
- Check backend logs for actual URL being called
- Verify no extra `/api` in service calls
- Clear app cache and rebuild

### Connection Timeout?
- Ensure backend is running
- Check PostgreSQL is running
- Verify port 3001 is not blocked by firewall

### Database Errors?
```bash
cd backend
npx prisma migrate dev
npx prisma db seed
```

---

**Status:** ✅ Fixed
**Date:** November 29, 2024
**Files Modified:** 3
