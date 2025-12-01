import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface SummaryResult {
  totalIncome: number;
  totalExpense: number;
  netSavings: number;
  savingsRate: number;
  transactionCount: number;
  categoryBreakdown: Array<{
    categoryId: number;
    categoryName: string;
    icon: string | null;
    color: string | null;
    total: number;
    percentage: number;
    count: number;
  }>;
}

export interface TimeSeriesData {
  label: string;
  totalExpense: number;
  totalIncome: number;
  netSavings: number;
}

export interface CategoryForecast {
  categoryId: number;
  categoryName: string;
  expectedAmount: number;
  averageAmount: number;
  trend: 'increasing' | 'decreasing' | 'stable';
}

export class AnalyticsService {
  /**
   * Get spending summary for a date range
   * GET /api/analytics/summary
   */
  async getSummary(userId: string, from: Date, to: Date): Promise<SummaryResult> {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        postedAt: { gte: from, lte: to },
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
      },
    });

    const income = transactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const expense = transactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    // Category breakdown for expenses
    const categoryMap = new Map<number, {
      categoryId: number;
      categoryName: string;
      icon: string | null;
      color: string | null;
      total: number;
      count: number;
    }>();

    transactions
      .filter((t) => t.type === 'expense' && t.category)
      .forEach((t) => {
        const catId = t.categoryId!;
        if (!categoryMap.has(catId)) {
          categoryMap.set(catId, {
            categoryId: catId,
            categoryName: t.category!.name,
            icon: t.category!.icon,
            color: t.category!.color,
            total: 0,
            count: 0,
          });
        }
        const cat = categoryMap.get(catId)!;
        cat.total += Number(t.amount);
        cat.count += 1;
      });

    const categoryBreakdown = Array.from(categoryMap.values())
      .map((cat) => ({
        ...cat,
        percentage: expense > 0 ? (cat.total / expense) * 100 : 0,
      }))
      .sort((a, b) => b.total - a.total);

    return {
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
      savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0,
      transactionCount: transactions.length,
      categoryBreakdown,
    };
  }

  /**
   * Get time series data for charts
   * GET /api/analytics/timeseries
   */
  async getTimeSeries(
    userId: string,
    from: Date,
    to: Date,
    groupBy: 'day' | 'month' | 'year' = 'month'
  ): Promise<TimeSeriesData[]> {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        postedAt: { gte: from, lte: to },
      },
      orderBy: { postedAt: 'asc' },
    });

    const groupedData = new Map<string, { income: number; expense: number }>();

    transactions.forEach((t) => {
      const date = new Date(t.postedAt);
      let label: string;

      switch (groupBy) {
        case 'day':
          label = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
          break;
        case 'month':
          label = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
          break;
        case 'year':
          label = `${date.getFullYear()}`;
          break;
      }

      if (!groupedData.has(label)) {
        groupedData.set(label, { income: 0, expense: 0 });
      }

      const data = groupedData.get(label)!;
      if (t.type === 'income') {
        data.income += Number(t.amount);
      } else {
        data.expense += Number(t.amount);
      }
    });

    // Fill in missing dates for continuous chart
    const result: TimeSeriesData[] = [];
    const sortedLabels = Array.from(groupedData.keys()).sort();

    sortedLabels.forEach((label) => {
      const data = groupedData.get(label)!;
      result.push({
        label,
        totalIncome: data.income,
        totalExpense: data.expense,
        netSavings: data.income - data.expense,
      });
    });

    return result;
  }

  /**
   * Get category spending trends
   * GET /api/analytics/category-trends
   */
  async getCategoryTrends(
    userId: string,
    categoryId: number,
    months: number = 6
  ): Promise<{
    categoryName: string;
    monthlyData: Array<{ month: string; amount: number }>;
    averageMonthly: number;
    trend: 'increasing' | 'decreasing' | 'stable';
  }> {
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - months);
    startDate.setDate(1);

    const category = await prisma.category.findUnique({
      where: { id: categoryId },
    });

    if (!category) {
      throw new Error('Category not found');
    }

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        categoryId,
        type: 'expense',
        postedAt: { gte: startDate },
      },
      orderBy: { postedAt: 'asc' },
    });

    // Group by month
    const monthlyMap = new Map<string, number>();

    transactions.forEach((t) => {
      const date = new Date(t.postedAt);
      const label = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      monthlyMap.set(label, (monthlyMap.get(label) || 0) + Number(t.amount));
    });

    const monthlyData = Array.from(monthlyMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => a.month.localeCompare(b.month));

    // Calculate average and trend
    const totalAmount = monthlyData.reduce((sum, m) => sum + m.amount, 0);
    const averageMonthly = monthlyData.length > 0 ? totalAmount / monthlyData.length : 0;

    // Simple trend detection
    let trend: 'increasing' | 'decreasing' | 'stable' = 'stable';
    if (monthlyData.length >= 3) {
      const recentHalf = monthlyData.slice(-Math.ceil(monthlyData.length / 2));
      const olderHalf = monthlyData.slice(0, Math.floor(monthlyData.length / 2));

      const recentAvg = recentHalf.reduce((sum, m) => sum + m.amount, 0) / recentHalf.length;
      const olderAvg = olderHalf.reduce((sum, m) => sum + m.amount, 0) / olderHalf.length;

      const changePercent = olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg) * 100 : 0;

      if (changePercent > 10) {
        trend = 'increasing';
      } else if (changePercent < -10) {
        trend = 'decreasing';
      }
    }

    return {
      categoryName: category.name,
      monthlyData,
      averageMonthly,
      trend,
    };
  }

  /**
   * Get spending forecast by category
   * GET /api/analytics/forecast
   */
  async getSpendingForecast(userId: string): Promise<{
    expectedTotalExpenseNextMonth: number;
    expectedByCategory: CategoryForecast[];
    confidence: number;
    basedOnMonths: number;
  }> {
    // Get last 6 months of data
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    sixMonthsAgo.setDate(1);

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: sixMonthsAgo },
      },
      include: {
        category: true,
      },
    });

    // Group by month and category
    const categoryMonthlyMap = new Map<number, Map<string, number>>();
    const categoryNames = new Map<number, string>();

    transactions.forEach((t) => {
      if (!t.categoryId || !t.category) return;

      if (!categoryMonthlyMap.has(t.categoryId)) {
        categoryMonthlyMap.set(t.categoryId, new Map());
        categoryNames.set(t.categoryId, t.category.name);
      }

      const date = new Date(t.postedAt);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      const monthMap = categoryMonthlyMap.get(t.categoryId)!;
      monthMap.set(monthKey, (monthMap.get(monthKey) || 0) + Number(t.amount));
    });

    // Calculate forecast for each category
    const expectedByCategory: CategoryForecast[] = [];
    let totalExpected = 0;

    categoryMonthlyMap.forEach((monthMap, categoryId) => {
      const values = Array.from(monthMap.values());
      
      if (values.length < 2) return;

      // Simple moving average with trend adjustment
      const average = values.reduce((sum, v) => sum + v, 0) / values.length;
      
      // Check recent trend
      const recentValues = values.slice(-3);
      const recentAvg = recentValues.reduce((sum, v) => sum + v, 0) / recentValues.length;
      
      const trendFactor = average > 0 ? recentAvg / average : 1;
      const adjustedExpected = average * Math.min(Math.max(trendFactor, 0.8), 1.2);

      let trend: 'increasing' | 'decreasing' | 'stable' = 'stable';
      if (trendFactor > 1.1) trend = 'increasing';
      else if (trendFactor < 0.9) trend = 'decreasing';

      expectedByCategory.push({
        categoryId,
        categoryName: categoryNames.get(categoryId) || 'Unknown',
        expectedAmount: Math.round(adjustedExpected),
        averageAmount: Math.round(average),
        trend,
      });

      totalExpected += adjustedExpected;
    });

    // Sort by expected amount
    expectedByCategory.sort((a, b) => b.expectedAmount - a.expectedAmount);

    // Calculate confidence based on data quantity
    const uniqueMonths = new Set<string>();
    transactions.forEach((t) => {
      const date = new Date(t.postedAt);
      uniqueMonths.add(`${date.getFullYear()}-${date.getMonth()}`);
    });

    const monthCount = uniqueMonths.size;
    const confidence = Math.min(monthCount / 6 * 100, 100);

    return {
      expectedTotalExpenseNextMonth: Math.round(totalExpected),
      expectedByCategory,
      confidence: Math.round(confidence),
      basedOnMonths: monthCount,
    };
  }

  /**
   * Get top spending categories for current month
   */
  async getTopCategories(userId: string, limit: number = 5): Promise<Array<{
    categoryId: number;
    categoryName: string;
    icon: string | null;
    color: string | null;
    total: number;
    percentage: number;
  }>> {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const summary = await this.getSummary(userId, monthStart, monthEnd);
    
    return summary.categoryBreakdown.slice(0, limit);
  }

  /**
   * Get spending comparison with previous period
   */
  async getPeriodComparison(
    userId: string,
    currentFrom: Date,
    currentTo: Date
  ): Promise<{
    currentPeriod: { income: number; expense: number; savings: number };
    previousPeriod: { income: number; expense: number; savings: number };
    changes: {
      incomeChange: number;
      expenseChange: number;
      savingsChange: number;
      incomeChangePercent: number;
      expenseChangePercent: number;
      savingsChangePercent: number;
    };
  }> {
    // Calculate previous period dates (same duration before current period)
    const duration = currentTo.getTime() - currentFrom.getTime();
    const previousFrom = new Date(currentFrom.getTime() - duration);
    const previousTo = new Date(currentFrom.getTime() - 1);

    const [currentSummary, previousSummary] = await Promise.all([
      this.getSummary(userId, currentFrom, currentTo),
      this.getSummary(userId, previousFrom, previousTo),
    ]);

    const calculateChangePercent = (current: number, previous: number): number => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return ((current - previous) / previous) * 100;
    };

    return {
      currentPeriod: {
        income: currentSummary.totalIncome,
        expense: currentSummary.totalExpense,
        savings: currentSummary.netSavings,
      },
      previousPeriod: {
        income: previousSummary.totalIncome,
        expense: previousSummary.totalExpense,
        savings: previousSummary.netSavings,
      },
      changes: {
        incomeChange: currentSummary.totalIncome - previousSummary.totalIncome,
        expenseChange: currentSummary.totalExpense - previousSummary.totalExpense,
        savingsChange: currentSummary.netSavings - previousSummary.netSavings,
        incomeChangePercent: calculateChangePercent(
          currentSummary.totalIncome,
          previousSummary.totalIncome
        ),
        expenseChangePercent: calculateChangePercent(
          currentSummary.totalExpense,
          previousSummary.totalExpense
        ),
        savingsChangePercent: calculateChangePercent(
          currentSummary.netSavings,
          previousSummary.netSavings
        ),
      },
    };
  }
}

