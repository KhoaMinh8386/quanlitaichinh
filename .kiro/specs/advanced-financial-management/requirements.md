# Requirements Document

## Introduction

Hệ thống Quản lý Tài chính Cá nhân Nâng Cao (Advanced Financial Management System) là một ứng dụng di động toàn diện giúp người dùng quản lý tài chính cá nhân thông qua việc kết nối trực tiếp với tài khoản ngân hàng, tự động đồng bộ và phân loại giao dịch, theo dõi ngân sách, phân tích chi tiêu và dự báo tài chính. Hệ thống bao gồm ứng dụng mobile Flutter, backend REST API Node.js/Express và cơ sở dữ liệu PostgreSQL.

## Glossary

- **System**: Hệ thống Quản lý Tài chính Cá nhân Nâng Cao
- **User**: Người dùng cuối sử dụng ứng dụng mobile
- **Mobile App**: Ứng dụng Flutter chạy trên thiết bị di động
- **Backend**: Máy chủ Node.js/Express xử lý API requests
- **Database**: Cơ sở dữ liệu PostgreSQL lưu trữ dữ liệu
- **Bank Provider**: Nhà cung cấp dịch vụ kết nối ngân hàng (Open Banking API)
- **Bank Connection**: Kết nối được ủy quyền giữa User và Bank Provider
- **Bank Account**: Tài khoản ngân hàng của User được liên kết với System
- **Transaction**: Giao dịch thu hoặc chi từ Bank Account
- **Category**: Danh mục phân loại giao dịch (ăn uống, di chuyển, hóa đơn, etc.)
- **Budget**: Ngân sách chi tiêu được thiết lập cho một tháng cụ thể
- **Alert**: Cảnh báo gửi đến User về tình trạng tài chính
- **Forecast**: Dự báo tài chính dựa trên lịch sử chi tiêu
- **Access Token**: Mã xác thực ngắn hạn để truy cập API
- **Refresh Token**: Mã xác thực dài hạn để làm mới Access Token
- **JWT**: JSON Web Token dùng cho xác thực
- **OAuth2**: Giao thức ủy quyền để kết nối Bank Provider
- **MCC**: Merchant Category Code - mã phân loại merchant
- **Bulk Operation**: Thao tác áp dụng cho nhiều giao dịch cùng lúc
- **Merchant**: Đối tác giao dịch, cửa hàng hoặc dịch vụ nhận thanh toán
- **Pattern**: Mẫu nhận dạng để tự động phân loại giao dịch
- **Confidence Score**: Điểm tin cậy của pattern phân loại (0.0 - 1.0)
- **Budget History**: Lịch sử ngân sách và chi tiêu của các tháng trước
- **Spending Trend**: Xu hướng chi tiêu theo thời gian

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a user, I want to securely register and login to the system, so that my financial data is protected and only accessible by me.

#### Acceptance Criteria

1. WHEN a user submits registration with valid email and password THEN THE System SHALL create a new user account with hashed password stored in Database
2. WHEN a user submits login credentials THEN THE System SHALL validate credentials and return JWT Access Token and Refresh Token
3. WHEN a user provides valid Access Token in API request THEN THE System SHALL authenticate the request and allow access to protected resources
4. WHEN Access Token expires THEN THE System SHALL reject the request and require token refresh
5. WHEN a user provides valid Refresh Token THEN THE System SHALL issue new Access Token and Refresh Token pair

### Requirement 2: Bank Provider Management

**User Story:** As a user, I want to view available bank providers and connect my bank accounts, so that I can automatically sync my financial transactions.

#### Acceptance Criteria

1. WHEN a user requests bank providers list THEN THE System SHALL return all supported Bank Providers with connection details
2. WHEN a user initiates bank connection for a Bank Provider THEN THE System SHALL generate OAuth2 authorization URL for that provider
3. WHEN Bank Provider redirects with authorization code THEN THE System SHALL exchange code for Access Token and Refresh Token
4. WHEN Bank Provider tokens are received THEN THE System SHALL encrypt and store tokens in Database with expiration timestamp
5. WHEN stored Bank Provider token expires THEN THE System SHALL use Refresh Token to obtain new Access Token

### Requirement 3: Bank Account Synchronization

**User Story:** As a user, I want to sync my bank accounts and transactions automatically, so that I don't have to manually enter financial data.

#### Acceptance Criteria

1. WHEN a user has active Bank Connection THEN THE System SHALL fetch and store all linked Bank Accounts from Bank Provider
2. WHEN a user triggers transaction sync for a Bank Account THEN THE System SHALL call Bank Provider API to retrieve new transactions
3. WHEN transactions are retrieved from Bank Provider THEN THE System SHALL normalize transaction data and store in Database
4. WHEN a transaction with duplicate external transaction ID exists THEN THE System SHALL skip insertion and maintain existing record
5. WHEN Bank Provider API returns error THEN THE System SHALL log error details and return descriptive error message to Mobile App

