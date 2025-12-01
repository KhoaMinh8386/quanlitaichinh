import { PrismaClient } from '@prisma/client';
import { NotFoundError } from '../middlewares/errorHandler';

const prisma = new PrismaClient();

export type AlertType = 
  | 'BUDGET_WARNING' 
  | 'BUDGET_EXCEEDED' 
  | 'INFO' 
  | 'SUCCESS'
  | 'LARGE_TRANSACTION'
  | 'UNUSUAL_SPENDING'
  | 'CATEGORY_SPIKE';

export interface CreateAlertInput {
  userId: string;
  alertType: AlertType;
  message: string;
  payload?: any;
}

export interface Alert {
  id: string;
  userId: string;
  alertType: string;
  message: string;
  payload: any;
  readFlag: boolean;
  createdAt: Date;
}

export class AlertService {
  /**
   * Create a new alert
   * Validates: Requirements 7.3
   */
  async createAlert(input: CreateAlertInput): Promise<Alert> {
    const { userId, alertType, message, payload = {} } = input;

    const alert = await prisma.alert.create({
      data: {
        userId,
        alertType,
        message,
        payload,
        readFlag: false,
      },
    });

    return alert as Alert;
  }

  /**
   * Get all alerts for a user
   * Validates: Requirements 7.4
   */
  async getUserAlerts(userId: string, unreadOnly: boolean = false): Promise<Alert[]> {
    const where: any = { userId };

    if (unreadOnly) {
      where.readFlag = false;
    }

    const alerts = await prisma.alert.findMany({
      where,
      orderBy: {
        createdAt: 'desc',
      },
    });

    return alerts as Alert[];
  }

  /**
   * Mark alert as read
   * Validates: Requirements 7.5
   */
  async markAsRead(alertId: string, userId: string): Promise<void> {
    // Verify alert belongs to user
    const alert = await prisma.alert.findFirst({
      where: { id: alertId, userId },
    });

    if (!alert) {
      throw new NotFoundError('Alert not found');
    }

    await prisma.alert.update({
      where: { id: alertId },
      data: { readFlag: true },
    });
  }

  /**
   * Mark all alerts as read
   */
  async markAllAsRead(userId: string): Promise<number> {
    const result = await prisma.alert.updateMany({
      where: {
        userId,
        readFlag: false,
      },
      data: {
        readFlag: true,
      },
    });

    return result.count;
  }

  /**
   * Delete an alert
   */
  async deleteAlert(alertId: string, userId: string): Promise<void> {
    // Verify alert belongs to user
    const alert = await prisma.alert.findFirst({
      where: { id: alertId, userId },
    });

    if (!alert) {
      throw new NotFoundError('Alert not found');
    }

    await prisma.alert.delete({
      where: { id: alertId },
    });
  }

  /**
   * Check budgets and create alerts if needed
   * Validates: Requirements 7.1, 7.2
   */
  async checkBudgetsAndCreateAlerts(userId: string, month: number, year: number): Promise<void> {
    const budgets = await prisma.budget.findMany({
      where: { userId, month, year },
      include: { category: true },
    });

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    for (const budget of budgets) {
      const spent = await prisma.transaction.aggregate({
        where: {
          userId,
          categoryId: budget.categoryId,
          type: 'expense',
          postedAt: { gte: startDate, lte: endDate },
        },
        _sum: { amount: true },
      });

      const spentAmount = Number(spent._sum.amount || 0);
      const limitAmount = Number(budget.amountLimit);
      const percentage = (spentAmount / limitAmount) * 100;

      // Check if we need to create alerts
      if (percentage >= 100) {
        // Check if alert already exists
        const existingAlert = await prisma.alert.findFirst({
          where: {
            userId,
            alertType: 'BUDGET_EXCEEDED',
            payload: {
              path: ['budgetId'],
              equals: budget.id,
            },
            createdAt: {
              gte: startDate,
            },
          },
        });

        if (!existingAlert) {
          await this.createAlert({
            userId,
            alertType: 'BUDGET_EXCEEDED',
            message: `You have exceeded your budget for ${budget.category.name}. Spent: ${spentAmount.toFixed(0)} / ${limitAmount.toFixed(0)}`,
            payload: {
              budgetId: budget.id,
              categoryId: budget.categoryId,
              categoryName: budget.category.name,
              spent: spentAmount,
              limit: limitAmount,
              percentage,
            },
          });
        }
      } else if (percentage >= 80) {
        // Check if alert already exists
        const existingAlert = await prisma.alert.findFirst({
          where: {
            userId,
            alertType: 'BUDGET_WARNING',
            payload: {
              path: ['budgetId'],
              equals: budget.id,
            },
            createdAt: {
              gte: startDate,
            },
          },
        });

        if (!existingAlert) {
          await this.createAlert({
            userId,
            alertType: 'BUDGET_WARNING',
            message: `Warning: You have used ${percentage.toFixed(0)}% of your budget for ${budget.category.name}`,
            payload: {
              budgetId: budget.id,
              categoryId: budget.categoryId,
              categoryName: budget.category.name,
              spent: spentAmount,
              limit: limitAmount,
              percentage,
            },
          });
        }
      }
    }
  }

