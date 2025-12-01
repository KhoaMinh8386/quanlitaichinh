# Design Document

## Overview

The Advanced Financial Management System is a three-tier architecture application consisting of:

1. **Mobile Application (Flutter)**: Cross-platform mobile app providing user interface for financial management
2. **Backend API (Node.js/Express)**: RESTful API server handling business logic, bank integrations, and data processing
3. **Database (PostgreSQL)**: Relational database storing all application data with proper normalization and indexing

The system enables users to connect their bank accounts via OAuth2, automatically sync and categorize transactions, manage budgets, analyze spending patterns through interactive charts, and receive financial forecasts based on historical data.

### Key Design Principles

- **Security First**: All sensitive data encrypted, JWT-based authentication, HTTPS-only communication
- **Separation of Concerns**: Clear boundaries between presentation, business logic, and data layers
- **Scalability**: Stateless API design, indexed database queries, efficient data aggregation
- **User Experience**: Responsive UI, animated charts, real-time feedback, offline-capable where possible
- **Maintainability**: Modular code structure, comprehensive error handling, consistent naming conventions

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Dashboard │  │Transactions│ │ Budgets  │  │ Reports  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Forecast │  │  Alerts  │  │  Banks   │  │ Settings │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTPS/REST API
                          │ JWT Authentication
┌─────────────────────────▼───────────────────────────────────┐
│              Backend API (Node.js/Express)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Middleware Layer                         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │   Auth   │  │  Error   │  │ Logging  │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Controller Layer                         │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │   │
│  │  │ Auth │ │Banks │ │Trans │ │Budget│ │Report│      │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘      │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               Service Layer                           │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │   Auth   │  │  Banks   │  │  Trans   │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │ Category │  │  Budget  │  │ Forecast │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │             Repository Layer                          │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │   │
│  │  │Users │ │Banks │ │Trans │ │Budget│ │Alerts│      │   │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────┘
                          │ SQL Queries
┌─────────────────────────▼───────────────────────────────────┐
│                PostgreSQL Database                           │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│  │users │ │banks │ │trans │ │budget│ │alerts│ │categ │    │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │
└──────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│           External Bank Provider APIs (OAuth2)               │
└──────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Mobile (Flutter)**
- Dart SDK 3.0+
- State Management: Riverpod
- HTTP Client: dio
- Charts: fl_chart
- Secure Storage: flutter_secure_storage
- WebView: webview_flutter

**Backend (Node.js)**
- Node.js 18+
- Express.js 4.x
- PostgreSQL Client: pg
- ORM: Prisma
- Authentication: jsonwebtoken, bcrypt
- Encryption: crypto (AES-256-GCM)
- HTTP Client: axios
- Validation: joi

**Database**
- PostgreSQL 14+
- Connection Pooling
- Prepared Statements
- B-tree Indexes

## Components and Interfaces

### Backend Components

#### 1. Authentication Module

**Responsibilities:**
- User registration and login
- JWT token generation and validation
- Password hashing and verification
- Token refresh mechanism

**Key Classes/Services:**
- `AuthService`: Business logic for authentication
- `AuthController`: HTTP request handlers
- `AuthMiddleware`: JWT validation middleware
- `TokenService`: Token generation and refresh

**Interfaces:**
```typescript
interface AuthService {
  register(email: string, password: string, fullName: string): Promise<User>
  login(email: string, password: string): Promise<AuthTokens>
  refreshToken(refreshToken: string): Promise<AuthTokens>
  validateToken(token: string): Promise<TokenPayload>
}

interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}
```

#### 2. Bank Provider Module

**Responsibilities:**
- Manage bank provider configurations
- Handle OAuth2 authorization flow
- Token encryption/decryption
- Token refresh for expired connections

**Key Classes/Services:**
- `BankProviderService`: Provider management
- `BankConnectionService`: Connection lifecycle
- `OAuth2Service`: OAuth2 flow handling
- `EncryptionService`: Token encryption/decryption

**Interfaces:**
```typescript
interface BankProviderService {
  listProviders(): Promise<BankProvider[]>
  getAuthorizationUrl(providerId: string, userId: string): Promise<string>
  handleCallback(code: string, state: string): Promise<BankConnection>
  refreshConnection(connectionId: string): Promise<void>
}

interface BankConnection {
  id: string
  userId: string
  providerId: string
  accessToken: string  // encrypted
  refreshToken: string  // encrypted
  expiresAt: Date
  status: 'active' | 'expired' | 'disconnected'
}
```

#### 3. Bank Account Sync Module

**Responsibilities:**
- Fetch bank accounts from provider
- Sync transactions from bank API
- Normalize transaction data
- Prevent duplicate transactions

**Key Classes/Services:**
- `BankAccountService`: Account management
- `TransactionSyncService`: Transaction synchronization
- `BankApiClient`: HTTP client for bank APIs
- `TransactionNormalizer`: Data normalization

**Interfaces:**
```typescript
interface TransactionSyncService {
  syncTransactions(accountId: string): Promise<SyncResult>
  normalizeTransaction(rawTxn: any): Promise<NormalizedTransaction>
  isDuplicate(externalTxnId: string, userId: string): Promise<boolean>
}

interface SyncResult {
  newTransactions: number
  skippedDuplicates: number
  errors: string[]
}
```

