-- Add vi_slug column to categories table
ALTER TABLE "categories" ADD COLUMN IF NOT EXISTS "vi_slug" VARCHAR(255);

-- Create index on vi_slug
CREATE INDEX IF NOT EXISTS "categories_vi_slug_idx" ON "categories"("vi_slug");

