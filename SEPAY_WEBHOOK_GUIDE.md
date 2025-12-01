# Hướng dẫn Tích hợp Sepay Webhook

## 📌 Thông tin Webhook

### Endpoint URL
```
POST https://your-domain.com/api/sepay/webhook/public
```

**Lưu ý**: Endpoint này KHÔNG yêu cầu authentication vì Sepay sẽ gọi trực tiếp.

### Development/Local Testing
```
POST http://localhost:3000/api/sepay/webhook/public
```

---

## 🔧 Cấu hình tại Sepay

### Bước 1: Đăng nhập Sepay Dashboard
1. Truy cập [https://my.sepay.vn](https://my.sepay.vn)
2. Đăng nhập với tài khoản Sepay của bạn

### Bước 2: Thêm Webhook
1. Vào mục **Cài đặt** > **Webhook**
2. Thêm URL webhook: `https://your-domain.com/api/sepay/webhook/public`
3. Chọn các sự kiện muốn nhận: **Giao dịch mới**
4. Lưu cấu hình

### Bước 3: Lấy Webhook Secret (nếu có)
- Copy Webhook Secret và thêm vào file `.env`:
```env
SEPAY_WEBHOOK_SECRET=your-webhook-secret
```

---

## 📦 Payload Format từ Sepay

```json
{
  "id": 93,
  "gateway": "MBBank",
  "transactionDate": "2024-07-11 23:30:10",
  "accountNumber": "0381000123456",
  "code": null,
  "content": "NGUYEN VAN A chuyen tien GD 123456",
  "transferType": "in",
  "transferAmount": 100000,
  "accumulated": 500000,
  "subAccount": null,
  "referenceCode": "FT24193929399",
  "description": ""
}
```

### Giải thích các trường:

| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | number | ID giao dịch từ Sepay |
| `gateway` | string | Tên ngân hàng (MBBank, Vietcombank, Techcombank...) |
| `transactionDate` | string | Thời gian giao dịch (YYYY-MM-DD HH:mm:ss) |
| `accountNumber` | string | Số tài khoản nhận |
| `content` | string | Nội dung chuyển khoản |
| `transferType` | string | Loại: `"in"` (nhận) hoặc `"out"` (chuyển) |
| `transferAmount` | number | Số tiền giao dịch (VND) |
| `accumulated` | number | Số dư sau giao dịch |
| `referenceCode` | string | Mã tham chiếu giao dịch |

---

## 🧪 Test Webhook

### Cách 1: Sử dụng cURL

```bash
# Test giao dịch chi (expense)
curl -X POST http://localhost:3000/api/sepay/webhook/public \
  -H "Content-Type: application/json" \
  -d '{
    "id": 12345,
    "gateway": "MBBank",
    "transactionDate": "2024-12-01 10:30:00",
    "accountNumber": "0381000123456",
    "code": null,
    "content": "GRAB FOOD don hang GF123456",
    "transferType": "out",
    "transferAmount": 75000,
    "accumulated": 5000000,
    "subAccount": null,
    "referenceCode": "MB123456789",
    "description": ""
  }'
```

```bash
# Test giao dịch thu (income)
curl -X POST http://localhost:3000/api/sepay/webhook/public \
  -H "Content-Type: application/json" \
  -d '{
    "id": 12346,
    "gateway": "Vietcombank",
    "transactionDate": "2024-12-01 09:00:00",
    "accountNumber": "1234567890",
    "code": null,
    "content": "LUONG THANG 12",
    "transferType": "in",
    "transferAmount": 15000000,
    "accumulated": 20000000,
    "subAccount": null,
    "referenceCode": "VCB987654321",
    "description": "Salary December 2024"
  }'
```

### Cách 2: Sử dụng Postman

1. Tạo request mới: `POST http://localhost:3000/api/sepay/webhook/public`
2. Headers: `Content-Type: application/json`
3. Body (raw JSON):
```json
{
  "id": 12345,
  "gateway": "MBBank",
  "transactionDate": "2024-12-01 10:30:00",
  "accountNumber": "0381000123456",
  "content": "GRAB FOOD don hang",
  "transferType": "out",
  "transferAmount": 75000,
  "referenceCode": "TEST123456"
}
```

### Cách 3: Sử dụng Simulate Endpoint (yêu cầu đăng nhập)

```bash
# Đăng nhập trước
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@example.com", "password": "Demo123456!"}' \
  | jq -r '.tokens.accessToken')

# Simulate webhook
curl -X POST http://localhost:3000/api/sepay/webhook/simulate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amount": 150000,
    "type": "out",
    "content": "SHOPEE mua sam",
    "bankCode": "MBBANK"
  }'
```

---

## 🔗 Liên kết Tài khoản Ngân hàng

Trước khi webhook có thể match giao dịch với user, cần liên kết tài khoản:

```bash
curl -X POST http://localhost:3000/api/sepay/link-account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "accountNumber": "0381000123456",
    "bankCode": "MBBANK",
    "alias": "Tài khoản MB chính"
  }'
```

Sau khi liên kết, webhook sẽ tự động match giao dịch dựa trên 4 số cuối của tài khoản.

---

## 📊 Xem Logs Webhook

```bash
curl http://localhost:3000/api/sepay/webhook/logs \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "success": true,
  "transactions": [
    {
      "id": "uuid-xxx",
      "externalTxnId": "MB123456789",
      "amount": 75000,
      "type": "expense",
      "rawDescription": "GRAB FOOD don hang",
      "postedAt": "2024-12-01T10:30:00.000Z",
      "bankAccount": {
        "bankName": "MB Bank",
        "accountNumberMask": "******3456"
      },
      "category": {
        "name": "Food"
      }
    }
  ],
  "count": 1
}
```

---

## 🔔 Cảnh báo Tự động

Khi webhook nhận giao dịch, hệ thống tự động kiểm tra và tạo cảnh báo:

1. **Giao dịch lớn**: Số tiền > 5.000.000 VND
2. **Chi tiêu bất thường**: Giao dịch > 3 lần mức trung bình 30 ngày
3. **Tăng đột biến theo danh mục**: Danh mục tăng > 150% so với 3 tháng trước

---

## 🏷️ Phân loại Tự động

Hệ thống tự động phân loại giao dịch dựa trên `content`:

| Từ khóa | Danh mục |
|---------|----------|
| GRAB FOOD, SHOPEE FOOD, BAEMIN | Food |
| GRAB, GOJEK, BE, TAXI | Transport |
| TIEN DIEN, EVN, VNPT, VIETTEL | Bills |
| SHOPEE, LAZADA, TIKI | Shopping |
| NETFLIX, SPOTIFY, CGV | Entertainment |

---

## ⚠️ Xử lý Lỗi

Webhook luôn trả về HTTP 200 để Sepay biết đã nhận thành công:

```json
// Thành công
{ "success": true, "message": "Transaction processed", "transactionId": "uuid" }

// Trùng lặp (idempotent)
{ "success": true, "message": "Duplicate transaction" }

// Không tìm thấy user
{ "success": true, "message": "No matching user found" }

// Lỗi xử lý
{ "success": true, "message": "Error processing webhook: ..." }
```

---

## 🔐 Bảo mật

### Xác thực Signature (tùy chọn)

Nếu Sepay cung cấp webhook signature, hệ thống sẽ tự động xác thực:

```env
SEPAY_WEBHOOK_SECRET=your-secret-from-sepay
```

Headers từ Sepay:
```
x-sepay-signature: sha256-hmac-signature
x-sepay-timestamp: 1701432000000
```

---

## 📝 Ví dụ Response

### Webhook thành công:
```json
{
  "success": true,
  "message": "Transaction processed",
  "transactionId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Xem giao dịch đã tạo:
```bash
curl http://localhost:3000/api/transactions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

