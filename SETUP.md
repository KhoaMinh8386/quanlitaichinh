# Advanced Financial Management System - Setup Guide

This guide will help you set up both the backend API and mobile application.

## Prerequisites

### Backend
- Node.js 18+ and npm
- PostgreSQL 14+
- Git

### Mobile
- Flutter SDK 3.0.0+
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

## Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
```

4. Edit `.env` and configure your database connection:
```
DATABASE_URL=postgresql://username:password@localhost:5432/financial_management
```

5. Generate Prisma client:
```bash
npm run prisma:generate
```

6. Run database migrations:
```bash
npm run prisma:migrate
```

7. Seed the database with default data:
```bash
npm run prisma:seed
```

This will create:
- Default expense categories (Food, Transport, Bills, etc.)
- Default income categories (Salary, Business Income, etc.)
- Sample bank providers for testing
- Demo user account:
  - Email: `demo@example.com`
  - Password: `Demo123456!`

8. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Testing the Backend

Run tests:
```bash
npm test
```

Run tests in watch mode:
```bash
npm run test:watch
```

## Mobile Setup

1. Navigate to the mobile directory:
```bash
cd mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Start the app:

For Android:
```bash
flutter run
```

For iOS (macOS only):
```bash
flutter run
```

For a specific device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### Testing the Mobile App

Run tests:
```bash
flutter test
```

## Project Structure

### Backend (`/backend`)
```
backend/
├── prisma/
│   ├── migrations/      # Database migrations
│   ├── schema.prisma    # Database schema
│   └── seed.ts          # Seed data script
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Request handlers
│   ├── services/        # Business logic
│   ├── repositories/    # Data access layer
│   ├── middlewares/     # Express middlewares
│   ├── routes/          # API routes
│   ├── utils/           # Utility functions
│   └── index.ts         # Application entry point
├── package.json
└── tsconfig.json
```

### Mobile (`/mobile`)
```
mobile/
├── lib/
│   ├── core/            # Core utilities and configuration
│   ├── models/          # Data models
│   ├── services/        # API and local services
│   ├── providers/       # Riverpod state management
│   ├── screens/         # Screen widgets
│   ├── widgets/         # Reusable widgets
│   └── main.dart        # Application entry point
├── test/                # Tests
├── pubspec.yaml
└── analysis_options.yaml
```

## Database Schema

The system uses PostgreSQL with the following main tables:

- `users` - User accounts
- `bank_providers` - Supported bank providers
- `bank_connections` - OAuth connections to banks
- `bank_accounts` - User's linked bank accounts
- `categories` - Transaction categories
- `transactions` - Financial transactions
- `budgets` - Monthly budgets
- `alerts` - User notifications
- `category_patterns` - Auto-categorization patterns

## API Endpoints (To be implemented)

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/banks/providers` - List bank providers
- `GET /api/banks/connect-url` - Get OAuth URL
- `GET /api/bank-accounts` - List bank accounts
- `POST /api/bank-accounts/:id/sync-transactions` - Sync transactions
- `GET /api/transactions` - List transactions
- `PATCH /api/transactions/:id/category` - Update category
- `GET /api/budgets/summary` - Get budget summary
- `POST /api/budgets` - Create/update budget
- `GET /api/reports/overview` - Get spending overview
- `GET /api/forecast/next-month` - Get financial forecast
- `GET /api/alerts` - List alerts

## Next Steps

After completing the setup:

1. Review the requirements document: `.kiro/specs/advanced-financial-management/requirements.md`
2. Review the design document: `.kiro/specs/advanced-financial-management/design.md`
3. Check the task list: `.kiro/specs/advanced-financial-management/tasks.md`
4. Start implementing the next task (Task 2: Authentication and Authorization)

## Troubleshooting

### Backend Issues

**Database connection errors:**
- Ensure PostgreSQL is running
- Verify DATABASE_URL in `.env` is correct
- Check that the database exists

**Migration errors:**
- Try resetting the database: `npx prisma migrate reset`
- This will drop all data and re-run migrations

### Mobile Issues

**Dependency errors:**
- Run `flutter clean` then `flutter pub get`
- Delete `pubspec.lock` and run `flutter pub get` again

**Build errors:**
- Run `flutter pub run build_runner clean`
- Then `flutter pub run build_runner build --delete-conflicting-outputs`

## Support

For issues or questions, refer to:
- Backend README: `backend/README.md`
- Mobile README: `mobile/README.md`
- Design document: `.kiro/specs/advanced-financial-management/design.md`
