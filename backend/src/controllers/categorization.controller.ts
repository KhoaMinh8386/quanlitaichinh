import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middlewares/auth';
import { CategorizationService } from '../services/categorization.service';

const categorizationService = new CategorizationService();

export class CategorizationController {
  /**
   * Manually update transaction category and learn from it
   */
  async updateTransactionCategory(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { transactionId } = req.params;
      const { categoryId } = req.body;
      const userId = req.userId!;

      // Update category
      await categorizationService.updateCategory(
        transactionId,
        categoryId,
        userId
      );

      // Get transaction to learn pattern
      const { PrismaClient } = await import('@prisma/client');
      const prisma = new PrismaClient();
      const transaction = await prisma.transaction.findUnique({
        where: { id: transactionId },
      });

      if (transaction) {
        const description =
          transaction.normalizedDescription || transaction.rawDescription || '';
        await categorizationService.learnPattern(description, categoryId, userId);
      }

      res.status(200).json({
        message: 'Category updated successfully',
        transactionId,
        categoryId,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Auto-categorize all pending transactions
   */
  async autoCategorizePending(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;

      const count = await categorizationService.autoCategorizePendingTransactions(
        userId
      );

      res.status(200).json({
        message: 'Auto-categorization completed',
        categorizedCount: count,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get categorization patterns for user
   * Validates: Requirements 22.5
   */
  async getPatterns(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { type } = req.query;

      // Validate pattern type if provided
      if (type && !['merchant', 'keyword', 'mcc'].includes(type as string)) {
        res.status(400).json({
          message: 'Invalid pattern type. Must be merchant, keyword, or mcc',
        });
        return;
      }

      const patterns = await categorizationService.getPatterns(
        userId,
        type as string | undefined
      );

      res.status(200).json({
        patterns: patterns.map((p) => ({
          id: p.id,
          pattern: p.pattern,
          patternType: p.patternType,
          categoryId: p.categoryId,
          confidence: parseFloat(p.confidence.toString()),
          usageCount: p.usageCount,
          category: (p as any).category,
        })),
        total: patterns.length,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete a categorization pattern
   */
  async deletePattern(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { patternId } = req.params;
      const userId = req.userId!;

      const { PrismaClient } = await import('@prisma/client');
      const prisma = new PrismaClient();

      // Verify pattern belongs to user
      const pattern = await prisma.categoryPattern.findFirst({
        where: {
          id: parseInt(patternId),
          userId,
        },
      });

      if (!pattern) {
        res.status(404).json({ message: 'Pattern not found' });
        return;
      }

      await prisma.categoryPattern.delete({
        where: { id: parseInt(patternId) },
      });

      res.status(200).json({ message: 'Pattern deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
}