#### 4. Transaction Categorization Module

**Responsibilities:**
- Auto-categorize transactions using rules
- Learn from manual categorizations
- Manage category patterns
- Handle uncategorized transactions
- Extract merchant information
- Prioritize patterns by confidence

**Key Classes/Services:**
- `CategorizationService`: Categorization logic
- `PatternMatcher`: Pattern matching engine
- `CategoryLearningService`: Learning from user input
- `MerchantExtractor`: Extract merchant names from descriptions

**Interfaces:**
```typescript
interface CategorizationService {
  categorizeTransaction(transaction: Transaction): Promise<Category>
  updateCategory(transactionId: string, categoryId: string): Promise<void>
  bulkUpdateCategory(transactionIds: string[], categoryId: string): Promise<BulkUpdateResult>
  learnPattern(description: string, categoryId: string): Promise<void>
  matchPattern(description: string, mcc?: string): Promise<Category | null>
  getPatterns(userId: string): Promise<CategoryPattern[]>
  extractMerchant(description: string): Promise<string | null>
}

interface CategoryPattern {
  id: number
  pattern: string  // regex or keyword
  patternType: 'merchant' | 'keyword' | 'mcc'
  categoryId: string
  confidence: number
  usageCount: number
  createdAt: Date
}

interface BulkUpdateResult {
  successCount: number
  failedCount: number
  failedIds: string[]
}
```

#### 5. Budget Management Module

**Responsibilities:**
- Create and update budgets
- Calculate budget usage
- Determine budget status
- Trigger budget alerts
- Track budget history
- Compare budgets across periods

**Key Classes/Services:**
- `BudgetService`: Budget CRUD operations
- `BudgetCalculator`: Usage calculations
- `BudgetAlertService`: Alert generation
- `BudgetHistoryService`: Historical analysis

**Interfaces:**
```typescript
interface BudgetService {
  createOrUpdateBudget(budget: BudgetInput): Promise<Budget>
  getBudgetSummary(userId: string, month: number, year: number): Promise<BudgetSummary>
  calculateUsage(budgetId: string): Promise<BudgetUsage>
  getBudgetHistory(userId: string, months: number): Promise<BudgetHistory[]>
  compareBudgets(userId: string, month1: MonthYear, month2: MonthYear): Promise<BudgetComparison>
}

interface BudgetSummary {
  totalBudget: number
  totalSpent: number
  usagePercentage: number
  status: 'normal' | 'warning' | 'exceeded'
  categories: CategoryBudget[]
}

interface BudgetHistory {
  month: number
  year: number
  totalBudget: number
  totalSpent: number
  usagePercentage: number
  categories: CategoryBudget[]
}

interface BudgetComparison {
  month1: BudgetSummary
  month2: BudgetSummary
  changes: Array<{
    categoryId: number
    categoryName: string
    spendingDifference: number
    percentageChange: number
  }>
  overallChange: {
    absoluteDifference: number
    percentageChange: number
  }
}
```

#### 6. Reports and Analytics Module

**Responsibilities:**
- Aggregate spending data
- Calculate statistics
- Generate chart data
- Compare time periods
- Analyze merchant spending
- Track spending trends

**Key Classes/Services:**
- `ReportService`: Report generation
- `AnalyticsService`: Data aggregation
- `ChartDataFormatter`: Format data for charts
- `TrendAnalyzer`: Analyze spending trends
- `MerchantAnalyzer`: Merchant-based analysis

**Interfaces:**
```typescript
interface ReportService {
  getOverview(userId: string, from: Date, to: Date): Promise<SpendingOverview>
  getCategoryBreakdown(userId: string, from: Date, to: Date): Promise<CategoryBreakdown[]>
  getAccountBreakdown(userId: string, from: Date, to: Date): Promise<AccountBreakdown[]>
  getMerchantBreakdown(userId: string, from: Date, to: Date): Promise<MerchantBreakdown[]>
  comparePeriods(userId: string, period1: DateRange, period2: DateRange): Promise<PeriodComparison>
  compareMonths(userId: string, month1: MonthYear, month2: MonthYear): Promise<MonthComparison>
  compareYears(userId: string, year1: number, year2: number): Promise<YearComparison>
}

interface SpendingOverview {
  totalIncome: number
  totalExpense: number
  netSavings: number
  dailyBreakdown: DailySpending[]
}

interface MerchantBreakdown {
  merchantName: string
  totalSpent: number
  transactionCount: number
  averageAmount: number
  category: string
  percentage: number
}

interface MonthComparison {
  month1: {
    month: number
    year: number
    totalSpent: number
    categoryBreakdown: CategoryBreakdown[]
  }
  month2: {
    month: number
    year: number
    totalSpent: number
    categoryBreakdown: CategoryBreakdown[]
  }
  changes: Array<{
    categoryId: number
    categoryName: string
    difference: number
    percentageChange: number
    trend: 'increase' | 'decrease' | 'stable'
  }>
}

interface YearComparison {
  year1: {
    year: number
    totalSpent: number
    monthlyBreakdown: MonthlySpending[]
  }
  year2: {
    year: number
    totalSpent: number
    monthlyBreakdown: MonthlySpending[]
  }
  annualChange: {
    difference: number
    percentageChange: number
  }
  categoryTrends: Array<{
    categoryId: number
    categoryName: string
    year1Total: number
    year2Total: number
    change: number
    percentageChange: number
  }>
}
```

