import { PrismaClient } from '@prisma/client';
import { ValidationError, NotFoundError } from '../middlewares/errorHandler';

const prisma = new PrismaClient();

export interface CategoryRuleInput {
  categoryId: number;
  keyword: string;
  priority?: number;
}

export class CategoryRuleService {
  /**
   * Remove Vietnamese diacritics and normalize text
   */
  normalizeVietnamese(text: string): string {
    const vietnameseMap: { [key: string]: string } = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
      'À': 'A', 'Á': 'A', 'Ạ': 'A', 'Ả': 'A', 'Ã': 'A',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ậ': 'A', 'Ẩ': 'A', 'Ẫ': 'A',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ặ': 'A', 'Ẳ': 'A', 'Ẵ': 'A',
      'È': 'E', 'É': 'E', 'Ẹ': 'E', 'Ẻ': 'E', 'Ẽ': 'E',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ệ': 'E', 'Ể': 'E', 'Ễ': 'E',
      'Ì': 'I', 'Í': 'I', 'Ị': 'I', 'Ỉ': 'I', 'Ĩ': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ọ': 'O', 'Ỏ': 'O', 'Õ': 'O',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ộ': 'O', 'Ổ': 'O', 'Ỗ': 'O',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ợ': 'O', 'Ở': 'O', 'Ỡ': 'O',
      'Ù': 'U', 'Ú': 'U', 'Ụ': 'U', 'Ủ': 'U', 'Ũ': 'U',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ự': 'U', 'Ử': 'U', 'Ữ': 'U',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỵ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y',
      'Đ': 'D',
    };

    return text
      .split('')
      .map(char => vietnameseMap[char] || char)
      .join('')
      .toLowerCase()
      .trim();
  }

  /**
   * Categorize transaction description using rules
   * Returns the category with highest priority match
   */
  async categorizeByRules(description: string): Promise<{
    categoryId: number;
    categoryName: string;
    matchedKeyword: string;
    confidence: number;
  } | null> {
    const normalizedDesc = this.normalizeVietnamese(description);

    // Get all active rules, ordered by priority (lower = higher priority)
    const rules = await prisma.categoryRule.findMany({
      where: { isActive: true },
      include: {
        category: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { priority: 'asc' },
    });

    // Find first matching rule
    for (const rule of rules) {
      if (normalizedDesc.includes(rule.keywordNormalized)) {
        // Calculate confidence based on priority
        const confidence = Math.max(0.5, 1 - (rule.priority * 0.1));
        
        return {
          categoryId: rule.categoryId,
          categoryName: rule.category.name,
          matchedKeyword: rule.keyword,
          confidence,
        };
      }
    }

    return null;
  }

  /**
   * Get all rules
   */
  async getAllRules(): Promise<any[]> {
    return prisma.categoryRule.findMany({
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
        { priority: 'asc' },
        { keyword: 'asc' },
      ],
    });
  }

  /**
   * Get rules by category
   */
  async getRulesByCategory(categoryId: number): Promise<any[]> {
    return prisma.categoryRule.findMany({
      where: { categoryId },
      orderBy: { priority: 'asc' },
    });
  }

  /**
   * Create a new rule
   */
  async createRule(input: CategoryRuleInput): Promise<any> {
    // Verify category exists
    const category = await prisma.category.findUnique({
      where: { id: input.categoryId },
    });

    if (!category) {
      throw new NotFoundError('Category not found');
    }

    const keywordNormalized = this.normalizeVietnamese(input.keyword);

    // Check for existing rule with same keyword and category
    const existing = await prisma.categoryRule.findFirst({
      where: {
        keyword: input.keyword,
        categoryId: input.categoryId,
      },
    });

    if (existing) {
      throw new ValidationError('Rule with this keyword already exists for this category');
    }

    return prisma.categoryRule.create({
      data: {
        categoryId: input.categoryId,
        keyword: input.keyword,
        keywordNormalized,
        priority: input.priority ?? 5,
        isActive: true,
      },
      include: {
        category: true,
      },
    });
  }

  /**
   * Create rule from manual categorization
   * Used when user manually categorizes and checks "Remember"
   */
  async createRuleFromTransaction(
    description: string,
    categoryId: number
  ): Promise<any> {
    // Extract meaningful keywords from description
    const keywords = this.extractKeywords(description);

    if (keywords.length === 0) {
      throw new ValidationError('Could not extract keywords from description');
    }

    // Use the first (most significant) keyword
    const keyword = keywords[0];
    const keywordNormalized = this.normalizeVietnamese(keyword);

    // Check if rule already exists
    const existing = await prisma.categoryRule.findFirst({
      where: {
        keywordNormalized,
        categoryId,
      },
    });

    if (existing) {
      // Update existing rule priority
      return prisma.categoryRule.update({
        where: { id: existing.id },
        data: {
          priority: Math.max(0, existing.priority - 1), // Increase priority
        },
        include: { category: true },
      });
    }

    return this.createRule({
      categoryId,
      keyword,
      priority: 5, // Medium priority for user-created rules
    });
  }

  /**
   * Extract meaningful keywords from description
   */
  private extractKeywords(description: string): string[] {
    const normalized = this.normalizeVietnamese(description);
    
    // Common words to exclude
    const stopWords = [
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'up', 'about', 'into', 'over', 'after',
      'chuyen', 'tien', 'thanh', 'toan', 'giao', 'dich', 'ma', 'so',
      'ngay', 'thang', 'nam', 'qua', 'tai', 'khoan', 'ngan', 'hang',
      'vnd', 'dong', 'payment', 'transfer', 'transaction',
    ];

    const words = normalized
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter(word => 
        word.length > 2 && 
        !stopWords.includes(word) &&
        !/^\d+$/.test(word) // Exclude pure numbers
      );

    // Remove duplicates and return first 3
    return [...new Set(words)].slice(0, 3);
  }

  /**
   * Update rule
   */
  async updateRule(
    id: number,
    data: { keyword?: string; priority?: number; isActive?: boolean }
  ): Promise<any> {
    const rule = await prisma.categoryRule.findUnique({ where: { id } });

    if (!rule) {
      throw new NotFoundError('Rule not found');
    }

    const updateData: any = {};

    if (data.keyword !== undefined) {
      updateData.keyword = data.keyword;
      updateData.keywordNormalized = this.normalizeVietnamese(data.keyword);
    }

    if (data.priority !== undefined) {
      updateData.priority = data.priority;
    }

    if (data.isActive !== undefined) {
      updateData.isActive = data.isActive;
    }

    return prisma.categoryRule.update({
      where: { id },
      data: updateData,
      include: { category: true },
    });
  }

  /**
   * Delete rule
   */
  async deleteRule(id: number): Promise<void> {
    const rule = await prisma.categoryRule.findUnique({ where: { id } });

    if (!rule) {
      throw new NotFoundError('Rule not found');
    }

    await prisma.categoryRule.delete({ where: { id } });
  }
}