### Requirement 4: Automatic Transaction Categorization

**User Story:** As a user, I want my transactions to be automatically categorized, so that I can quickly understand my spending patterns without manual work.

#### Acceptance Criteria

1. WHEN a new transaction is stored THEN THE System SHALL analyze transaction description and MCC to determine appropriate Category
2. WHEN transaction description matches known pattern THEN THE System SHALL assign corresponding Category and mark classification source as AUTO
3. WHEN transaction description does not match any pattern THEN THE System SHALL assign "Uncategorized" Category
4. WHEN a user manually changes transaction Category THEN THE System SHALL update Category and mark classification source as MANUAL
5. WHEN a user manually categorizes transaction THEN THE System SHALL store pattern-category mapping for future learning

### Requirement 5: Transaction Management

**User Story:** As a user, I want to view, filter, and manage my transactions, so that I can track my income and expenses effectively.

#### Acceptance Criteria

1. WHEN a user requests transactions list THEN THE System SHALL return transactions filtered by date range, type, category, and account
2. WHEN a user views transaction details THEN THE System SHALL display normalized description, amount, date, category, and account information
3. WHEN a user updates transaction category THEN THE System SHALL persist the change and update classification source to MANUAL
4. WHEN a user adds notes to transaction THEN THE System SHALL store notes in Database
5. WHEN transactions are displayed THEN THE System SHALL format amounts with proper currency symbol and color coding for income versus expense

### Requirement 6: Budget Management

**User Story:** As a user, I want to set monthly budgets for different spending categories, so that I can control my expenses and avoid overspending.

#### Acceptance Criteria

1. WHEN a user creates budget for specific month and category THEN THE System SHALL store budget limit in Database
2. WHEN budget already exists for same user, month, year, and category THEN THE System SHALL update existing budget instead of creating duplicate
3. WHEN a user requests budget summary THEN THE System SHALL calculate total budget, actual spending, usage percentage, and status for each category
4. WHEN actual spending exceeds eighty percent of budget limit THEN THE System SHALL mark budget status as WARNING
5. WHEN actual spending exceeds one hundred percent of budget limit THEN THE System SHALL mark budget status as EXCEEDED

### Requirement 7: Budget Alerts

**User Story:** As a user, I want to receive alerts when I'm approaching or exceeding my budget, so that I can adjust my spending behavior in time.

#### Acceptance Criteria

1. WHEN actual spending reaches eighty percent of budget limit THEN THE System SHALL create Alert with type BUDGET_WARNING
2. WHEN actual spending exceeds budget limit THEN THE System SHALL create Alert with type BUDGET_EXCEEDED
3. WHEN Alert is created THEN THE System SHALL store alert message, type, and payload in Database with unread status
4. WHEN a user views alerts list THEN THE System SHALL return all alerts ordered by creation time descending
5. WHEN a user marks alert as read THEN THE System SHALL update read flag in Database

### Requirement 8: Spending Analytics and Reports

**User Story:** As a user, I want to visualize my spending patterns through charts and reports, so that I can understand where my money goes and make informed financial decisions.

#### Acceptance Criteria

1. WHEN a user requests spending overview for date range THEN THE System SHALL calculate total income, total expense, net savings, and daily spending breakdown
2. WHEN a user requests category breakdown THEN THE System SHALL aggregate spending by Category with amounts and percentages
3. WHEN a user requests account breakdown THEN THE System SHALL aggregate spending by Bank Account with amounts and percentages
4. WHEN a user requests period comparison THEN THE System SHALL calculate spending differences between two time periods
5. WHEN report data is returned THEN THE System SHALL format data suitable for chart rendering in Mobile App

### Requirement 9: Financial Forecasting

**User Story:** As a user, I want to see predictions of my future income and expenses, so that I can plan ahead and improve my financial health.

#### Acceptance Criteria

1. WHEN a user requests forecast with less than three months of transaction history THEN THE System SHALL return warning message about insufficient data
2. WHEN a user requests forecast with sufficient history THEN THE System SHALL analyze last six months of income and expense data
3. WHEN forecast is calculated THEN THE System SHALL compute average income, average expense, average savings, and savings rate
4. WHEN forecast is calculated THEN THE System SHALL predict next month income, expense, and savings based on historical trends
5. WHEN forecast is returned THEN THE System SHALL include actionable recommendations for spending reduction and savings improvement

### Requirement 10: Data Security and Encryption

**User Story:** As a user, I want my sensitive financial data to be encrypted and secure, so that I can trust the system with my personal information.