#### 7. Forecast Module

**Responsibilities:**
- Analyze historical data
- Calculate trends
- Generate predictions
- Provide recommendations

**Key Classes/Services:**
- `ForecastService`: Forecast generation
- `TrendAnalyzer`: Trend calculation
- `RecommendationEngine`: Generate suggestions

**Interfaces:**
```typescript
interface ForecastService {
  generateForecast(userId: string): Promise<ForecastResult>
  analyzeHistory(userId: string, months: number): Promise<HistoricalAnalysis>
  calculateTrend(data: number[]): Promise<Trend>
}

interface ForecastResult {
  hasEnoughData: boolean
  historicalAverage: HistoricalAverage
  prediction: MonthlyPrediction
  recommendations: string[]
  chartData: ForecastChartData
}
```

### Mobile App Components

#### 1. State Management (Riverpod)

**Providers:**
- `authProvider`: Authentication state
- `userProvider`: Current user data
- `bankAccountsProvider`: List of bank accounts
- `transactionsProvider`: Transaction list with filters
- `budgetsProvider`: Budget data
- `dashboardProvider`: Dashboard summary
- `reportsProvider`: Report data
- `forecastProvider`: Forecast data

#### 2. Services Layer

**API Service:**
- `ApiClient`: HTTP client with interceptors
- `AuthService`: Authentication API calls
- `BankService`: Bank-related API calls
- `TransactionService`: Transaction API calls
- `BudgetService`: Budget API calls
- `ReportService`: Report API calls
- `ForecastService`: Forecast API calls

**Local Services:**
- `SecureStorageService`: Token storage
- `PreferencesService`: User preferences
- `CacheService`: Data caching

#### 3. UI Screens

**Screen Structure:**
```
lib/
  screens/
    auth/
      - login_screen.dart
      - register_screen.dart
    dashboard/
      - dashboard_screen.dart
      - widgets/
        - summary_card.dart
        - spending_chart.dart
        - category_donut.dart
    transactions/
      - transactions_screen.dart
      - transaction_detail_sheet.dart
      - widgets/
        - transaction_item.dart
        - transaction_filter.dart
    banks/
      - bank_accounts_screen.dart
      - bank_connection_screen.dart
      - oauth_webview.dart
    budgets/
      - budgets_screen.dart
      - budget_form_screen.dart
      - widgets/
        - budget_item.dart
        - progress_bar.dart
    reports/
      - reports_screen.dart
      - widgets/
        - line_chart_widget.dart
        - donut_chart_widget.dart
        - bar_chart_widget.dart
    forecast/
      - forecast_screen.dart
      - widgets/
        - forecast_chart.dart
        - recommendation_card.dart
    alerts/
      - alerts_screen.dart
    settings/
      - settings_screen.dart
```

## Data Models

### Database Schema

#### users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

#### bank_providers
```sql
CREATE TABLE bank_providers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(100) UNIQUE NOT NULL,
  auth_type VARCHAR(50) NOT NULL,
  api_base_url VARCHAR(500) NOT NULL,
  client_id VARCHAR(255),
  client_secret VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### bank_connections
```sql
CREATE TABLE bank_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bank_provider_id INTEGER NOT NULL REFERENCES bank_providers(id),
  access_token TEXT NOT NULL,  -- encrypted
  refresh_token TEXT NOT NULL,  -- encrypted
  token_expires_at TIMESTAMP NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_provider FOREIGN KEY (bank_provider_id) REFERENCES bank_providers(id)
);

CREATE INDEX idx_bank_connections_user ON bank_connections(user_id);
CREATE INDEX idx_bank_connections_status ON bank_connections(status);
```

#### bank_accounts
```sql
CREATE TABLE bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  connection_id UUID NOT NULL REFERENCES bank_connections(id) ON DELETE CASCADE,
  bank_name VARCHAR(255) NOT NULL,
  account_alias VARCHAR(255),
  account_number_mask VARCHAR(50),
  account_type VARCHAR(50) NOT NULL,
  currency VARCHAR(10) DEFAULT 'VND',
  balance DECIMAL(15, 2),
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id);
CREATE INDEX idx_bank_accounts_connection ON bank_accounts(connection_id);
```

#### categories
```sql
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
  icon VARCHAR(50),
  color VARCHAR(20),
  priority INTEGER DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_user ON categories(user_id);
CREATE INDEX idx_categories_type ON categories(type);
```

#### transactions
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bank_account_id UUID NOT NULL REFERENCES bank_accounts(id) ON DELETE CASCADE,
  external_txn_id VARCHAR(255),
  posted_at TIMESTAMP NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
  raw_description TEXT,
  normalized_description TEXT,
  mcc VARCHAR(10),
  category_id INTEGER REFERENCES categories(id),
  classification_source VARCHAR(20) DEFAULT 'AUTO' CHECK (classification_source IN ('AUTO', 'MANUAL')),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unique_external_txn UNIQUE (user_id, external_txn_id)
);

CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_posted_at ON transactions(posted_at);
CREATE INDEX idx_transactions_user_posted ON transactions(user_id, posted_at);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_account ON transactions(bank_account_id);
```

