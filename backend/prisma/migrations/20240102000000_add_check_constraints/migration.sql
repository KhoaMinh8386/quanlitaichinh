-- Add CHECK constraints for data validation

-- Add CHECK constraint for categories.type
ALTER TABLE "categories" ADD CONSTRAINT "categories_type_check" 
CHECK (type IN ('income', 'expense'));

-- Add CHECK constraint for transactions.type
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_type_check" 
CHECK (type IN ('income', 'expense'));

-- Add CHECK constraint for transactions.classification_source
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_classification_source_check" 
CHECK (classification_source IN ('AUTO', 'MANUAL'));

-- Add CHECK constraint for budgets.month
ALTER TABLE "budgets" ADD CONSTRAINT "budgets_month_check" 
CHECK (month >= 1 AND month <= 12);

-- Add CHECK constraint for budgets.year
ALTER TABLE "budgets" ADD CONSTRAINT "budgets_year_check" 
CHECK (year >= 2000);