#### Acceptance Criteria

1. WHEN a user password is stored THEN THE System SHALL hash password using bcrypt before storing in Database
2. WHEN Bank Provider tokens are stored THEN THE System SHALL encrypt tokens using AES encryption with secret key from environment
3. WHEN Bank Provider tokens are retrieved THEN THE System SHALL decrypt tokens before using in API calls
4. WHEN API requests are made from Mobile App THEN THE System SHALL require HTTPS protocol for all communications
5. WHEN errors occur THEN THE System SHALL log errors without exposing sensitive data like passwords or tokens

### Requirement 11: Mobile App Dashboard

**User Story:** As a user, I want to see an overview of my financial status on the home screen, so that I can quickly understand my current financial situation.

#### Acceptance Criteria

1. WHEN a user opens Mobile App dashboard THEN THE Mobile App SHALL display total monthly income, total monthly expense, net balance, and savings rate
2. WHEN dashboard loads THEN THE Mobile App SHALL render line chart showing daily spending trend for current month
3. WHEN dashboard loads THEN THE Mobile App SHALL render donut chart showing spending distribution by Category
4. WHEN dashboard displays amounts THEN THE Mobile App SHALL format currency with proper symbols and color coding
5. WHEN dashboard is displayed THEN THE Mobile App SHALL provide navigation shortcuts to Budgets, Reports, and Forecast screens

### Requirement 12: Mobile App Transaction Interface

**User Story:** As a user, I want to browse and manage my transactions on mobile, so that I can review and categorize my spending on the go.

#### Acceptance Criteria

1. WHEN a user opens transactions screen THEN THE Mobile App SHALL display list of transactions with filters for date range, type, category, and account
2. WHEN a user taps on transaction THEN THE Mobile App SHALL show transaction details with option to change Category
3. WHEN a user changes transaction Category THEN THE Mobile App SHALL call Backend API to update Category and refresh display
4. WHEN a user adds notes to transaction THEN THE Mobile App SHALL call Backend API to save notes
5. WHEN transactions are displayed THEN THE Mobile App SHALL show normalized description, formatted amount, date, and Category icon

### Requirement 13: Mobile App Bank Connection Flow

**User Story:** As a user, I want to connect my bank accounts through the mobile app, so that I can start syncing my financial data.

#### Acceptance Criteria

1. WHEN a user navigates to bank accounts screen THEN THE Mobile App SHALL display list of connected Bank Accounts and option to add new connection
2. WHEN a user initiates new bank connection THEN THE Mobile App SHALL fetch available Bank Providers from Backend
3. WHEN a user selects Bank Provider THEN THE Mobile App SHALL request OAuth2 URL from Backend and open WebView for authorization
4. WHEN OAuth2 authorization completes THEN THE Mobile App SHALL close WebView and refresh Bank Accounts list
5. WHEN a user triggers sync for Bank Account THEN THE Mobile App SHALL call Backend API to sync transactions and display loading indicator

### Requirement 14: Mobile App Budget Interface

**User Story:** As a user, I want to manage my budgets through the mobile app, so that I can set spending limits and track my progress.

#### Acceptance Criteria

1. WHEN a user opens budgets screen THEN THE Mobile App SHALL display list of budgets for current month with usage progress bars
2. WHEN budget usage exceeds eighty percent THEN THE Mobile App SHALL display budget item with warning color
3. WHEN budget usage exceeds one hundred percent THEN THE Mobile App SHALL display budget item with exceeded color
4. WHEN a user creates or edits budget THEN THE Mobile App SHALL call Backend API to save budget and refresh display
5. WHEN budget progress bars are displayed THEN THE Mobile App SHALL animate progress from zero to actual percentage

### Requirement 15: Mobile App Reports and Charts

**User Story:** As a user, I want to view interactive charts and reports on mobile, so that I can analyze my spending patterns visually.

#### Acceptance Criteria

1. WHEN a user opens reports screen THEN THE Mobile App SHALL provide date range filters and category tabs
2. WHEN a user selects date range THEN THE Mobile App SHALL fetch report data from Backend and render appropriate charts
3. WHEN line chart is rendered THEN THE Mobile App SHALL animate chart drawing from left to right
4. WHEN donut chart is rendered THEN THE Mobile App SHALL animate segments appearing with rotation effect
5. WHEN charts are displayed THEN THE Mobile App SHALL show summary cards with top spending categories and insights

### Requirement 16: Mobile App Forecast Display

**User Story:** As a user, I want to view financial forecasts on mobile, so that I can plan my future spending and savings.

#### Acceptance Criteria

