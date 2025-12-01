import { PrismaClient } from '@prisma/client';
import { ValidationError, NotFoundError } from '../middlewares/errorHandler';

const prisma = new PrismaClient();

export interface CreateBudgetInput {
  userId: string;
  month: number;
  year: number;
  categoryId: number;
  amountLimit: number;
}

export class BudgetService {
  async createOrUpdateBudget(input: CreateBudgetInput) {
    const { userId, month, year, categoryId, amountLimit } = input;

    // Validate month and year
    if (month < 1 || month > 12) {
      throw new ValidationError('Month must be between 1 and 12');
    }
    if (year < 2000) {
      throw new ValidationError('Invalid year');
    }

    // Upsert budget
    const budget = await prisma.budget.upsert({
      where: {
        unique_budget: { userId, month, year, categoryId },
      },
      update: { amountLimit },
      create: { userId, month, year, categoryId, amountLimit },
      include: { category: true },
    });

    return budget;
  }

  async getBudgetSummary(userId: string, month: number, year: number) {
    const budgets = await prisma.budget.findMany({
      where: { userId, month, year },
      include: { category: true },
    });

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const summaries = await Promise.all(
      budgets.map(async (budget) => {
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

        let status = 'normal';
        if (percentage >= 100) status = 'exceeded';
        else if (percentage >= 80) status = 'warning';

        return {
          budgetId: budget.id,
          category: budget.category,
          limit: limitAmount,
          spent: spentAmount,
          remaining: limitAmount - spentAmount,
          percentage: Math.min(percentage, 100),
          status,
        };
      })
    );

    const totalBudget = summaries.reduce((sum, s) => sum + s.limit, 0);
    const totalSpent = summaries.reduce((sum, s) => sum + s.spent, 0);

    return {
      month,
      year,
      totalBudget,
      totalSpent,
      usagePercentage: totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
      categories: summaries,
    };
  }

  async deleteBudget(id: string, userId: string) {
    const budget = await prisma.budget.findFirst({
      where: { id, userId },
    });

    if (!budget) {
      throw new NotFoundError('Budget not found');
    }

    await prisma.budget.delete({ where: { id } });
    return { message: 'Budget deleted successfully' };
  }

  async getBudgetHistory(userId: string, months: number = 6) {
    const history = [];
    const currentDate = new Date();
    
    // Generate list of months to fetch
    for (let i = 0; i < months; i++) {
      const targetDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const month = targetDate.getMonth() + 1;
      const year = targetDate.getFullYear();
      
      const summary = await this.getBudgetSummary(userId, month, year);
      history.push(summary);
    }
    
    return {
      months: history.length,
      hasInsufficientData: history.length < months,
      history,
    };
  }

  async compareBudgets(
    userId: string,
    month1: number,
    year1: number,
    month2: number,
    year2: number
  ) {
    // Get summaries for both months
    const summary1 = await this.getBudgetSummary(userId, month1, year1);
    const summary2 = await this.getBudgetSummary(userId, month2, year2);

    // Calculate changes by category
    const categoryChanges: Array<{
      categoryId: number;
      categoryName: string;
      month1Spent: number;
      month2Spent: number;
      difference: number;
      percentageChange: number;
      isSignificant: boolean;
    }> = [];
    const categoriesMap = new Map<number, {
      categoryId: number;
      categoryName: string;
      month1Spent: number;
      month2Spent: number;
    }>();

    // Build map of categories from both months
    summary1.categories.forEach((cat) => {
      categoriesMap.set(cat.category.id, {
        categoryId: cat.category.id,
        categoryName: cat.category.name,
        month1Spent: cat.spent,
        month2Spent: 0,
      });
    });

    summary2.categories.forEach((cat) => {
      const existing = categoriesMap.get(cat.category.id);
      if (existing) {
        existing.month2Spent = cat.spent;
      } else {
        categoriesMap.set(cat.category.id, {
          categoryId: cat.category.id,
          categoryName: cat.category.name,
          month1Spent: 0,
          month2Spent: cat.spent,
        });
      }
    });

    // Calculate differences and percentage changes
    categoriesMap.forEach((value) => {
      const difference = value.month2Spent - value.month1Spent;
      const percentageChange =
        value.month1Spent > 0
          ? ((difference / value.month1Spent) * 100)
          : value.month2Spent > 0
          ? 100
          : 0;

      categoryChanges.push({
        categoryId: value.categoryId,
        categoryName: value.categoryName,
        month1Spent: value.month1Spent,
        month2Spent: value.month2Spent,
        difference,
        percentageChange: Math.round(percentageChange * 100) / 100,
        isSignificant: Math.abs(percentageChange) > 20,
      });
    });

    // Sort by absolute difference (largest changes first)
    categoryChanges.sort((a, b) => Math.abs(b.difference) - Math.abs(a.difference));

    // Calculate overall change
    const overallDifference = summary2.totalSpent - summary1.totalSpent;
    const overallPercentageChange =
      summary1.totalSpent > 0
        ? ((overallDifference / summary1.totalSpent) * 100)
        : summary2.totalSpent > 0
        ? 100
        : 0;

    return {
      month1: {
        month: month1,
        year: year1,
        totalBudget: summary1.totalBudget,
        totalSpent: summary1.totalSpent,
        usagePercentage: summary1.usagePercentage,
      },
      month2: {
        month: month2,
        year: year2,
        totalBudget: summary2.totalBudget,
        totalSpent: summary2.totalSpent,
        usagePercentage: summary2.usagePercentage,
      },
      categoryChanges,
      overallChange: {
        difference: overallDifference,
        percentageChange: Math.round(overallPercentageChange * 100) / 100,
      },
    };
  }
}
