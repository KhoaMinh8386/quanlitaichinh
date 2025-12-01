# Advanced Financial Management System

Hệ thống Quản lý Tài chính Cá nhân Nâng Cao - Ứng dụng mobile Flutter với backend Node.js/Express và PostgreSQL. **Tích hợp Sepay** để tự động đồng bộ giao dịch ngân hàng Việt Nam.

## 🚀 Tính năng

### Mobile App (Flutter)
- ✅ **Onboarding** - Giới thiệu tính năng app
- ✅ **Authentication** - Đăng ký/Đăng nhập với JWT
- ✅ **Dashboard** - Tổng quan tài chính với charts
- ✅ **Transactions** - Quản lý giao dịch thu/chi
- ✅ **Budgets** - Theo dõi ngân sách theo danh mục
- ✅ **Reports** - Báo cáo chi tiết với biểu đồ
- ✅ **Forecast** - Dự báo tài chính dựa trên lịch sử
- ✅ **Settings** - Cài đặt và quản lý tài khoản
- ✅ **Alerts** - Cảnh báo chi tiêu bất thường

### Backend API (Node.js/Express)
- ✅ **Authentication** - JWT với refresh token
- ✅ **User Management** - Quản lý người dùng
- ✅ **Database** - PostgreSQL với Prisma ORM
- ✅ **Security** - Password hashing, token encryption
- ✅ **Error Handling** - Comprehensive error handling
- ✅ **Sepay Integration** - Tích hợp Sepay Webhook để tự động đồng bộ giao dịch
- ✅ **Auto Categorization** - Phân loại giao dịch tự động theo keyword
- ✅ **Analytics** - Phân tích chi tiêu và dự báo tài chính
- ✅ **Smart Alerts** - Cảnh báo giao dịch lớn, chi tiêu bất thường

## 📋 Yêu cầu

### Backend
- Node.js 18+
- PostgreSQL 14+
- npm hoặc yarn

### Mobile
- Flutter 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode
- Android Emulator / iOS Simulator

## 🛠️ Cài đặt

### 1. Backend Setup

```bash
cd backend

# Cài đặt dependencies
npm install

# Cấu hình database trong .env
# DATABASE_URL=postgresql://user:password@localhost:5432/financial_management

# Chạy migrations
npm run prisma:migrate

# Seed database với dữ liệu mẫu
npm run prisma:seed

# Chạy backend
npm run dev
```

Backend sẽ chạy tại: `http://localhost:3001`

### 2. Mobile Setup

```bash
cd mobile

# Cài đặt dependencies
flutter pub get

# Generate code (Freezed models)
flutter pub run build_runner build --delete-conflicting-outputs

# Chạy app trên emulator
flutter run
```

## 🔧 Configuration

### Backend (.env)
```env
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://postgres:password@localhost:5432/financial_management
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key
ENCRYPTION_KEY=your-encryption-key

# Sepay Integration
SEPAY_API_KEY=your-sepay-api-key
SEPAY_WEBHOOK_SECRET=your-sepay-webhook-secret
SEPAY_BASE_URL=https://my.sepay.vn/userapi

# Alert Thresholds (optional)
SEPAY_LARGE_TRANSACTION_THRESHOLD=5000000
SEPAY_LARGE_TRANSACTION_MULTIPLIER=3
SEPAY_CATEGORY_SPIKE_THRESHOLD=150
```

### Mobile (lib/core/config/app_config.dart)
```dart
// Android emulator: 10.0.2.2
// iOS simulator: localhost
static const String apiBaseUrl = 'http://10.0.2.2:3001';
```

## 📱 Demo Account

Sau khi seed database, bạn có thể đăng nhập với:
- **Email**: demo@example.com
- **Password**: Demo123456!

## 🏗️ Cấu trúc Project

```
.
├── backend/                 # Node.js/Express API
│   ├── src/
│   │   ├── config/         # Configuration
│   │   ├── controllers/    # Request handlers
│   │   ├── services/       # Business logic
│   │   ├── middlewares/    # Express middlewares
│   │   └── routes/         # API routes
│   ├── prisma/             # Database schema & migrations
│   └── __tests__/          # Tests
│
└── mobile/                  # Flutter Mobile App
    ├── lib/
    │   ├── core/           # Core utilities, theme, constants
    │   ├── models/         # Data models (Freezed)
    │   ├── services/       # API services
    │   ├── providers/      # State management (Riverpod)
    │   └── screens/        # UI screens
    └── test/               # Tests
```

## 🧪 Testing

### Backend
```bash
cd backend
npm test
```

### Mobile
```bash
cd mobile
flutter test
```

## 🎨 Design

App được thiết kế theo Material Design 3 với:
- Gradient purple-cyan theme
- Smooth animations
- Interactive charts (fl_chart)
- Vietnamese language