1. WHEN a user opens forecast screen THEN THE Mobile App SHALL fetch forecast data from Backend
2. WHEN forecast data is received THEN THE Mobile App SHALL display historical averages and predicted values for next month
3. WHEN forecast chart is rendered THEN THE Mobile App SHALL show line chart with solid line for historical data and dashed line for predictions
4. WHEN forecast includes recommendations THEN THE Mobile App SHALL display actionable suggestions in readable format
5. WHEN insufficient data exists for forecast THEN THE Mobile App SHALL display warning message about data limitations

### Requirement 17: Database Schema and Indexing

**User Story:** As a system administrator, I want the database to be properly structured and indexed, so that the system performs efficiently at scale.

#### Acceptance Criteria

1. WHEN Database is initialized THEN THE System SHALL create all required tables with proper foreign key constraints
2. WHEN transactions table is created THEN THE System SHALL add index on user_id and posted_at columns
3. WHEN transactions table is created THEN THE System SHALL add unique constraint on user_id and external_txn_id combination
4. WHEN budgets table is created THEN THE System SHALL add index on user_id, month, and year columns
5. WHEN queries are executed THEN THE System SHALL utilize indexes for filtering and sorting operations

### Requirement 18: Error Handling and Logging

**User Story:** As a developer, I want comprehensive error handling and logging, so that I can troubleshoot issues and maintain system reliability.

#### Acceptance Criteria

1. WHEN an error occurs in Backend THEN THE System SHALL catch error and return structured error response with status code and message
2. WHEN Bank Provider API fails THEN THE System SHALL log error details and return user-friendly error message
3. WHEN validation fails THEN THE System SHALL return error response with specific validation failure reasons
4. WHEN unexpected error occurs THEN THE System SHALL log stack trace and return generic error message without exposing internals
5. WHEN Mobile App receives error response THEN THE Mobile App SHALL display error message to user in readable format

### Requirement 19: Bulk Transaction Operations

**User Story:** As a user, I want to perform actions on multiple transactions at once, so that I can efficiently manage large numbers of similar transactions.

#### Acceptance Criteria

1. WHEN a user selects multiple transactions THEN THE Mobile App SHALL display bulk action menu with available operations
2. WHEN a user applies bulk category change to selected transactions THEN THE System SHALL update all selected transactions with new Category
3. WHEN bulk operation is performed THEN THE System SHALL update classification source to MANUAL for all affected transactions
4. WHEN bulk operation completes THEN THE System SHALL return count of successfully updated transactions
5. WHEN bulk operation includes invalid transaction IDs THEN THE System SHALL skip invalid IDs and process valid ones

### Requirement 20: Budget History and Comparison

**User Story:** As a user, I want to view and compare my budget history across different months, so that I can track my spending patterns over time and adjust future budgets.

#### Acceptance Criteria

1. WHEN a user requests budget history THEN THE System SHALL return budgets for specified number of past months with actual spending data
2. WHEN a user compares two months THEN THE System SHALL calculate spending differences by category and overall
3. WHEN budget comparison is displayed THEN THE Mobile App SHALL show percentage change and absolute difference for each category
4. WHEN viewing budget history THEN THE Mobile App SHALL render trend chart showing budget usage over time
5. WHEN historical data is insufficient THEN THE System SHALL return available months with warning about limited data

### Requirement 21: Advanced Spending Analysis

**User Story:** As a user, I want detailed spending analysis with multiple comparison options, so that I can understand my financial patterns and make better decisions.

#### Acceptance Criteria

1. WHEN a user requests merchant analysis THEN THE System SHALL aggregate spending by merchant name with transaction counts
2. WHEN a user compares current month with previous month THEN THE System SHALL calculate spending changes by category with percentage differences
3. WHEN a user compares current year with previous year THEN THE System SHALL calculate annual spending trends by category
4. WHEN a user selects custom date range comparison THEN THE System SHALL compare spending between two user-defined periods
5. WHEN comparison data is displayed THEN THE Mobile App SHALL highlight categories with significant increases or decreases

### Requirement 22: Enhanced Transaction Categorization

**User Story:** As a user, I want the system to learn from my categorization patterns and improve accuracy over time, so that I spend less time manually categorizing transactions.

#### Acceptance Criteria

1. WHEN a user manually categorizes transaction THEN THE System SHALL extract merchant name from description and store as pattern
2. WHEN merchant pattern exists for transaction THEN THE System SHALL prioritize merchant-based categorization over keyword matching
3. WHEN multiple patterns match transaction THEN THE System SHALL use pattern with highest confidence score
4. WHEN pattern is used successfully THEN THE System SHALL increment usage count and adjust confidence score
5. WHEN a user views categorization patterns THEN THE Mobile App SHALL display learned patterns with confidence scores and usage statistics
