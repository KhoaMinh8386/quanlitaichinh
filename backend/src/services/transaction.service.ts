import { PrismaClient } from '@prisma/client';
import { ValidationError, NotFoundError } from '../middlewares/errorHandler';

const prisma = new PrismaClient();

export interface TransactionFilters {
  userId: string;
  from?: Date;
  to?: Date;
  type?: 'income' | 'expense';
  categoryId?: number;
  accountId?: string;
  page?: number;
  limit?: number;
}

export interface UpdateTransactionInput {
  categoryId?: number;
  notes?: string;
}

export class TransactionService {
  async getTransactions(filters: TransactionFilters) {
    const {
      userId,
      from,
      to,
      type,
      categoryId,
      accountId,
      page = 1,
      limit = 20,
    } = filters;

    const skip = (page - 1) * limit;

    const where: any = {
      userId,
    };

    if (from || to) {
      where.postedAt = {};
      if (from) where.postedAt.gte = from;
      if (to) where.postedAt.lte = to;
    }

    if (type) {
      where.type = type;
    }

    if (categoryId) {
      where.categoryId = categoryId;
    }

    if (accountId) {
      where.bankAccountId = accountId;
    }

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
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
          bankAccount: {
            select: {
              id: true,
              bankName: true,
              accountAlias: true,
            },
          },
        },
        orderBy: {
          postedAt: 'desc',
        },
        skip,
        take: limit,
      }),
      prisma.transaction.count({ where }),
    ]);

    return {
      transactions: transactions.map((t: any) => ({
        id: t.id,
        amount: Number(t.amount),
        type: t.type,
        description: t.normalizedDescription || t.rawDescription || '',
        postedAt: t.postedAt,
        category: t.category,
        account: t.bankAccount,
        notes: t.notes,
        classificationSource: t.classificationSource,
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getTransactionById(id: string, userId: string) {
    const transaction = await prisma.transaction.findFirst({
      where: {
        id,
        userId,
      },
      include: {
        category: {
          select: {
            id: true,
            name: true,
            icon: true,
            color: true,
          },
        },
        bankAccount: {
          select: {
            id: true,
            bankName: true,
            accountAlias: true,
            accountNumberMask: true,
          },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundError('Transaction not found');
    }

    return {
      id: transaction.id,
      amount: Number(transaction.amount),
      type: transaction.type,
      description: transaction.normalizedDescription || transaction.rawDescription || '',
      rawDescription: transaction.rawDescription,
      postedAt: transaction.postedAt,
      category: transaction.category,
      account: transaction.bankAccount,
      notes: transaction.notes,
      classificationSource: transaction.classificationSource,
      mcc: transaction.mcc,
    };
  }

  async updateTransactionCategory(
    id: string,
    userId: string,
    categoryId: number
  ) {
    // Verify transaction exists and belongs to user
    const transaction = await prisma.transaction.findFirst({
      where: { id, userId },
    });

    if (!transaction) {
      throw new NotFoundError('Transaction not found');
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

    // Update transaction
    const updated = await prisma.transaction.update({
      where: { id },
      data: {
        categoryId,
        classificationSource: 'MANUAL',
      },
      include: {
        category: true,
      },
    });

    return {
      id: updated.id,
      categoryId: updated.categoryId,
      category: updated.category,
      classificationSource: updated.classificationSource,
    };
  }

  async updateTransaction(
    id: string,
    userId: string,
    data: UpdateTransactionInput
  ) {
    // Verify transaction exists and belongs to user
    const transaction = await prisma.transaction.findFirst({
      where: { id, userId },
    });

    if (!transaction) {
      throw new NotFoundError('Transaction not found');
    }

    const updateData: any = {};

    if (data.categoryId !== undefined) {
      // Verify category exists
      const category = await prisma.category.findFirst({
        where: {
          id: data.categoryId,
          OR: [{ userId }, { isDefault: true }],
        },
      });

      if (!category) {
        throw new ValidationError('Category not found');
      }

      updateData.categoryId = data.categoryId;
      updateData.classificationSource = 'MANUAL';
    }

    if (data.notes !== undefined) {
      updateData.notes = data.notes;
    }

    const updated = await prisma.transaction.update({
      where: { id },
      data: updateData,
      include: {
        category: true,
        bankAccount: true,
      },
    });

    return {
      id: updated.id,
      amount: Number(updated.amount),
      type: updated.type,
      description: updated.normalizedDescription || updated.rawDescription || '',
      postedAt: updated.postedAt,
      category: updated.category,
      account: updated.bankAccount,
      notes: updated.notes,
      classificationSource: updated.classificationSource,
    };
  }

  async getTransactionStats(userId: string, from: Date, to: Date) {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        postedAt: {
          gte: from,
          lte: to,
        },
      },
    });

    const income = transactions
      .filter((t: any) => t.type === 'income')
      .reduce((sum: number, t: any) => sum + Number(t.amount), 0);

    const expense = transactions
      .filter((t: any) => t.type === 'expense')
      .reduce((sum: number, t: any) => sum + Number(t.amount), 0);

    return {
      totalIncome: income,
      totalExpense: expense,
      netBalance: income - expense,
      savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0,
      transactionCount: transactions.length,
    };
  }

  async createTransaction(
    userId: string,
    data: {
      amount: number;
      type: 'income' | 'expense';
      categoryId: number;
      description?: string;
      postedAt?: Date;
      accountId?: string;
    }
  ) {
    // Verify category exists and belongs to user or is default
    const category = await prisma.category.findFirst({
      where: {
        id: data.categoryId,
        OR: [{ userId }, { isDefault: true }],
      },
    });

    if (!category) {
      throw new ValidationError('Category not found');
    }

    // Verify category type matches transaction type
    if (category.type !== data.type) {
      throw new ValidationError(
        `Category type (${category.type}) does not match transaction type (${data.type})`
      );
    }

    // Get or create a default bank account for manual transactions
    let bankAccountId = data.accountId;
    
    if (!bankAccountId) {
      // Try to find an existing manual account
      let manualAccount = await prisma.bankAccount.findFirst({
        where: {
          userId,
          bankName: 'Manual Entry',
        },
      });

      // Create one if it doesn't exist
      if (!manualAccount) {
        // First, we need a bank connection
        let manualConnection = await prisma.bankConnection.findFirst({
          where: {
            userId,
            status: 'manual',
          },
        });

        if (!manualConnection) {
          // Get or create manual bank provider
          let manualProvider = await prisma.bankProvider.findFirst({
            where: { code: 'MANUAL' },
          });

          if (!manualProvider) {
            manualProvider = await prisma.bankProvider.create({
              data: {
                name: 'Manual Entry',
                code: 'MANUAL',
                authType: 'none',
                apiBaseUrl: 'none',
              },
            });
          }

          manualConnection = await prisma.bankConnection.create({
            data: {
              userId,
              bankProviderId: manualProvider.id,
              accessToken: 'manual',
              refreshToken: 'manual',
              tokenExpiresAt: new Date('2099-12-31'),
              status: 'manual',
            },
          });
        }

        manualAccount = await prisma.bankAccount.create({
          data: {
            userId,
            connectionId: manualConnection.id,
            bankName: 'Manual Entry',
            accountType: 'manual',
            currency: 'VND',
            status: 'active',
          },
        });
      }

      bankAccountId = manualAccount.id;
    }

    // Create the transaction
    const transaction = await prisma.transaction.create({
      data: {
        userId,
        bankAccountId,
        amount: data.amount,
        type: data.type,
        rawDescription: data.description || 'Manual transaction',
        normalizedDescription: data.description || 'Manual transaction',
        postedAt: data.postedAt || new Date(),
        categoryId: data.categoryId,
        classificationSource: 'MANUAL',
      },
      include: {
        category: {
          select: {
            id: true,
            name: true,
            icon: true,
            color: true,
            type: true,
          },
        },
        bankAccount: {
          select: {
            id: true,
            bankName: true,
            accountAlias: true,
          },
        },
      },
    });

    return {
      id: transaction.id,
      amount: Number(transaction.amount),
      type: transaction.type,
      description: transaction.normalizedDescription || transaction.rawDescription || '',
      postedAt: transaction.postedAt,
      category: transaction.category,
      account: transaction.bankAccount,
      notes: transaction.notes,
      classificationSource: transaction.classificationSource,
    };
  }

  async bulkUpdateCategory(
    transactionIds: string[],
    categoryId: number,
    userId: string
  ) {
    console.log(`[BulkUpdate] Starting bulk update for ${transactionIds.length} transactions`);
    console.log(`[BulkUpdate] User: ${userId}, Target Category: ${categoryId}`);

    // Verify category exists and belongs to user or is default
    const category = await prisma.category.findFirst({
      where: {
        id: categoryId,
        OR: [{ userId }, { isDefault: true }],
      },
    });

    if (!category) {
      throw new ValidationError('Category not found');
    }

    const successIds: string[] = [];
    const failedIds: string[] = [];

    // Use database transaction for atomicity
    await prisma.$transaction(async (tx) => {
      for (const transactionId of transactionIds) {
        try {
          // Verify transaction exists and belongs to user
          const transaction = await tx.transaction.findFirst({
            where: {
              id: transactionId,
              userId,
            },
          });

          if (!transaction) {
            console.log(`[BulkUpdate] Transaction ${transactionId} not found or doesn't belong to user`);
            failedIds.push(transactionId);
            continue;
          }

          // Update the transaction
          await tx.transaction.update({
            where: { id: transactionId },
            data: {
              categoryId,
              classificationSource: 'MANUAL',
            },
          });

          successIds.push(transactionId);
          console.log(`[BulkUpdate] Successfully updated transaction ${transactionId}`);
        } catch (error) {
          console.error(`[BulkUpdate] Error updating transaction ${transactionId}:`, error);
          failedIds.push(transactionId);
        }
      }
    });

    console.log(`[BulkUpdate] Completed: ${successIds.length} successful, ${failedIds.length} failed`);

    return {
      successCount: successIds.length,
      failedCount: failedIds.length,
      failedIds,
    };
  }
}