#### budgets
```sql
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
  amount_limit DECIMAL(15, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unique_budget UNIQUE (user_id, month, year, category_id)
);

CREATE INDEX idx_budgets_user ON budgets(user_id);
CREATE INDEX idx_budgets_period ON budgets(user_id, month, year);
```

#### alerts
```sql
CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  alert_type VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  payload JSONB DEFAULT '{}',
  read_flag BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_user ON alerts(user_id);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);
CREATE INDEX idx_alerts_unread ON alerts(user_id, read_flag) WHERE read_flag = false;
```

#### category_patterns (for learning)
```sql
CREATE TABLE category_patterns (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  pattern VARCHAR(500) NOT NULL,
  pattern_type VARCHAR(20) NOT NULL DEFAULT 'keyword' CHECK (pattern_type IN ('merchant', 'keyword', 'mcc')),
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  confidence DECIMAL(3, 2) DEFAULT 1.0,
  usage_count INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patterns_user ON category_patterns(user_id);
CREATE INDEX idx_patterns_type ON category_patterns(pattern_type);
CREATE INDEX idx_patterns_confidence ON category_patterns(confidence DESC);
```

### API Data Models

#### Request/Response DTOs

**Authentication:**
```typescript
// POST /api/auth/register
interface RegisterRequest {
  email: string
  password: string
  fullName: string
}

interface AuthResponse {
  user: {
    id: string
    email: string
    fullName: string
  }
  tokens: {
    accessToken: string
    refreshToken: string
    expiresIn: number
  }
}
```

**Bank Providers:**
```typescript
// GET /api/banks/providers
interface BankProviderResponse {
  id: number
  name: string
  code: string
  logo?: string
}

// GET /api/banks/connect-url
interface ConnectUrlResponse {
  authorizationUrl: string
  state: string
}
```

**Transactions:**
```typescript
// GET /api/transactions
interface TransactionListRequest {
  from?: string  // ISO date
  to?: string
  type?: 'income' | 'expense'
  categoryId?: number
  accountId?: string
  page?: number
  limit?: number
}

interface TransactionResponse {
  id: string
  amount: number
  type: 'income' | 'expense'
  description: string
  postedAt: string
  category: {
    id: number
    name: string
    icon: string
    color: string
  }
  account: {
    id: string
    bankName: string
    accountAlias: string
  }
}
```

**Budgets:**
```typescript
// GET /api/budgets/summary
interface BudgetSummaryResponse {
  month: number
  year: number
  totalBudget: number
  totalSpent: number
  usagePercentage: number
  status: 'normal' | 'warning' | 'exceeded'
  categories: Array<{
    categoryId: number
    categoryName: string
    budgetLimit: number
    spent: number
    usagePercentage: number
    status: 'normal' | 'warning' | 'exceeded'
  }>
}
```

**Reports:**
```typescript
// GET /api/reports/overview
interface SpendingOverviewResponse {
  totalIncome: number
  totalExpense: number
  netSavings: number
  savingsRate: number
  dailyBreakdown: Array<{
    date: string
    income: number
    expense: number
  }>
  categoryBreakdown: Array<{
    categoryId: number
    categoryName: string
    amount: number
    percentage: number
    color: string
  }>
}
```

