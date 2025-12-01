# Implementation Plan

## Phase 1: Setup and Foundation (Already Completed ✅)

- [x] 1. Setup project structure and database
- [x] 1.1 Initialize backend Node.js project with TypeScript, Express, and Prisma
  - Create project structure: src/config, src/routes, src/controllers, src/services, src/repositories, src/middlewares, src/utils
  - Install dependencies: express, prisma, bcrypt, jsonwebtoken, joi, axios, dotenv
  - Setup TypeScript configuration
  - _Requirements: All_

- [x] 1.2 Initialize Flutter mobile project with required dependencies
  - Create Flutter project structure
  - Install dependencies: riverpod, dio, fl_chart, flutter_secure_storage, webview_flutter
  - Setup project folders: lib/core, lib/models, lib/services, lib/providers, lib/screens, lib/widgets
  - _Requirements: 11, 12, 13, 14, 15, 16_

- [x] 1.3 Create PostgreSQL database schema with all tables and indexes
  - Create migration script for all tables: users, bank_providers, bank_connections, bank_accounts, categories, transactions, budgets, alerts, category_patterns
  - Add foreign key constraints
  - Add indexes on user_id, posted_at, category_id, month/year
  - Add unique constraints
  - _Requirements: 17_

- [x] 1.4 Seed database with default data
  - Insert default categories (Food, Transport, Bills, Entertainment, Salary, etc.)
  - Insert sample bank providers for testing
  - Create demo user account
  - _Requirements: 4_

## Phase 2: Core Features (Already Completed ✅)

- [x] 2. Implement authentication and authorization
- [x] 3. Implement transaction management
- [x] 4. Implement auto-categorization
- [x] 5. Implement budget management
- [x] 6. Implement budget alerts
- [x] 7. Implement reports and analytics
- [x] 8. Implement financial forecast
- [x] 9. Implement mobile screens (Dashboard, Transactions, Budgets, Settings)

## Phase 3: Enhanced Features (New Tasks)

- [x] 10. Enhance transaction categorization with merchant extraction






- [x] 10.1 Add pattern_type field to category_patterns table


  - Create database migration to add pattern_type column
  - Add CHECK constraint for pattern_type values
  - Add indexes on pattern_type and confidence
  - Update seed data to include pattern types
  - _Requirements: 22_

- [x] 10.2 Implement merchant extraction service


  - Create MerchantExtractor utility class
  - Implement regex patterns to extract merchant names from descriptions
  - Handle common transaction description formats
  - Test with various transaction description patterns
  - _Requirements: 22.1_

- [x] 10.3 Update categorization service with merchant priority


  - Modify matchPattern to check pattern_type
  - Implement merchant pattern matching with priority
  - Update confidence score calculation based on usage
  - Ensure merchant patterns are prioritized over keywords
  - _Requirements: 22.2, 22.3, 22.4_

- [x] 10.4 Create API endpoint for viewing categorization patterns


  - Add GET /api/categorization/patterns endpoint
  - Return patterns with confidence scores and usage statistics
  - Filter patterns by type (merchant, keyword, mcc)
  - Sort by confidence score descending
  - _Requirements: 22.5_

- [x] 10.5 Write property test for merchant extraction






  - **Property 67: Merchant pattern extraction**
  - **Validates: Requirements 22.1**

- [ ]* 10.6 Write property test for pattern priority
  - **Property 68: Merchant pattern priority**
  - **Validates: Requirements 22.2**

- [ ]* 10.7 Write property test for confidence ordering
  - **Property 69: Pattern confidence ordering**
  - **Validates: Requirements 22.3**

- [x] 11. Implement bulk transaction operations






- [x] 11.1 Create bulk update API endpoint


  - Add POST /api/transactions/bulk-update-category endpoint
  - Accept array of transaction IDs and target category ID
  - Validate all transaction IDs belong to authenticated user
  - Update all valid transactions in single database transaction
  - Return success count and failed IDs
  - _Requirements: 19.2, 19.4, 19.5_

- [x] 11.2 Implement bulk update service method


  - Create bulkUpdateCategory method in TransactionService
  - Use database transaction for atomicity
  - Update classification_source to MANUAL for all transactions
  - Handle partial failures gracefully
  - Log bulk operation details
  - _Requirements: 19.2, 19.3_

- [x] 11.3 Add bulk selection UI to mobile transactions screen


  - Add checkbox selection mode to transaction list
  - Implement select all / deselect all functionality
  - Show selected count in app bar
  - Display bulk action menu when items selected
  - _Requirements: 19.1_

- [x] 11.4 Implement bulk category change in mobile app

  - Create bulk category selection dialog
  - Call bulk update API with selected transaction IDs
  - Show loading indicator during operation
  - Display success message with count
  - Refresh transaction list after update
  - _Requirements: 19.2_

- [ ]* 11.5 Write property test for bulk update consistency
  - **Property 57: Bulk category update consistency**
  - **Validates: Requirements 19.2, 19.3**

- [ ]* 11.6 Write property test for bulk operation count
  - **Property 58: Bulk operation success count**
  - **Validates: Requirements 19.4**

- [x] 12. Implement budget history and comparison






- [x] 12.1 Create budget history API endpoint


  - Add GET /api/budgets/history endpoint
  - Accept months parameter (default 6)
  - Return budget and spending data for past N months
  - Include category breakdowns for each month
  - Handle cases with insufficient data
  - _Requirements: 20.1, 20.5_

