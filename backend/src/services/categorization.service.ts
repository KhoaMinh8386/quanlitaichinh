import { PrismaClient } from '@prisma/client';
import { ValidationError } from '../middlewares/errorHandler';
import { MerchantExtractor } from '../utils/merchantExtractor';

const prisma = new PrismaClient();

export interface Transaction {
  id: string;
  description: string;
  mcc?: string;
  userId: string;
}

export interface Category {
  id: number;
  name: string;
  type: string;
}

export interface CategoryPattern {
  id: number;
  pattern: string;
  patternType: string;
  categoryId: number;
  confidence: number;
  usageCount: number;
}

export class CategorizationService {
  private uncategorizedCategoryId: number | null = null;

  /**
   * Categorize a transaction based on description and MCC
   * Validates: Requirements 4.1, 4.2, 4.3
   */
  async categorizeTransaction(transaction: Transaction): Promise<Category> {
    const { description, mcc, userId } = transaction;

    // Try to match pattern
    const matchedCategory = await this.matchPattern(description, mcc, userId);

    if (matchedCategory) {
      return matchedCategory;
    }

    // Return uncategorized if no match
    return await this.getUncategorizedCategory();
  }

  /**
   * Match transaction description against known patterns
   * Validates: Requirements 4.2, 22.2, 22.3, 22.4
   */
  async matchPattern(
    description: string,
    mcc: string | undefined,
    userId: string
  ): Promise<Category | null> {
    if (!description) {
      return null;
    }

    const normalizedDesc = description.toLowerCase().trim();

    // Extract merchant name from description
    const merchantName = MerchantExtractor.extractMerchant(description);

    // Get all patterns for this user (and default patterns)
    // Order by pattern_type (merchant first), then confidence, then usage_count
    const patterns = await prisma.categoryPattern.findMany({
      where: {
        OR: [{ userId }, { userId: null }],
      },
      include: {
        category: true,
      },
      orderBy: [
        { confidence: 'desc' },
        { usageCount: 'desc' },
      ],
    });

    // Separate patterns by type for prioritization
    const merchantPatterns = patterns.filter((p) => p.patternType === 'merchant');
    const keywordPatterns = patterns.filter((p) => p.patternType === 'keyword');
    const mccPatterns = patterns.filter((p) => p.patternType === 'mcc');

    // Priority 1: Try merchant patterns first (highest priority)
    if (merchantName) {
      for (const patternRecord of merchantPatterns) {
        const pattern = patternRecord.pattern.toLowerCase();
        const merchantLower = merchantName.toLowerCase();

        // Exact match or contains
        if (merchantLower === pattern || merchantLower.includes(pattern)) {
          // Increment usage count and adjust confidence
          await this.updatePatternUsage(patternRecord.id);
          return patternRecord.category as Category;
        }
      }
    }

    // Priority 2: Try keyword patterns
    for (const patternRecord of keywordPatterns) {
      const pattern = patternRecord.pattern.toLowerCase();

      // Simple keyword matching
      if (normalizedDesc.includes(pattern)) {
        await this.updatePatternUsage(patternRecord.id);
        return patternRecord.category as Category;
      }

      // Try regex matching if pattern looks like regex
      try {
        if (pattern.startsWith('/') && pattern.endsWith('/')) {
          const regexPattern = pattern.slice(1, -1);
          const regex = new RegExp(regexPattern, 'i');
          if (regex.test(normalizedDesc)) {
            await this.updatePatternUsage(patternRecord.id);
            return patternRecord.category as Category;
          }
        }
      } catch (error) {
        // Invalid regex, skip
        continue;
      }
    }

    // Priority 3: Try MCC-based categorization if available
    if (mcc) {
      // Check if we have an MCC pattern
      for (const patternRecord of mccPatterns) {
        if (patternRecord.pattern === mcc) {
          await this.updatePatternUsage(patternRecord.id);
          return patternRecord.category as Category;
        }
      }

      // Fallback to hardcoded MCC mapping
      const mccCategory = await this.categorizeByCCC(mcc, userId);
      if (mccCategory) {
        return mccCategory;
      }
    }

    return null;
  }