**Forecast:**
```typescript
// GET /api/forecast/next-month
interface ForecastResponse {
  hasEnoughData: boolean
  warningMessage?: string
  historicalData: {
    months: Array<{
      month: number
      year: number
      income: number
      expense: number
      savings: number
    }>
    averages: {
      income: number
      expense: number
      savings: number
      savingsRate: number
    }
  }
  prediction: {
    month: number
    year: number
    predictedIncome: number
    predictedExpense: number
    predictedSavings: number
  }
  recommendations: string[]
  chartData: {
    historical: Array<{ x: string, y: number }>
    predicted: Array<{ x: string, y: number }>
  }
}
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Authentication and Authorization Properties

**Property 1: Password hashing consistency**
*For any* valid password, when stored in the database, the stored value should not equal the plain text password and should be verifiable using bcrypt.
**Validates: Requirements 1.1, 10.1**

**Property 2: Token generation validity**
*For any* successful login, the system should return both access token and refresh token that can be successfully validated.
**Validates: Requirements 1.2**

**Property 3: Token authentication**
*For any* valid access token, requests to protected endpoints should be authenticated and allowed.
**Validates: Requirements 1.3**

**Property 4: Token refresh produces valid tokens**
*For any* valid refresh token, the token refresh operation should produce new valid access and refresh tokens.
**Validates: Requirements 1.5**

### Bank Provider and Connection Properties

**Property 5: OAuth URL generation**
*For any* bank provider, the generated OAuth2 authorization URL should contain required parameters (client_id, redirect_uri, state, scope).
**Validates: Requirements 2.2**

**Property 6: Token encryption round-trip**
*For any* bank provider token, encrypting then decrypting should produce the original token value.
**Validates: Requirements 2.4, 10.2, 10.3**

**Property 7: Token refresh on expiration**
*For any* expired bank connection with valid refresh token, the system should attempt to refresh the access token.
**Validates: Requirements 2.5**

### Transaction Synchronization Properties

**Property 8: Account fetching completeness**
*For any* active bank connection, all accounts returned by the bank provider API should be stored in the database.
**Validates: Requirements 3.1**

**Property 9: Transaction normalization consistency**
*For any* raw transaction data from bank provider, the normalized transaction should contain all required fields (amount, type, description, posted_at).
**Validates: Requirements 3.3**

**Property 10: Duplicate transaction prevention**
*For any* transaction with external_txn_id, attempting to insert the same external_txn_id for the same user should result in only one record in the database.
**Validates: Requirements 3.4**

**Property 11: Error handling returns descriptive messages**
*For any* bank provider API error, the system should return an error response with a non-empty message field.
**Validates: Requirements 3.5, 18.2**

### Transaction Categorization Properties

**Property 12: Categorization is always attempted**
*For any* new transaction, the system should assign a category (either matched or "Uncategorized").
**Validates: Requirements 4.1**

**Property 13: Pattern matching assigns correct category**
*For any* transaction description matching a known pattern, the assigned category should match the pattern's category and classification source should be AUTO.
**Validates: Requirements 4.2**

**Property 14: Unknown patterns get uncategorized**
*For any* transaction description not matching any known pattern, the assigned category should be "Uncategorized".
**Validates: Requirements 4.3**

**Property 15: Manual categorization updates source**
*For any* transaction category update by user, the classification_source should be set to MANUAL.
**Validates: Requirements 4.4, 5.3**

**Property 16: Manual categorization creates learning pattern**
*For any* manual category assignment, a pattern-category mapping should be stored for future use.
**Validates: Requirements 4.5**

### Transaction Management Properties

**Property 17: Transaction filtering correctness**
*For any* transaction query with filters, all returned transactions should match the filter criteria (date range, type, category, account).
**Validates: Requirements 5.1**

**Property 18: Transaction details completeness**
*For any* transaction, the transaction details should include description, amount, date, category, and account information.
**Validates: Requirements 5.2**

**Property 19: Notes persistence**
*For any* transaction with added notes, retrieving the transaction should return the same notes.
**Validates: Requirements 5.4**

**Property 20: Amount formatting consistency**
*For any* transaction amount, the formatted display should include currency symbol and appropriate color (green for income, red for expense).
**Validates: Requirements 5.5, 11.4**

### Budget Management Properties

**Property 21: Budget storage persistence**
*For any* created budget, the budget should be retrievable from the database with the same parameters.
**Validates: Requirements 6.1**

**Property 22: Budget upsert prevents duplicates**
*For any* budget with same user_id, month, year, and category_id, creating it twice should result in only one record (updated, not duplicated).
**Validates: Requirements 6.2**

**Property 23: Budget calculation accuracy**
*For any* budget and associated transactions, the calculated usage percentage should equal (actual_spending / budget_limit) * 100.
**Validates: Requirements 6.3**

### Budget Alert Properties

**Property 24: Warning alert generation at threshold**
*For any* budget where actual spending reaches 80% of limit, an alert with type BUDGET_WARNING should be created.
**Validates: Requirements 7.1**

**Property 25: Exceeded alert generation**
*For any* budget where actual spending exceeds 100% of limit, an alert with type BUDGET_EXCEEDED should be created.
**Validates: Requirements 7.2**

**Property 26: Alert storage completeness**
*For any* created alert, it should be stored with message, type, payload, and read_flag set to false.
**Validates: Requirements 7.3**

**Property 27: Alert ordering**
*For any* user's alerts list, alerts should be ordered by creation time in descending order (newest first).
**Validates: Requirements 7.4**

**Property 28: Alert read flag update**
*For any* alert marked as read, the read_flag in database should be updated to true.
**Validates: Requirements 7.5**

### Reports and Analytics Properties

**Property 29: Spending overview calculation correctness**
*For any* date range, the net savings should equal total income minus total expense.
**Validates: Requirements 8.1**

**Property 30: Category breakdown percentage sum**
*For any* category breakdown, the sum of all category percentages should equal 100% (within rounding tolerance).
**Validates: Requirements 8.2**

**Property 31: Account breakdown totals match**
*For any* account breakdown, the sum of all account amounts should equal the total spending for the period.
**Validates: Requirements 8.3**

**Property 32: Period comparison calculation**
*For any* two time periods, the spending difference should equal period2_total minus period1_total.
**Validates: Requirements 8.4**

**Property 33: Chart data format validity**
*For any* report response, the chart data should contain arrays with required fields (x, y for line charts; name, value for pie charts).
**Validates: Requirements 8.5**

### Forecast Properties

**Property 34: Historical analysis accuracy**
*For any* set of historical transactions, the calculated average income should equal the sum of income divided by number of months.
**Validates: Requirements 9.2, 9.3**

**Property 35: Savings rate calculation**
*For any* forecast calculation, the savings rate should equal (average_savings / average_income) * 100.
**Validates: Requirements 9.3**

**Property 36: Prediction reasonableness**
*For any* forecast prediction, the predicted values should be within 50% of historical averages (basic sanity check).
**Validates: Requirements 9.4**

**Property 37: Recommendations presence**
*For any* forecast with sufficient data, the response should include at least one recommendation.
**Validates: Requirements 9.5**

### Security Properties

**Property 38: Password storage security**
*For any* stored user password, the database value should not equal the plain text password and should start with bcrypt hash prefix.
**Validates: Requirements 10.1**

**Property 39: Token encryption in storage**
*For any* stored bank provider token, the database value should not equal the plain text token.
**Validates: Requirements 10.2**

**Property 40: Error logging sanitization**
*For any* logged error, the log message should not contain password or token values.
**Validates: Requirements 10.5**

### Mobile App Integration Properties

**Property 41: API call on category change**
*For any* transaction category change in mobile app, the app should make a PATCH request to /api/transactions/:id/category.
**Validates: Requirements 12.3**

**Property 42: API call on notes addition**
*For any* transaction notes addition in mobile app, the app should make a PATCH request to /api/transactions/:id.
**Validates: Requirements 12.4**

**Property 43: Transaction display completeness**
*For any* displayed transaction in mobile app, it should show description, amount, date, and category icon.
**Validates: Requirements 12.5**

**Property 44: Bank provider fetch on connection**
*For any* bank connection initiation, the mobile app should call GET /api/banks/providers.
**Validates: Requirements 13.2**

**Property 45: OAuth WebView opening**
*For any* selected bank provider, the mobile app should open WebView with the authorization URL from backend.
**Validates: Requirements 13.3**

**Property 46: Sync API call with loading indicator**
*For any* transaction sync trigger, the mobile app should call POST /api/bank-accounts/:id/sync-transactions and display loading state.
**Validates: Requirements 13.5**

**Property 47: Budget API call on save**
*For any* budget creation or edit, the mobile app should call POST /api/budgets with budget data.
**Validates: Requirements 14.4**

**Property 48: Budget color coding**
*For any* budget item with usage > 80%, the display color should be warning color; if usage > 100%, it should be exceeded color.
**Validates: Requirements 14.2, 14.3**

**Property 49: Report data fetch on date change**
*For any* date range selection in reports screen, the mobile app should fetch new report data from backend.
**Validates: Requirements 15.2**

**Property 50: Forecast data fetch**
*For any* forecast screen opening, the mobile app should call GET /api/forecast/next-month.
**Validates: Requirements 16.1**

**Property 51: Forecast display completeness**
*For any* received forecast data, the mobile app should display historical averages and predicted values.
**Validates: Requirements 16.2**

**Property 52: Forecast recommendations display**
*For any* forecast with recommendations, the mobile app should display all recommendation strings.
**Validates: Requirements 16.4**

### Error Handling Properties

**Property 53: Structured error responses**
*For any* backend error, the response should include status code and message fields.
**Validates: Requirements 18.1**

**Property 54: Validation error specificity**
*For any* validation failure, the error response should include specific field names and reasons.
**Validates: Requirements 18.3**

**Property 55: Error response safety**
*For any* unexpected error, the error response should not include stack traces or internal implementation details.
**Validates: Requirements 18.4**

**Property 56: Mobile error display**
*For any* error response received by mobile app, an error message should be displayed to the user.
**Validates: Requirements 18.5**

### Bulk Operations Properties

**Property 57: Bulk category update consistency**
*For any* set of selected transactions and target category, all transactions should be updated with the same category and classification source set to MANUAL.
**Validates: Requirements 19.2, 19.3**

**Property 58: Bulk operation success count**
*For any* bulk operation, the returned success count should equal the number of valid transaction IDs processed.
**Validates: Requirements 19.4**

**Property 59: Bulk operation partial success**
*For any* bulk operation with mixed valid and invalid IDs, the operation should process all valid IDs and skip invalid ones without failing.
**Validates: Requirements 19.5**

### Budget History Properties

**Property 60: Budget history completeness**
*For any* budget history request for N months, the response should contain data for all available months up to N.
**Validates: Requirements 20.1**

**Property 61: Budget comparison calculation**
*For any* two months being compared, the spending difference should equal month2_spending minus month1_spending for each category.
**Validates: Requirements 20.2**

**Property 62: Budget comparison percentage accuracy**
*For any* budget comparison, the percentage change should equal ((new_value - old_value) / old_value) * 100.
**Validates: Requirements 20.3**

### Advanced Analysis Properties

**Property 63: Merchant aggregation accuracy**
*For any* merchant analysis, the sum of all merchant spending should equal total spending for the period.
**Validates: Requirements 21.1**

**Property 64: Month comparison consistency**
*For any* month-to-month comparison, spending changes should be calculated consistently across all categories.
**Validates: Requirements 21.2**

**Property 65: Year comparison accuracy**
*For any* year-to-year comparison, annual totals should equal the sum of all monthly spending in each year.
**Validates: Requirements 21.3**

**Property 66: Custom range comparison validity**
*For any* two custom date ranges, the comparison should only include transactions within the specified dates.
**Validates: Requirements 21.4**

### Enhanced Categorization Properties

**Property 67: Merchant pattern extraction**
*For any* manual categorization, if a merchant name can be extracted from description, it should be stored as a pattern.
**Validates: Requirements 22.1**

**Property 68: Merchant pattern priority**
*For any* transaction matching both merchant and keyword patterns, the merchant pattern should be used for categorization.
**Validates: Requirements 22.2**

**Property 69: Pattern confidence ordering**
*For any* transaction matching multiple patterns, the pattern with highest confidence score should be selected.
**Validates: Requirements 22.3**

**Property 70: Pattern usage tracking**
*For any* successful pattern match, the usage count should increment by 1 and confidence score should be recalculated.
**Validates: Requirements 22.4**

## Error Handling

### Backend Error Handling Strategy

**Error Categories:**

1. **Validation Errors (400)**
   - Invalid input data
   - Missing required fields
   - Format violations
   - Response: `{ status: 400, message: "Validation failed", errors: [{ field, message }] }`

2. **Authentication Errors (401)**
   - Invalid credentials
   - Expired tokens
   - Missing authentication
   - Response: `{ status: 401, message: "Authentication required" }`

3. **Authorization Errors (403)**
   - Insufficient permissions
   - Resource access denied
   - Response: `{ status: 403, message: "Access denied" }`

4. **Not Found Errors (404)**
   - Resource not found
   - Invalid IDs
   - Response: `{ status: 404, message: "Resource not found" }`

5. **External API Errors (502)**
   - Bank provider API failures
   - Timeout errors
   - Response: `{ status: 502, message: "External service unavailable" }`

6. **Internal Server Errors (500)**
   - Unexpected exceptions
   - Database errors
   - Response: `{ status: 500, message: "Internal server error" }`

**Error Middleware:**
```typescript
function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  // Log error with sanitization
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    // Never log sensitive data
  })

  // Determine error type and response
  if (err instanceof ValidationError) {
    return res.status(400).json({
      status: 400,
      message: "Validation failed",
      errors: err.details
    })
  }

  if (err instanceof AuthenticationError) {
    return res.status(401).json({
      status: 401,
      message: err.message
    })
  }

  // Default to 500 for unexpected errors
  res.status(500).json({
    status: 500,
    message: "Internal server error"
  })
}
```

### Mobile Error Handling Strategy

**Error Display:**
- Toast messages for transient errors
- Dialog boxes for critical errors requiring user action
- Inline error messages for form validation
- Retry mechanisms for network failures

**Error Recovery:**
- Automatic token refresh on 401 errors
- Retry with exponential backoff for network errors
- Offline mode with local cache when backend unavailable
- Clear error messages with actionable suggestions

**Example Error Handler:**
```dart
class ApiErrorHandler {
  static void handle(DioError error, BuildContext context) {
    if (error.response?.statusCode == 401) {
      // Token expired, attempt refresh
      _refreshTokenAndRetry(error);
    } else if (error.response?.statusCode == 400) {
      // Validation error, show specific messages
      _showValidationErrors(error.response?.data, context);
    } else if (error.type == DioErrorType.connectionTimeout) {
      // Network error, show retry option
      _showRetryDialog(context);
    } else {
      // Generic error
      _showErrorToast(error.message, context);
    }
  }
}
```

## Testing Strategy

### Backend Testing

**Unit Testing:**
- Test individual service methods with mocked dependencies
- Test repository methods with in-memory database
- Test utility functions (encryption, hashing, formatting)
- Test validation logic
- Framework: Jest or Mocha with Chai
- Coverage target: 80%+ for services and repositories

**Property-Based Testing:**
- Library: fast-check (JavaScript/TypeScript property-based testing)
- Configuration: Minimum 100 iterations per property test
- Each property test must include a comment tag: `**Feature: advanced-financial-management, Property {number}: {property_text}**`
- Property tests verify universal correctness across randomly generated inputs
- Examples:
  - Password hashing: generate random passwords, verify hashing is consistent
  - Token encryption: generate random tokens, verify encryption round-trip
  - Budget calculations: generate random budgets and transactions, verify percentage calculations
  - Transaction filtering: generate random transactions and filters, verify all results match criteria

**Integration Testing:**
- Test API endpoints with real database (test database)
- Test OAuth2 flow with mocked bank provider
- Test transaction sync with mocked bank API
- Framework: Supertest with Jest

**Example Property Test:**
```typescript
import fc from 'fast-check'

