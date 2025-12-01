-- CreateTable
CREATE TABLE "category_rules" (
    "id" SERIAL NOT NULL,
    "category_id" INTEGER NOT NULL,
    "keyword" VARCHAR(255) NOT NULL,
    "keyword_normalized" VARCHAR(255) NOT NULL,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "category_rules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "category_rules_category_id_idx" ON "category_rules"("category_id");

-- CreateIndex
CREATE INDEX "category_rules_keyword_normalized_idx" ON "category_rules"("keyword_normalized");

-- CreateIndex
CREATE INDEX "category_rules_priority_idx" ON "category_rules"("priority");

-- CreateIndex
CREATE UNIQUE INDEX "category_rules_keyword_category_id_key" ON "category_rules"("keyword", "category_id");

-- AddForeignKey
ALTER TABLE "category_rules" ADD CONSTRAINT "category_rules_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Insert default category rules for Vietnamese transactions
INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Food & Dining (Ăn uống)
    ('GRAB FOOD', 'grab food', 1),
    ('GRABFOOD', 'grabfood', 1),
    ('SHOPEE FOOD', 'shopee food', 1),
    ('SHOPEEFOOD', 'shopeefood', 1),
    ('NOW.VN', 'now.vn', 1),
    ('BAEMIN', 'baemin', 1),
    ('GOFOOD', 'gofood', 1),
    ('HIGHLAND', 'highland', 2),
    ('STARBUCKS', 'starbucks', 2),
    ('PHUC LONG', 'phuc long', 2),
    ('THE COFFEE HOUSE', 'the coffee house', 2),
    ('CAFE', 'cafe', 3),
    ('RESTAURANT', 'restaurant', 3),
    ('NHA HANG', 'nha hang', 3),
    ('QUAN AN', 'quan an', 3),
    ('COM', 'com', 4),
    ('PHO', 'pho', 4),
    ('BUN', 'bun', 4)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Food' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Transport (Di chuyển)
    ('GRAB', 'grab', 1),
    ('GOJEK', 'gojek', 1),
    ('BE', 'be', 1),
    ('XANH SM', 'xanh sm', 1),
    ('TAXI', 'taxi', 2),
    ('UBER', 'uber', 2),
    ('PETROLIMEX', 'petrolimex', 2),
    ('XANG DAU', 'xang dau', 2),
    ('PARKING', 'parking', 3),
    ('GUI XE', 'gui xe', 3),
    ('METRO', 'metro', 3),
    ('BUS', 'bus', 3),
    ('VE XE', 've xe', 3),
    ('VE TAU', 've tau', 3),
    ('VIETJET', 'vietjet', 2),
    ('VIETNAM AIRLINES', 'vietnam airlines', 2),
    ('BAMBOO', 'bamboo', 2)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Transport' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Bills & Utilities (Hóa đơn)
    ('TIEN DIEN', 'tien dien', 1),
    ('EVN', 'evn', 1),
    ('DIEN LUC', 'dien luc', 1),
    ('TIEN NUOC', 'tien nuoc', 1),
    ('CAP NUOC', 'cap nuoc', 1),
    ('INTERNET', 'internet', 1),
    ('VNPT', 'vnpt', 1),
    ('FPT', 'fpt', 1),
    ('VIETTEL', 'viettel', 1),
    ('MOBIFONE', 'mobifone', 1),
    ('VINAPHONE', 'vinaphone', 1),
    ('NAP DIEN THOAI', 'nap dien thoai', 2),
    ('NAP THE', 'nap the', 2),
    ('TRUYEN HINH', 'truyen hinh', 2),
    ('K+', 'k+', 2),
    ('VTV', 'vtv', 2)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Bills' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Shopping (Mua sắm)
    ('SHOPEE', 'shopee', 1),
    ('LAZADA', 'lazada', 1),
    ('TIKI', 'tiki', 1),
    ('SENDO', 'sendo', 1),
    ('THEGIOIDIDONG', 'thegioididong', 1),
    ('THE GIOI DI DONG', 'the gioi di dong', 1),
    ('DIEN MAY XANH', 'dien may xanh', 1),
    ('BACH HOA XANH', 'bach hoa xanh', 1),
    ('VINMART', 'vinmart', 2),
    ('COOPMART', 'coopmart', 2),
    ('BIG C', 'big c', 2),
    ('LOTTE', 'lotte', 2),
    ('AEON', 'aeon', 2),
    ('UNIQLO', 'uniqlo', 2),
    ('H&M', 'h&m', 2),
    ('ZARA', 'zara', 2)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Shopping' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Entertainment (Giải trí)
    ('NETFLIX', 'netflix', 1),
    ('SPOTIFY', 'spotify', 1),
    ('YOUTUBE', 'youtube', 1),
    ('GAME', 'game', 2),
    ('CINEMA', 'cinema', 2),
    ('RAP CHIEU PHIM', 'rap chieu phim', 2),
    ('CGV', 'cgv', 1),
    ('LOTTE CINEMA', 'lotte cinema', 1),
    ('GALAXY', 'galaxy', 2),
    ('KARAOKE', 'karaoke', 2),
    ('BILLIARD', 'billiard', 3),
    ('GYM', 'gym', 2),
    ('FITNESS', 'fitness', 2),
    ('SPA', 'spa', 2),
    ('MASSAGE', 'massage', 3)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Entertainment' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Health (Sức khỏe)
    ('BENH VIEN', 'benh vien', 1),
    ('HOSPITAL', 'hospital', 1),
    ('PHONG KHAM', 'phong kham', 1),
    ('CLINIC', 'clinic', 1),
    ('NHA THUOC', 'nha thuoc', 1),
    ('PHARMACY', 'pharmacy', 1),
    ('BAO HIEM', 'bao hiem', 2),
    ('INSURANCE', 'insurance', 2),
    ('PRUDENTIAL', 'prudential', 1),
    ('MANULIFE', 'manulife', 1),
    ('DAI ICI', 'dai ici', 1),
    ('AIA', 'aia', 1),
    ('KHAM BENH', 'kham benh', 2),
    ('THUOC', 'thuoc', 3)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Health' AND c.is_default = true
ON CONFLICT DO NOTHING;

INSERT INTO "category_rules" ("category_id", "keyword", "keyword_normalized", "priority", "is_active", "updated_at")
SELECT c.id, r.keyword, r.keyword_normalized, r.priority, true, NOW()
FROM "categories" c
CROSS JOIN (
    VALUES 
    -- Education (Giáo dục)
    ('HOC PHI', 'hoc phi', 1),
    ('TUITION', 'tuition', 1),
    ('TRUONG', 'truong', 2),
    ('SCHOOL', 'school', 2),
    ('UNIVERSITY', 'university', 1),
    ('DAI HOC', 'dai hoc', 1),
    ('KHOA HOC', 'khoa hoc', 2),
    ('COURSE', 'course', 2),
    ('SACH', 'sach', 3),
    ('BOOK', 'book', 3),
    ('FAHASA', 'fahasa', 2),
    ('UDEMY', 'udemy', 1),
    ('COURSERA', 'coursera', 1)
) AS r(keyword, keyword_normalized, priority)
WHERE c.name = 'Education' AND c.is_default = true
ON CONFLICT DO NOTHING;