  /**
   * Update pattern usage count and confidence score
   * Validates: Requirements 22.4
   */
  private async updatePatternUsage(patternId: number): Promise<void> {
    const pattern = await prisma.categoryPattern.findUnique({
      where: { id: patternId },
    });

    if (pattern) {
      // Increment usage count
      const newUsageCount = pattern.usageCount + 1;

      // Increase confidence slightly (max 1.0)
      // Confidence increases by 0.05 per use, up to 1.0
      const newConfidence = Math.min(
        parseFloat(pattern.confidence.toString()) + 0.05,
        1.0
      );

      await prisma.categoryPattern.update({
        where: { id: patternId },
        data: {
          usageCount: newUsageCount,
          confidence: newConfidence,
        },
      });
    }
  }

  /**
   * Categorize based on Merchant Category Code (MCC)
   */
  private async categorizeByCCC(
    mcc: string,
    userId: string
  ): Promise<Category | null> {
    // Common MCC mappings
    const mccMappings: { [key: string]: string } = {
      '5411': 'Food', // Grocery stores
      '5812': 'Food', // Eating places, restaurants
      '5814': 'Food', // Fast food restaurants
      '4121': 'Transport', // Taxicabs and limousines
      '4131': 'Transport', // Bus lines
      '5541': 'Transport', // Service stations
      '5542': 'Transport', // Automated fuel dispensers
      '4900': 'Bills', // Utilities
      '4814': 'Bills', // Telecommunication services
      '7832': 'Entertainment', // Motion picture theaters
      '7922': 'Entertainment', // Theatrical producers
      '5999': 'Shopping', // Miscellaneous retail
    };

    const categoryName = mccMappings[mcc];
    if (!categoryName) {
      return null;
    }

    // Find category by name
    const category = await prisma.category.findFirst({
      where: {
        name: categoryName,
        OR: [{ userId }, { isDefault: true }],
      },
    });

    return category as Category | null;
  }

  /**
   * Update transaction category manually
   * Validates: Requirements 4.4, 5.3
   */
  async updateCategory(
    transactionId: string,
    categoryId: number,
    userId: string
  ): Promise<void> {
    // Verify transaction exists and belongs to user
    const transaction = await prisma.transaction.findFirst({
      where: { id: transactionId, userId },
    });

    if (!transaction) {
      throw new ValidationError('Transaction not found');
    }

    // Verify category exists
    const category = await prisma.category.findFirst({
      where: {
        id: categoryId,
        OR: [{ userId }, { isDefault: true }],
      },
    });

    if (!category) {
      throw new ValidationError('Category not found');
    }

    // Update transaction with MANUAL classification
    await prisma.transaction.update({
      where: { id: transactionId },
      data: {
        categoryId,
        classificationSource: 'MANUAL',
      },
    });
  }

  /**
   * Learn from manual categorization
   * Validates: Requirements 4.5, 22.1
   */
  async learnPattern(
    description: string,
    categoryId: number,
    userId: string
  ): Promise<void> {
    if (!description || description.trim().length === 0) {
      return;
    }

    const normalizedDesc = description.toLowerCase().trim();

    // Priority 1: Extract and store merchant pattern
    const merchantName = MerchantExtractor.extractMerchant(description);
    if (merchantName) {
      const merchantPattern = merchantName.toLowerCase();

      // Check if merchant pattern already exists
      const existingMerchantPattern = await prisma.categoryPattern.findFirst({
        where: {
          userId,
          pattern: merchantPattern,
          patternType: 'merchant',
          categoryId,
        },
      });

      if (existingMerchantPattern) {
        // Increase usage count and confidence
        await prisma.categoryPattern.update({
          where: { id: existingMerchantPattern.id },
          data: {
            usageCount: existingMerchantPattern.usageCount + 1,
            confidence: Math.min(
              parseFloat(existingMerchantPattern.confidence.toString()) + 0.1,
              1.0
            ),
          },
        });
      } else {
        // Create new merchant pattern with high initial confidence
        await prisma.categoryPattern.create({
          data: {
            userId,
            pattern: merchantPattern,
            patternType: 'merchant',
            categoryId,
            confidence: 0.9, // High confidence for merchant patterns
            usageCount: 1,
          },
        });
      }
    }

    // Priority 2: Extract and store keyword patterns
    const keywords = this.extractKeywords(normalizedDesc);

    for (const keyword of keywords) {
      // Check if keyword pattern already exists
      const existingPattern = await prisma.categoryPattern.findFirst({
        where: {
          userId,
          pattern: keyword,
          patternType: 'keyword',
          categoryId,
        },
      });

      if (existingPattern) {
        // Increase usage count and confidence
        await prisma.categoryPattern.update({
          where: { id: existingPattern.id },
          data: {
            usageCount: existingPattern.usageCount + 1,
            confidence: Math.min(
              parseFloat(existingPattern.confidence.toString()) + 0.1,
              1.0
            ),
          },
        });
      } else {
        // Create new keyword pattern with moderate confidence
        await prisma.categoryPattern.create({
          data: {
            userId,
            pattern: keyword,
            patternType: 'keyword',
            categoryId,
            confidence: 0.7,
            usageCount: 1,
          },
        });
      }
    }
  }