  /**
   * Get unread alert count
   */
  async getUnreadCount(userId: string): Promise<number> {
    return await prisma.alert.count({
      where: {
        userId,
        readFlag: false,
      },
    });
  }

  /**
   * Check for large transaction alert
   * Validates: Requirements 6.1
   */
  async checkLargeTransaction(
    userId: string,
    transactionId: string,
    amount: number,
    description: string,
    threshold: number = 5000000
  ): Promise<void> {
    if (amount >= threshold) {
      await this.createAlert({
        userId,
        alertType: 'LARGE_TRANSACTION',
        message: `Phát hiện giao dịch lớn: ${amount.toLocaleString('vi-VN')} VND - ${description}`,
        payload: {
          transactionId,
          amount,
          description,
          threshold,
        },
      });
    }
  }

  /**
   * Check for unusual spending based on average
   * Validates: Requirements 6.2
   */
  async checkUnusualSpending(
    userId: string,
    transactionId: string,
    amount: number,
    description: string,
    multiplier: number = 3
  ): Promise<void> {
    // Get average spending over last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const avgResult = await prisma.transaction.aggregate({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: thirtyDaysAgo },
        id: { not: transactionId },
      },
      _avg: { amount: true },
      _count: true,
    });

    const avgAmount = Number(avgResult._avg.amount || 0);
    const count = avgResult._count;

    // Only check if we have enough historical data
    if (count >= 5 && avgAmount > 0 && amount > avgAmount * multiplier) {
      await this.createAlert({
        userId,
        alertType: 'UNUSUAL_SPENDING',
        message: `Giao dịch bất thường: ${amount.toLocaleString('vi-VN')} VND - gấp ${(amount / avgAmount).toFixed(1)} lần mức chi trung bình`,
        payload: {
          transactionId,
          amount,
          averageAmount: avgAmount,
          multiplier: amount / avgAmount,
          description,
        },
      });
    }
  }

  /**
   * Check for category spending spike
   * Validates: Requirements 6.3
   */
  async checkCategorySpike(
    userId: string,
    categoryId: number,
    categoryName: string,
    currentMonthSpending: number,
    threshold: number = 150
  ): Promise<void> {
    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    // Get average spending for this category over past 3 months
    const threeMonthsAgo = new Date(currentYear, currentMonth - 3, 1);
    const lastMonthEnd = new Date(currentYear, currentMonth, 0, 23, 59, 59);

    const historicalResult = await prisma.transaction.aggregate({
      where: {
        userId,
        categoryId,
        type: 'expense',
        postedAt: { gte: threeMonthsAgo, lte: lastMonthEnd },
      },
      _sum: { amount: true },
    });

    const historicalTotal = Number(historicalResult._sum.amount || 0);
    const monthlyAverage = historicalTotal / 3;

    if (monthlyAverage > 0) {
      const spikePercentage = (currentMonthSpending / monthlyAverage) * 100;

      if (spikePercentage >= threshold) {
        // Check if alert already exists for this category this month
        const monthStart = new Date(currentYear, currentMonth, 1);
        const existingAlert = await prisma.alert.findFirst({
          where: {
            userId,
            alertType: 'CATEGORY_SPIKE',
            payload: {
              path: ['categoryId'],
              equals: categoryId,
            },
            createdAt: { gte: monthStart },
          },
        });

        if (!existingAlert) {
          await this.createAlert({
            userId,
            alertType: 'CATEGORY_SPIKE',
            message: `Chi tiêu danh mục "${categoryName}" tăng ${spikePercentage.toFixed(0)}% so với trung bình 3 tháng trước`,
            payload: {
              categoryId,
              categoryName,
              currentSpending: currentMonthSpending,
              averageSpending: monthlyAverage,
              spikePercentage,
            },
          });
        }
      }
    }
  }
}
