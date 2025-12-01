-- Add pattern_type column to category_patterns table
ALTER TABLE category_patterns 
ADD COLUMN pattern_type VARCHAR(20) NOT NULL DEFAULT 'keyword';

-- Add CHECK constraint for pattern_type values
ALTER TABLE category_patterns
ADD CONSTRAINT check_pattern_type CHECK (pattern_type IN ('merchant', 'keyword', 'mcc'));

-- Add indexes on pattern_type and confidence
CREATE INDEX idx_patterns_type ON category_patterns(pattern_type);
CREATE INDEX idx_patterns_confidence ON category_patterns(confidence DESC);

-- Update existing patterns to have 'keyword' type (already set by DEFAULT)
-- No additional update needed as DEFAULT handles existing rows
