import { Response, NextFunction } from 'express';
import { TransactionService } from '../services/transaction.service';
import { AuthRequest } from '../middlewares/auth';

const transactionService = new TransactionService();

export class TransactionController {
  async getTransactions(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const {
        from,
        to,
        type,
        categoryId,
        accountId,
        page,
        limit,
      } = req.query;

      const filters: any = { userId };

      if (from) filters.from = new Date(from as string);
      if (to) filters.to = new Date(to as string);
      if (type) filters.type = type;
      if (categoryId) filters.categoryId = parseInt(categoryId as string);
      if (accountId) filters.accountId = accountId;
      if (page) filters.page = parseInt(page as string);
      if (limit) filters.limit = parseInt(limit as string);

      const result = await transactionService.getTransactions(filters);

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getTransactionById(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { id } = req.params;

      const transaction = await transactionService.getTransactionById(
        id,
        userId
      );

      res.status(200).json(transaction);
    } catch (error) {
      next(error);
    }
  }

  async updateTransactionCategory(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { id } = req.params;
      const { categoryId } = req.body;

      if (!categoryId) {
        return next(new Error('Category ID is required'));
      }

      const result = await transactionService.updateTransactionCategory(
        id,
        userId,
        categoryId
      );

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateTransaction(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { id } = req.params;
      const { categoryId, notes } = req.body;

      const result = await transactionService.updateTransaction(id, userId, {
        categoryId,
        notes,
      });

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getTransactionStats(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { from, to } = req.query;

      if (!from || !to) {
        return next(new Error('From and to dates are required'));
      }

      const stats = await transactionService.getTransactionStats(
        userId,
        new Date(from as string),
        new Date(to as string)
      );

      res.status(200).json(stats);
    } catch (error) {
      next(error);
    }
  }

  async createTransaction(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { amount, type, categoryId, description, postedAt, accountId } = req.body;

      // Validation
      if (!amount || amount <= 0) {
        return next(new Error('Amount must be greater than 0'));
      }

      if (!type || !['income', 'expense'].includes(type)) {
        return next(new Error('Type must be either income or expense'));
      }

      if (!categoryId) {
        return next(new Error('Category ID is required'));
      }

      const transaction = await transactionService.createTransaction(userId, {
        amount: parseFloat(amount),
        type,
        categoryId: parseInt(categoryId),
        description,
        postedAt: postedAt ? new Date(postedAt) : undefined,
        accountId,
      });

      res.status(201).json(transaction);
    } catch (error) {
      next(error);
    }
  }

  async bulkUpdateCategory(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const { transactionIds, categoryId } = req.body;

      // Validation
      if (!transactionIds || !Array.isArray(transactionIds) || transactionIds.length === 0) {
        return next(new Error('Transaction IDs array is required and must not be empty'));
      }

      if (!categoryId) {
        return next(new Error('Category ID is required'));
      }

      const result = await transactionService.bulkUpdateCategory(
        transactionIds,
        parseInt(categoryId),
        userId
      );

      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}