- [x] 12.2 Implement budget comparison service

  - Create compareBudgets method in BudgetService
  - Calculate spending differences by category
  - Calculate percentage changes
  - Compute overall spending change
  - Format data for chart rendering
  - _Requirements: 20.2, 20.3_

- [x] 12.3 Create budget comparison API endpoint

  - Add GET /api/budgets/compare endpoint
  - Accept two month/year parameters
  - Return comparison data with differences and percentages
  - Highlight significant changes (>20%)
  - _Requirements: 20.2, 20.3_

- [x] 12.4 Add budget history screen to mobile app


  - Create new BudgetHistoryScreen
  - Display trend chart showing b
  
  
  udget usage over time
  - Show monthly budget cards with usage percentages
  - Add month comparison selector
  - Navigate from budgets screen
  - _Requirements: 20.4_

- [x] 12.5 Implement budget comparison UI

  - Create comparison view with side-by-side month data
  - Display percentage changes with color coding
  - Show increase/decrease indicators
  - Render comparison chart
  - _Requirements: 20.3_

- [ ]* 12.6 Write property test for budget comparison calculation
  - **Property 61: Budget comparison calculation**
  - **Validates: Requirements 20.2**

- [ ]* 12.7 Write property test for percentage accuracy
  - **Property 62: Budget comparison percentage accuracy**
  - **Validates: Requirements 20.3**

- [x] 13. Implement advanced spending analysis






- [x] 13.1 Create merchant analysis service


  - Implement getMerchantBreakdown method in ReportService
  - Aggregate transactions by merchant name
  - Calculate total spent, transaction count, average amount
  - Sort by total spent descending
  - Include category information
  - _Requirements: 21.1_

- [x] 13.2 Create merchant analysis API endpoint


  - Add GET /api/reports/merchants endpoint
  - Accept date range parameters
  - Return merchant breakdown with statistics
  - Include percentage of total spending
  - _Requirements: 21.1_

- [x] 13.3 Implement month-to-month comparison service

  - Create compareMonths method in ReportService
  - Calculate spending changes by category
  - Determine trend direction (increase/decrease/stable)
  - Compute percentage changes
  - _Requirements: 21.2_

- [x] 13.4 Create month comparison API endpoint


  - Add GET /api/reports/compare-months endpoint
  - Accept two month/year parameters
  - Return detailed comparison with trends
  - Highlight categories with significant changes
  - _Requirements: 21.2, 21.5_

- [x] 13.5 Implement year-to-year comparison service

  - Create compareYears method in ReportService
  - Aggregate spending by year and category
  - Calculate annual trends
  - Include monthly breakdown for each year
  - _Requirements: 21.3_

- [x] 13.6 Create year comparison API endpoint


  - Add GET /api/reports/compare-years endpoint
  - Accept two year parameters
  - Return annual comparison with category trends
  - Include monthly spending patterns
  - _Requirements: 21.3_

- [x] 13.7 Implement custom range comparison service

  - Create compareCustomRanges method in ReportService
  - Accept two arbitrary date ranges
  - Calculate spending differences
  - Ensure date range validation
  - _Requirements: 21.4_

- [x] 13.8 Create custom range comparison API endpoint


  - Add POST /api/reports/compare-ranges endpoint
  - Accept two date range objects
  - Validate date ranges don't overlap
  - Return comparison data
  - _Requirements: 21.4_

- [x] 13.9 Add merchant analysis tab to reports screen


  - Create merchant breakdown chart
  - Display top merchants by spending
  - Show transaction counts per merchant
  - Add merchant filter functionality
  - _Requirements: 21.1_

- [x] 13.10 Implement comparison views in reports screen

  - Add month comparison view
  - Add year comparison view
  - Add custom range comparison selector
  - Display comparison charts with trends
  - Highlight significant changes
  - _Requirements: 21.2, 21.3, 21.4, 21.5_

- [ ]* 13.11 Write property test for merchant aggregation
  - **Property 63: Merchant aggregation accuracy**
  - **Validates: Requirements 21.1**

- [ ]* 13.12 Write property test for month comparison
  - **Property 64: Month comparison consistency**
  - **Validates: Requirements 21.2**

- [ ]* 13.13 Write property test for year comparison
  - **Property 65: Year comparison accuracy**
  - **Validates: Requirements 21.3**

- [x] 14. Final integration and testing






- [x] 14.1 Integrate all new features with existing mobile screens


  - Update transactions screen with bulk operations
  - Update budgets screen with history and comparison
  - Update reports screen with advanced analysis
  - Ensure consistent UI/UX across features
  - _Requirements: All new requirements_

- [x] 14.2 Add navigation and deep linking


  - Add routes for new screens
  - Implement navigation from dashboard
  - Add quick actions for new features
  - Test navigation flows
  - _Requirements: All new requirements_

- [x] 14.3 Update mobile app state management


  - Add providers for new features
  - Implement caching for comparison data
  - Handle loading and error states
  - Add pull-to-refresh for all new screens
  - _Requirements: All new requirements_

- [ ]* 14.4 Write integration tests for new features
  - Test bulk operations end-to-end
  - Test budget history and comparison
  - Test merchant analysis
  - Test all comparison features
  - _Requirements: All new requirements_

- [ ] 15. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with * are optional testing tasks
- All property-based tests should run minimum 100 iterations
- Each property test must include comment tag with feature name and property number
- Backend changes should be completed before mobile implementation
- Database migrations must be tested in development environment first
- All new API endpoints must include proper error handling and validation