  /**
   * Extract merchant name from description
   * Validates: Requirements 22.1
   */
  extractMerchant(description: string): string | null {
    return MerchantExtractor.extractMerchant(description);
  }

  /**
   * Get categorization patterns for a user
   * Validates: Requirements 22.5
   */
  async getPatterns(
    userId: string,
    patternType?: string
  ): Promise<CategoryPattern[]> {
    const where: any = {
      OR: [{ userId }, { userId: null }],
    };

    if (patternType) {
      where.patternType = patternType;
    }

    const patterns = await prisma.categoryPattern.findMany({
      where,
      include: {
        category: {
          select: {
            id: true,
            name: true,
            icon: true,
            color: true,
          },
        },
      },
      orderBy: [
        { confidence: 'desc' },
        { usageCount: 'desc' },
      ],
    });

    return patterns as any[];
  }

  /**
   * Extract meaningful keywords from description
   */
  private extractKeywords(description: string): string[] {
    // Remove common words and extract meaningful terms
    const commonWords = [
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'payment',
      'purchase',
      'transaction',
    ];

    const words = description
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter((word) => word.length > 2 && !commonWords.includes(word));

    // Return unique words
    return [...new Set(words)].slice(0, 3); // Limit to 3 keywords
  }

  /**
   * Get or create uncategorized category
   */
  private async getUncategorizedCategory(): Promise<Category> {
    if (this.uncategorizedCategoryId) {
      const category = await prisma.category.findUnique({
        where: { id: this.uncategorizedCategoryId },
      });
      if (category) {
        return category as Category;
      }
    }

    // Find or create uncategorized category
    let category = await prisma.category.findFirst({
      where: {
        name: 'Uncategorized',
        isDefault: true,
      },
    });

    if (!category) {
      category = await prisma.category.create({
        data: {
          name: 'Uncategorized',
          type: 'expense',
          isDefault: true,
          icon: 'help_outline',
          color: '#9E9E9E',
        },
      });
    }

    this.uncategorizedCategoryId = category.id;
    return category as Category;
  }

  /**
   * Auto-categorize all uncategorized transactions for a user
   */
  async autoCategorizePendingTransactions(userId: string): Promise<number> {
    const uncategorized = await this.getUncategorizedCategory();

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        OR: [
          { categoryId: uncategorized.id },
          { categoryId: null },
        ],
      },
    });

    let categorizedCount = 0;

    for (const transaction of transactions) {
      const category = await this.categorizeTransaction({
        id: transaction.id,
        description: transaction.normalizedDescription || transaction.rawDescription || '',
        mcc: transaction.mcc || undefined,
        userId,
      });

      // Only update if we found a better category
      if (category.id !== uncategorized.id) {
        await prisma.transaction.update({
          where: { id: transaction.id },
          data: {
            categoryId: category.id,
            classificationSource: 'AUTO',
          },
        });
        categorizedCount++;
      }
    }

    return categorizedCount;
  }
}
