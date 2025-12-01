# Financial Management Backend API

Backend API cho ứng dụng quản lý tài chính cá nhân tại Việt Nam với tích hợp Sepay.

## Công nghệ sử dụng

- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL với Prisma ORM
- **Authentication**: JWT (Access Token + Refresh Token)
- **External API**: Sepay (đồng bộ giao dịch ngân hàng)

## Cài đặt

### 1. Clone và cài đặt dependencies

```bash
cd backend
npm install
```

### 2. Cấu hình môi trường

Tạo file `.env` từ template:

```bash
cp .env.example .env
```

Cập nhật các biến môi trường:

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/financial_management"

# JWT
JWT_SECRET="your-super-secret-jwt-key-at-least-32-chars"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-at-least-32-chars"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# Server
PORT=3000
NODE_ENV=development

# Sepay Integration
SEPAY_API_KEY="your-sepay-api-key"
SEPAY_WEBHOOK_SECRET="your-sepay-webhook-secret"
SEPAY_BASE_URL="https://my.sepay.vn/userapi"

# Alert Thresholds (optional)
SEPAY_LARGE_TRANSACTION_THRESHOLD=5000000
SEPAY_LARGE_TRANSACTION_MULTIPLIER=3
SEPAY_CATEGORY_SPIKE_THRESHOLD=150
```

### 3. Khởi tạo database

```bash
# Tạo migration
npx prisma migrate dev

# Generate Prisma Client
npx prisma generate

# Seed dữ liệu mẫu
npm run prisma:seed
```

### 4. Chạy server

```bash
# Development
npm run dev

# Production
npm run build
npm start
```

Server sẽ chạy tại `http://localhost:3000`

## API Endpoints

### Authentication

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký tài khoản |
| POST | `/api/auth/login` | Đăng nhập |
| POST | `/api/auth/refresh-token` | Làm mới token |
| POST | `/api/auth/logout` | Đăng xuất |

### Transactions

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/transactions` | Lấy danh sách giao dịch |
| GET | `/api/transactions/:id` | Chi tiết giao dịch |
| POST | `/api/transactions` | Tạo giao dịch thủ công |
| PATCH | `/api/transactions/:id` | Cập nhật giao dịch |
| PATCH | `/api/transactions/:id/category` | Đổi danh mục |

### Categories

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/categories` | Danh sách danh mục |
| POST | `/api/categories` | Tạo danh mục mới |
| PATCH | `/api/categories/:id` | Cập nhật danh mục |
| DELETE | `/api/categories/:id` | Xóa danh mục |

### Budgets

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/budgets` | Danh sách ngân sách |
| GET | `/api/budgets/:month` | Ngân sách theo tháng (YYYY-MM) |
| POST | `/api/budgets` | Tạo/cập nhật ngân sách |

### Analytics

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/analytics/summary` | Tổng quan chi tiêu |
| GET | `/api/analytics/timeseries` | Dữ liệu time series |
| GET | `/api/analytics/forecast` | Dự báo chi tiêu |
| GET | `/api/analytics/top-categories` | Top danh mục chi tiêu |
| GET | `/api/analytics/comparison` | So sánh kỳ trước |

### Alerts

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/alerts` | Danh sách cảnh báo |
| GET | `/api/alerts/count` | Số cảnh báo chưa đọc |
| PATCH | `/api/alerts/:id/read` | Đánh dấu đã đọc |
| PATCH | `/api/alerts/read-all` | Đánh dấu tất cả đã đọc |
| DELETE | `/api/alerts/:id` | Xóa cảnh báo |

### Sepay Integration

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/sepay/test` | Test kết nối Sepay |
| GET | `/api/sepay/accounts` | Danh sách tài khoản |
| GET | `/api/sepay/transactions` | Lấy giao dịch từ Sepay |
| POST | `/api/sepay/webhook/public` | Webhook nhận giao dịch (public) |
| POST | `/api/sepay/webhook` | Webhook nhận giao dịch (auth) |
| POST | `/api/sepay/sync` | Đồng bộ giao dịch |
| POST | `/api/sepay/link-account` | Liên kết tài khoản |

## Cấu hình Sepay Webhook

### 1. Đăng ký Webhook tại Sepay

