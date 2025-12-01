-- AlterTable
ALTER TABLE "categories" ADD COLUMN     "vi_slug" VARCHAR(255);

-- CreateIndex
CREATE INDEX "idx_alerts_unread" ON "alerts"("user_id", "read_flag");

-- CreateIndex
CREATE INDEX "categories_vi_slug_idx" ON "categories"("vi_slug");

-- RenameIndex
ALTER INDEX "idx_patterns_confidence" RENAME TO "category_patterns_confidence_idx";

-- RenameIndex
ALTER INDEX "idx_patterns_type" RENAME TO "category_patterns_pattern_type_idx";