describe('Budget Calculations', () => {
  /**
   * Feature: advanced-financial-management, Property 23: Budget calculation accuracy
   * For any budget and associated transactions, the calculated usage percentage
   * should equal (actual_spending / budget_limit) * 100
   */
  it('should calculate budget usage percentage correctly', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 1, max: 100000 }), // budget limit
        fc.float({ min: 0, max: 100000 }), // actual spending
        (budgetLimit, actualSpending) => {
          const expected = (actualSpending / budgetLimit) * 100
          const result = calculateBudgetUsage(budgetLimit, actualSpending)
          expect(result).toBeCloseTo(expected, 2)
        }
      ),
      { numRuns: 100 }
    )
  })
})
```

### Mobile Testing

**Unit Testing:**
- Test service methods (API calls, data parsing)
- Test state management providers
- Test utility functions (formatting, validation)
- Framework: Flutter test package
- Coverage target: 70%+ for services and providers

**Widget Testing:**
- Test individual widgets render correctly
- Test user interactions (taps, swipes, form inputs)
- Test navigation flows
- Framework: Flutter test package with widget tester

**Property-Based Testing:**
- Library: glados (Dart property-based testing)
- Configuration: Minimum 100 iterations per property test
- Test data formatting functions with random inputs
- Test validation logic with random valid/invalid inputs
- Test calculation functions with random numbers

**Example Property Test:**
```dart
import 'package:glados/glados.dart';

