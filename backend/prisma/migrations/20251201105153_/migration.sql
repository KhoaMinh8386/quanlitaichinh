-- AlterTable
ALTER TABLE "categories" ADD COLUMN IF NOT EXISTS "vi_slug" VARCHAR(255);

-- CreateIndex (with IF NOT EXISTS workaround)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_alerts_unread') THEN
        CREATE INDEX "idx_alerts_unread" ON "alerts"("user_id", "read_flag");
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'categories_vi_slug_idx') THEN
        CREATE INDEX "categories_vi_slug_idx" ON "categories"("vi_slug");
    END IF;
END$$;

-- RenameIndex (safe with error handling)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_patterns_confidence') THEN
        ALTER INDEX "idx_patterns_confidence" RENAME TO "category_patterns_confidence_idx";
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_patterns_type') THEN
        ALTER INDEX "idx_patterns_type" RENAME TO "category_patterns_pattern_type_idx";
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END$$;
