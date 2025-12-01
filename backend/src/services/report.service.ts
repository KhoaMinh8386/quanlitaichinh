import { PrismaClient } from '@prisma/client';
import { MerchantExtractor } from '../utils/merchantExtractor';

const prisma = new PrismaClient();

export class ReportService {
  async getOverview(userId: string, from: Date, to: Date) {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        postedAt: { gte: from, lte: to },
      },
      include: { category: true },
    });

    const income = transactions
      .filter((t: any) => t.type === 'income')
      .reduce((sum: number, t: any) => sum + Number(t.amount), 0);

    const expense = transactions
      .filter((t: any) => t.type === 'expense')
      .reduce((sum: number, t: any) => sum + Number(t.amount), 0);

    // Category breakdown
    const categoryMap = new Map<number, any>();
    transactions
      .filter((t: any) => t.type === 'expense' && t.category)
      .forEach((t: any) => {
        const catId = t.categoryId;
        if (!categoryMap.has(catId)) {
          categoryMap.set(catId, {
            categoryId: catId,
            categoryName: t.category.name,
            color: t.category.color,
            amount: 0,
          });
        }
        categoryMap.get(catId).amount += Number(t.amount);
      });

    const categoryBreakdown = Array.from(categoryMap.values()).map((cat) => ({
      ...cat,
      percentage: expense > 0 ? (cat.amount / expense) * 100 : 0,
    }));

    return {
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
      savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0,
      categoryBreakdown,
    };
  }

  async getCategoryBreakdown(userId: string, from: Date, to: Date) {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: from, lte: to },
      },
      include: { category: true },
    });

    const categoryMap = new Map<number, any>();
    transactions.forEach((t: any) => {
      if (!t.category) return;
      const catId = t.categoryId;
      if (!categoryMap.has(catId)) {
        categoryMap.set(catId, {
          categoryId: catId,
          categoryName: t.category.name,
          icon: t.category.icon,
          color: t.category.color,
          amount: 0,
          count: 0,
        });
      }
      const cat = categoryMap.get(catId);
      cat.amount += Number(t.amount);
      cat.count += 1;
    });

    const total = Array.from(categoryMap.values()).reduce(
      (sum, cat) => sum + cat.amount,
      0
    );

    return Array.from(categoryMap.values())
      .map((cat) => ({
        ...cat,
        percentage: total > 0 ? (cat.amount / total) * 100 : 0,
      }))
      .sort((a, b) => b.amount - a.amount);
  }

  /**
   * Get merchant breakdown for spending analysis
   * Validates: Requirements 21.1
   */
  async getMerchantBreakdown(userId: string, from: Date, to: Date) {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: from, lte: to },
      },
      include: { category: true },
    });

    // Aggregate transactions by merchant
    const merchantMap = new Map<string, any>();
    
    transactions.forEach((t: any) => {
      const merchantName = MerchantExtractor.extractMerchant(
        t.normalizedDescription || t.rawDescription || ''
      );
      
      if (!merchantName) return;

      if (!merchantMap.has(merchantName)) {
        merchantMap.set(merchantName, {
          merchantName,
          totalSpent: 0,
          transactionCount: 0,
          category: t.category?.name || 'Uncategorized',
          categoryId: t.categoryId,
        });
      }

      const merchant = merchantMap.get(merchantName);
      merchant.totalSpent += Number(t.amount);
      merchant.transactionCount += 1;
    });

    // Calculate total spending for percentage
    const totalSpending = Array.from(merchantMap.values()).reduce(
      (sum, m) => sum + m.totalSpent,
      0
    );

    // Sort by total spent descending and add calculated fields
    return Array.from(merchantMap.values())
      .map((merchant) => ({
        ...merchant,
        averageAmount: merchant.totalSpent / merchant.transactionCount,
        percentage: totalSpending > 0 ? (merchant.totalSpent / totalSpending) * 100 : 0,
      }))
      .sort((a, b) => b.totalSpent - a.totalSpent);
  }

  /**
   * Compare spending between two months
   * Validates: Requirements 21.2
   */
  async compareMonths(
    userId: string,
    month1: number,
    year1: number,
    month2: number,
    year2: number
  ) {
    // Get date ranges for both months
    const month1Start = new Date(year1, month1 - 1, 1);
    const month1End = new Date(year1, month1, 0, 23, 59, 59);
    const month2Start = new Date(year2, month2 - 1, 1);
    const month2End = new Date(year2, month2, 0, 23, 59, 59);

    // Get category breakdown for both months
    const month1Data = await this.getCategoryBreakdown(userId, month1Start, month1End);
    const month2Data = await this.getCategoryBreakdown(userId, month2Start, month2End);

    // Calculate totals
    const month1Total = month1Data.reduce((sum, cat) => sum + cat.amount, 0);
    const month2Total = month2Data.reduce((sum, cat) => sum + cat.amount, 0);

    // Create category comparison map
    const categoryChanges = new Map<number, any>();

    // Process month1 categories
    month1Data.forEach((cat) => {
      categoryChanges.set(cat.categoryId, {
        categoryId: cat.categoryId,
        categoryName: cat.categoryName,
        month1Amount: cat.amount,
        month2Amount: 0,
      });
    });

    // Process month2 categories
    month2Data.forEach((cat) => {
      if (categoryChanges.has(cat.categoryId)) {
        categoryChanges.get(cat.categoryId).month2Amount = cat.amount;
      } else {
        categoryChanges.set(cat.categoryId, {
          categoryId: cat.categoryId,
          categoryName: cat.categoryName,
          month1Amount: 0,
          month2Amount: cat.amount,
        });
      }
    });

    // Calculate changes and trends
    const changes = Array.from(categoryChanges.values()).map((cat) => {
      const difference = cat.month2Amount - cat.month1Amount;
      const percentageChange =
        cat.month1Amount > 0 ? (difference / cat.month1Amount) * 100 : 0;

      let trend: 'increase' | 'decrease' | 'stable';
      if (Math.abs(percentageChange) < 5) {
        trend = 'stable';
      } else if (difference > 0) {
        trend = 'increase';
      } else {
        trend = 'decrease';
      }

      return {
        categoryId: cat.categoryId,
        categoryName: cat.categoryName,
        difference,
        percentageChange,
        trend,
      };
    });

    return {
      month1: {
        month: month1,
        year: year1,
        totalSpent: month1Total,
        categoryBreakdown: month1Data,
      },
      month2: {
        month: month2,
        year: year2,
        totalSpent: month2Total,
        categoryBreakdown: month2Data,
      },
      changes: changes.sort((a, b) => Math.abs(b.difference) - Math.abs(a.difference)),
    };
  }

  /**
   * Compare spending between two years
   * Validates: Requirements 21.3
   */
  async compareYears(userId: string, year1: number, year2: number) {
    // Get all transactions for both years
    const year1Start = new Date(year1, 0, 1);
    const year1End = new Date(year1, 11, 31, 23, 59, 59);
    const year2Start = new Date(year2, 0, 1);
    const year2End = new Date(year2, 11, 31, 23, 59, 59);

    const year1Transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: year1Start, lte: year1End },
      },
      include: { category: true },
    });

    const year2Transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: year2Start, lte: year2End },
      },
      include: { category: true },
    });

    // Calculate monthly breakdown for year1
    const year1Monthly = this.calculateMonthlyBreakdown(year1Transactions, year1);
    const year2Monthly = this.calculateMonthlyBreakdown(year2Transactions, year2);

    // Calculate totals
    const year1Total = year1Transactions.reduce(
      (sum, t) => sum + Number(t.amount),
      0
    );
    const year2Total = year2Transactions.reduce(
      (sum, t) => sum + Number(t.amount),
      0
    );

    // Calculate category trends
    const categoryTrends = this.calculateCategoryTrends(
      year1Transactions,
      year2Transactions
    );

    return {
      year1: {
        year: year1,
        totalSpent: year1Total,
        monthlyBreakdown: year1Monthly,
      },
      year2: {
        year: year2,
        totalSpent: year2Total,
        monthlyBreakdown: year2Monthly,
      },
      annualChange: {
        difference: year2Total - year1Total,
        percentageChange:
          year1Total > 0 ? ((year2Total - year1Total) / year1Total) * 100 : 0,
      },
      categoryTrends,
    };
  }

  /**
   * Compare spending between two custom date ranges
   * Validates: Requirements 21.4
   */
  async compareCustomRanges(
    userId: string,
    range1Start: Date,
    range1End: Date,
    range2Start: Date,
    range2End: Date
  ) {
    // Validate date ranges
    if (range1Start >= range1End) {
      throw new Error('Range 1: start date must be before end date');
    }
    if (range2Start >= range2End) {
      throw new Error('Range 2: start date must be before end date');
    }

    // Get category breakdown for both ranges
    const range1Data = await this.getCategoryBreakdown(userId, range1Start, range1End);
    const range2Data = await this.getCategoryBreakdown(userId, range2Start, range2End);

    // Calculate totals
    const range1Total = range1Data.reduce((sum, cat) => sum + cat.amount, 0);
    const range2Total = range2Data.reduce((sum, cat) => sum + cat.amount, 0);

    // Create category comparison map
    const categoryChanges = new Map<number, any>();

    // Process range1 categories
    range1Data.forEach((cat) => {
      categoryChanges.set(cat.categoryId, {
        categoryId: cat.categoryId,
        categoryName: cat.categoryName,
        range1Amount: cat.amount,
        range2Amount: 0,
      });
    });

    // Process range2 categories
    range2Data.forEach((cat) => {
      if (categoryChanges.has(cat.categoryId)) {
        categoryChanges.get(cat.categoryId).range2Amount = cat.amount;
      } else {
        categoryChanges.set(cat.categoryId, {
          categoryId: cat.categoryId,
          categoryName: cat.categoryName,
          range1Amount: 0,
          range2Amount: cat.amount,
        });
      }
    });

    // Calculate changes
    const changes = Array.from(categoryChanges.values()).map((cat) => {
      const difference = cat.range2Amount - cat.range1Amount;
      const percentageChange =
        cat.range1Amount > 0 ? (difference / cat.range1Amount) * 100 : 0;

      return {
        categoryId: cat.categoryId,
        categoryName: cat.categoryName,
        difference,
        percentageChange,
      };
    });

    return {
      range1: {
        start: range1Start,
        end: range1End,
        totalSpent: range1Total,
        categoryBreakdown: range1Data,
      },
      range2: {
        start: range2Start,
        end: range2End,
        totalSpent: range2Total,
        categoryBreakdown: range2Data,
      },
      changes: changes.sort((a, b) => Math.abs(b.difference) - Math.abs(a.difference)),
      overallChange: {
        difference: range2Total - range1Total,
        percentageChange:
          range1Total > 0 ? ((range2Total - range1Total) / range1Total) * 100 : 0,
      },
    };
  }

  /**
   * Helper: Calculate monthly breakdown from transactions
   */
  private calculateMonthlyBreakdown(transactions: any[], year: number) {
    const monthlyMap = new Map<number, number>();

    // Initialize all months
    for (let month = 1; month <= 12; month++) {
      monthlyMap.set(month, 0);
    }

    // Aggregate by month
    transactions.forEach((t) => {
      const month = new Date(t.postedAt).getMonth() + 1;
      monthlyMap.set(month, monthlyMap.get(month)! + Number(t.amount));
    });

    return Array.from(monthlyMap.entries()).map(([month, amount]) => ({
      month,
      year,
      amount,
    }));
  }

  /**
   * Helper: Calculate category trends between two years
   */
  private calculateCategoryTrends(year1Transactions: any[], year2Transactions: any[]) {
    const categoryMap = new Map<number, any>();

    // Process year1 transactions
    year1Transactions.forEach((t) => {
      if (!t.category) return;
      const catId = t.categoryId;
      if (!categoryMap.has(catId)) {
        categoryMap.set(catId, {
          categoryId: catId,
          categoryName: t.category.name,
          year1Total: 0,
          year2Total: 0,
        });
      }
      categoryMap.get(catId).year1Total += Number(t.amount);
    });

    // Process year2 transactions
    year2Transactions.forEach((t) => {
      if (!t.category) return;
      const catId = t.categoryId;
      if (!categoryMap.has(catId)) {
        categoryMap.set(catId, {
          categoryId: catId,
          categoryName: t.category.name,
          year1Total: 0,
          year2Total: 0,
        });
      }
      categoryMap.get(catId).year2Total += Number(t.amount);
    });

    return Array.from(categoryMap.values())
      .map((cat) => ({
        categoryId: cat.categoryId,
        categoryName: cat.categoryName,
        year1Total: cat.year1Total,
        year2Total: cat.year2Total,
        change: cat.year2Total - cat.year1Total,
        percentageChange:
          cat.year1Total > 0
            ? ((cat.year2Total - cat.year1Total) / cat.year1Total) * 100
            : 0,
      }))
      .sort((a, b) => Math.abs(b.change) - Math.abs(a.change));
  }
}