void main() {
  /// Feature: advanced-financial-management, Property 20: Amount formatting consistency
  /// For any transaction amount, the formatted display should include currency symbol
  Glados<double>().test('formats amounts with currency symbol', (amount) {
    final formatted = formatCurrency(amount);
    expect(formatted, contains('₫')); // VND symbol
    expect(formatted, contains(amount.abs().toStringAsFixed(0)));
  });
}
```

**Integration Testing:**
- Test complete user flows (login → connect bank → view transactions)
- Test API integration with mock server
- Framework: Flutter integration test package

### Database Testing

**Schema Testing:**
- Verify all tables created with correct structure
- Verify foreign key constraints work
- Verify unique constraints prevent duplicates
- Verify indexes exist on specified columns

**Migration Testing:**
- Test migrations run successfully
- Test rollback functionality
- Test data integrity after migrations

### Test Data Generation

**Seed Data:**
- Default categories (Food, Transport, Bills, Entertainment, Salary, etc.)
- Sample bank providers (Mock Bank, Test Bank)
- Demo user account with sample data

**Generators:**
- Random user generator
- Random transaction generator (with realistic descriptions)
- Random budget generator
- Date range generator for testing different time periods

### Continuous Integration

**CI Pipeline:**
1. Lint code (ESLint for backend, Dart analyzer for mobile)
2. Run unit tests
3. Run property-based tests
4. Run integration tests
5. Check code coverage
6. Build artifacts

**Pre-commit Hooks:**
- Format code
- Run linter
- Run fast unit tests

## Deployment Considerations

### Environment Configuration

**Backend Environment Variables:**
```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:pass@host:5432/dbname
JWT_SECRET=<strong-secret>
JWT_REFRESH_SECRET=<strong-secret>
ENCRYPTION_KEY=<32-byte-hex-key>
BANK_API_BASE_URL=https://api.bank-provider.com
BANK_CLIENT_ID=<client-id>
BANK_CLIENT_SECRET=<client-secret>
OAUTH_REDIRECT_URI=https://app.example.com/oauth/callback
LOG_LEVEL=info
```

**Mobile Environment Configuration:**
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com'
  );
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production'
  );
}
```

