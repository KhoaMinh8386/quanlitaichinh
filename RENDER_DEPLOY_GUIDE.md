# 🚀 Hướng dẫn Deploy lên Render.com

## Ưu điểm của Render.com:
- ✅ **Miễn phí hoàn toàn** (750 giờ/tháng)
- ✅ **Không cần thẻ tín dụng**
- ✅ **URL cố định vĩnh viễn**
- ✅ **PostgreSQL miễn phí** (90 ngày)
- ✅ **Auto deploy từ GitHub**

---

## 📋 Các bước Deploy

### Bước 1: Push code lên GitHub

```bash
cd C:\FlutterCUOIKI
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Bước 2: Đăng ký Render.com

1. Truy cập: https://render.com
2. Click **"Get Started for Free"**
3. Đăng ký bằng **GitHub** (khuyến nghị)

### Bước 3: Tạo PostgreSQL Database

1. Trong Render Dashboard, click **"New +"** → **"PostgreSQL"**
2. Điền thông tin:
   - **Name**: `financial-db`
   - **Region**: `Singapore`
   - **Plan**: `Free`
3. Click **"Create Database"**
4. **Copy "External Database URL"** (sẽ dùng ở bước sau)

### Bước 4: Deploy Backend

1. Click **"New +"** → **"Web Service"**
2. Chọn **"Build and deploy from a Git repository"**
3. Connect GitHub repo của bạn
4. Cấu hình:
   - **Name**: `financial-management-api`
   - **Region**: `Singapore`
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm run start:prod`
   - **Plan**: `Free`

5. Click **"Advanced"** → Thêm **Environment Variables**:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | (paste External Database URL từ bước 3) |
| `JWT_SECRET` | (tạo random string 32+ ký tự) |
| `JWT_REFRESH_SECRET` | (tạo random string 32+ ký tự) |
| `JWT_EXPIRES_IN` | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | `7d` |
| `SEPAY_WEBHOOK_SECRET` | (từ Sepay Dashboard) |
| `SEPAY_API_KEY` | (từ Sepay Dashboard) |
| `SEPAY_BASE_URL` | `https://my.sepay.vn/userapi` |

6. Click **"Create Web Service"**

### Bước 5: Đợi Deploy hoàn tất

- Render sẽ tự động build và deploy
- Sau khoảng 5-10 phút, bạn sẽ có URL như:
  ```
  https://financial-management-api.onrender.com
  ```

---

## 🔗 URL Webhook cho Sepay

Sau khi deploy xong, URL webhook sẽ là:

```
https://YOUR-APP-NAME.onrender.com/api/sepay/webhook/public
```

Ví dụ:
```
https://financial-management-api.onrender.com/api/sepay/webhook/public
```

---

## 🧪 Test Webhook

```bash
curl -X POST https://YOUR-APP-NAME.onrender.com/api/sepay/webhook/public \
  -H "Content-Type: application/json" \
  -d '{
    "id": 12345,
    "gateway": "MBBank",
    "transactionDate": "2024-12-01 10:30:00",
    "accountNumber": "0903139361",
    "content": "GRAB FOOD test",
    "transferType": "out",
    "transferAmount": 75000,
    "referenceCode": "TEST_123"
  }'
```

---

## ⚠️ Lưu ý quan trọng

1. **Free tier PostgreSQL** của Render chỉ tồn tại **90 ngày**, sau đó cần upgrade hoặc tạo mới.

2. **Free tier Web Service** sẽ **sleep sau 15 phút không hoạt động**. Request đầu tiên sau khi sleep sẽ mất ~30 giây để wake up.

3. Để tránh sleep, bạn có thể:
   - Upgrade lên paid plan ($7/tháng)
   - Hoặc dùng UptimeRobot (free) để ping mỗi 10 phút

---

## 🔄 Auto Deploy

Mỗi khi bạn push code lên GitHub, Render sẽ tự động re-deploy!

---

## 📞 Hỗ trợ

- Render Docs: https://render.com/docs
- Render Discord: https://discord.gg/render