Truy cập [Sepay Dashboard](https://my.sepay.vn) và đăng ký webhook URL:

```
https://your-domain.com/api/sepay/webhook/public
```

### 2. Cấu hình Webhook Secret

Lấy Webhook Secret từ Sepay và thêm vào file `.env`:

```env
SEPAY_WEBHOOK_SECRET="your-webhook-secret-from-sepay"
```

### 3. Payload mẫu từ Sepay

```json
{
  "id": 12345,
  "gateway": "MBBANK",
  "transactionDate": "2025-01-15T10:30:00Z",
  "accountNumber": "0123456789",
  "subAccount": null,
  "code": null,
  "content": "GRAB FOOD DON HANG GF123456",
  "transferType": "out",
  "description": "Payment for Grab Food",
  "transferAmount": 75000,
  "referenceCode": "MB_REF_123456",
  "accumulated": 5000000
}
```

### 4. Headers từ Sepay

```
x-sepay-signature: sha256-hmac-signature
x-sepay-timestamp: 1705312200000
```

## Phân loại giao dịch tự động

Hệ thống sử dụng `category_rules` để tự động phân loại giao dịch dựa trên mô tả:

### Các từ khóa được hỗ trợ

| Danh mục | Từ khóa |
|----------|---------|
| Food | GRAB FOOD, SHOPEE FOOD, BAEMIN, HIGHLAND, STARBUCKS, CAFE, NHA HANG |
| Transport | GRAB, GOJEK, BE, TAXI, PETROLIMEX, VIETJET |
| Bills | TIEN DIEN, EVN, TIEN NUOC, VNPT, FPT, VIETTEL |
| Shopping | SHOPEE, LAZADA, TIKI, SENDO, THEGIOIDIDONG |
| Entertainment | NETFLIX, SPOTIFY, CGV, KARAOKE, GYM |
| Health | BENH VIEN, NHA THUOC, PRUDENTIAL, BAO HIEM |
| Education | HOC PHI, UDEMY, COURSERA, FAHASA |

### Thêm rule mới

Khi người dùng đổi danh mục và chọn "Nhớ lần sau", hệ thống sẽ tự động học:

```typescript
// API endpoint
PATCH /api/transactions/:id/category
{
  "categoryId": 1,
  "rememberRule": true
}
```

## Cảnh báo chi tiêu

Hệ thống tự động tạo cảnh báo trong các trường hợp:

### 1. Giao dịch lớn (LARGE_TRANSACTION)
- Số tiền > 5.000.000 VND (có thể tùy chỉnh)

### 2. Chi tiêu bất thường (UNUSUAL_SPENDING)
- Giao dịch > 3 lần mức chi trung bình 30 ngày

### 3. Tăng đột biến theo danh mục (CATEGORY_SPIKE)
- Chi tiêu danh mục tăng > 150% so với trung bình 3 tháng trước

### 4. Vượt ngân sách (BUDGET_EXCEEDED)
- Chi tiêu > 100% ngân sách đã đặt

### 5. Cảnh báo ngân sách (BUDGET_WARNING)
- Chi tiêu > 80% ngân sách đã đặt

## Testing

```bash
# Chạy tất cả tests
npm test

# Chạy test với watch mode
npm run test:watch
```

## Tài khoản Demo

Sau khi seed database:

```
Email: demo@example.com
Password: Demo123456!
```

## Cấu trúc thư mục

```
backend/
├── prisma/
│   ├── migrations/          # Database migrations
│   ├── schema.prisma        # Prisma schema
│   └── seed.ts              # Seed data
├── src/
│   ├── __tests__/           # Unit tests
│   ├── config/              # Configuration files
│   │   ├── env.ts           # Environment variables
│   │   ├── database.ts      # Database config
│   │   └── sepay.ts         # Sepay config
│   ├── controllers/         # Request handlers
│   │   ├── auth.controller.ts
│   │   ├── transaction.controller.ts
│   │   ├── sepay.controller.ts
│   │   └── analytics.controller.ts
│   ├── middlewares/         # Express middlewares
│   │   ├── auth.ts
│   │   └── errorHandler.ts
│   ├── routes/              # API routes
│   ├── services/            # Business logic
│   │   ├── sepay.service.ts
│   │   ├── categorization.service.ts
│   │   ├── analytics.service.ts
│   │   └── alert.service.ts
│   ├── utils/               # Utility functions
│   └── index.ts             # Application entry
├── package.json
└── tsconfig.json
```

## License

MIT