### Security Checklist

- [ ] All passwords hashed with bcrypt (cost factor 12+)
- [ ] All tokens encrypted with AES-256-GCM
- [ ] JWT secrets are strong and rotated regularly
- [ ] HTTPS enforced for all API communications
- [ ] CORS configured to allow only mobile app origin
- [ ] Rate limiting enabled on authentication endpoints
- [ ] SQL injection prevented via parameterized queries
- [ ] Input validation on all API endpoints
- [ ] Sensitive data never logged
- [ ] Database credentials stored securely
- [ ] Regular security audits and dependency updates

### Performance Optimization

**Database:**
- Connection pooling (max 20 connections)
- Indexes on frequently queried columns
- Query optimization for reports (use aggregation queries)
- Pagination for large result sets

**Backend:**
- Response caching for static data (categories, bank providers)
- Compression middleware (gzip)
- Async processing for heavy operations (transaction sync)
- Request timeout limits

**Mobile:**
- Image caching
- API response caching with expiration
- Lazy loading for lists
- Debouncing for search inputs
- Optimistic UI updates

### Monitoring and Logging

**Backend Logging:**
- Request/response logging (excluding sensitive data)
- Error logging with stack traces
- Performance metrics (response times)
- Bank API call logging
- Log aggregation service (e.g., ELK stack)

**Mobile Analytics:**
- Screen view tracking
- User action tracking
- Error tracking (e.g., Sentry)
- Performance monitoring (e.g., Firebase Performance)

**Alerts:**
- High error rate alerts
- Bank API failure alerts
- Database connection issues
- Slow query alerts

## Future Enhancements

### Phase 2 Features

1. **Multi-currency Support**
   - Handle multiple currencies
   - Currency conversion
   - Exchange rate tracking

2. **Recurring Transactions**
   - Detect recurring patterns
   - Predict upcoming bills
   - Set up automatic categorization for recurring transactions

3. **Goals and Savings**
   - Set financial goals
   - Track progress toward goals
   - Savings recommendations

4. **Bill Reminders**
   - Detect bill due dates
   - Send reminders before due dates
   - Track bill payment status

5. **Export and Reports**
   - Export transactions to CSV/Excel
   - Generate PDF reports
   - Tax preparation reports

6. **Shared Accounts**
   - Family account sharing
   - Shared budgets
   - Permission management

7. **Advanced Analytics**
   - Machine learning for better categorization
   - Anomaly detection for fraud
   - Spending pattern insights
   - Comparison with similar users (anonymized)

8. **Investment Tracking**
   - Connect investment accounts
   - Portfolio tracking
   - Investment performance analysis

### Scalability Considerations

**Horizontal Scaling:**
- Stateless API design allows multiple backend instances
- Load balancer distribution
- Session storage in Redis

**Database Scaling:**
- Read replicas for reporting queries
- Partitioning transactions table by date
- Archiving old transactions

**Caching Layer:**
- Redis for session storage
- Cache frequently accessed data (user settings, categories)
- Cache invalidation strategy

**Microservices Migration:**
- Split into services: Auth, Bank Integration, Analytics, Notifications
- Message queue for async processing (RabbitMQ, Kafka)
- API Gateway for routing