## 🔐 Security

- Password hashing với bcrypt (12 rounds)
- JWT authentication với refresh tokens
- Secure token storage (flutter_secure_storage)
- HTTPS-only communication (production)
- Input validation
- SQL injection prevention (Prisma)

## 📊 Tech Stack

### Backend
- **Framework**: Express.js
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT (jsonwebtoken)
- **Security**: bcrypt, helmet, cors
- **Testing**: Jest, Supertest

### Mobile
- **Framework**: Flutter
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Charts**: FL Chart
- **Storage**: flutter_secure_storage
- **Code Generation**: Freezed, json_serializable

## 🚀 Deployment

### Backend
1. Set `NODE_ENV=production`
2. Update database URL
3. Set strong JWT secrets
4. Enable HTTPS
5. Deploy to Heroku/AWS/DigitalOcean

### Mobile
1. Update API base URL
2. Build release APK/IPA
3. Submit to Play Store/App Store

## 📝 API Documentation

### Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/refresh-token` - Refresh token

### Transactions
- `GET /api/transactions` - Danh sách giao dịch
- `POST /api/transactions` - Tạo giao dịch thủ công
- `PATCH /api/transactions/:id/category` - Đổi danh mục

### Budgets
- `GET /api/budgets` - Danh sách ngân sách
- `GET /api/budgets/:month` - Ngân sách theo tháng (YYYY-MM)
- `POST /api/budgets` - Tạo/cập nhật ngân sách

### Analytics
- `GET /api/analytics/summary` - Tổng quan chi tiêu
- `GET /api/analytics/timeseries` - Dữ liệu time series
- `GET /api/analytics/forecast` - Dự báo chi tiêu
- `GET /api/analytics/top-categories` - Top danh mục

### Alerts
- `GET /api/alerts` - Danh sách cảnh báo
- `PATCH /api/alerts/:id/read` - Đánh dấu đã đọc
- `PATCH /api/alerts/read-all` - Đánh dấu tất cả đã đọc

### Sepay Integration
- `GET /api/sepay/test` - Test kết nối Sepay
- `POST /api/sepay/webhook/public` - Webhook nhận giao dịch từ Sepay (public, không cần auth)
- `GET /api/sepay/webhook/info` - Xem thông tin webhook URL để cấu hình
- `GET /api/sepay/webhook/raw` - Xem raw JSON từ webhook (sau khi đăng nhập)
- `POST /api/sepay/sync` - Đồng bộ giao dịch từ Sepay
- `POST /api/sepay/link-account` - Liên kết tài khoản ngân hàng

## 🔔 Sepay Webhook Integration

### Cấu hình Webhook tại Sepay

1. Truy cập [Sepay Dashboard](https://my.sepay.vn)
2. Thêm Webhook URL: `https://quanlitaichinh.onrender.com/api/sepay/webhook/public`
   - ⚠️ **Lưu ý**: Dùng URL Render (production), webhook từ Sepay sẽ gửi đến đây
   - Backend local chỉ để test, không nhận webhook thực từ Sepay
3. Lấy Webhook Secret và thêm vào `.env` trên Render

### Payload mẫu từ Sepay

```json
{
  "id": 12345,
  "gateway": "MBBANK",
  "transactionDate": "2025-01-15T10:30:00Z",
  "accountNumber": "0123456789",
  "content": "GRAB FOOD DON HANG GF123456",
  "transferType": "out",
  "transferAmount": 75000,
  "referenceCode": "MB_REF_123456"
}
```

### Tự động phân loại

Hệ thống tự động phân loại giao dịch dựa trên các keyword:
- **Food**: GRAB FOOD, SHOPEE FOOD, BAEMIN, HIGHLAND, STARBUCKS
- **Transport**: GRAB, GOJEK, BE, TAXI, PETROLIMEX
- **Bills**: TIEN DIEN, EVN, VNPT, VIETTEL
- **Shopping**: SHOPEE, LAZADA, TIKI
- **Entertainment**: NETFLIX, CGV, SPOTIFY

### Cảnh báo tự động

- 💰 **Giao dịch lớn**: Số tiền > 5.000.000 VND
- ⚡ **Chi tiêu bất thường**: Giao dịch > 3x mức trung bình
- 📈 **Tăng đột biến**: Danh mục tăng > 150% so với 3 tháng trước
- 🔴 **Vượt ngân sách**: Chi tiêu > 100% ngân sách
- ⚠️ **Cảnh báo ngân sách**: Chi tiêu > 80% ngân sách

## 🤝 Contributing

1. Fork the project
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License

## 👥 Authors

- Your Name

## 🙏 Acknowledgments

- Flutter team
- Prisma team
- All open source contributors
