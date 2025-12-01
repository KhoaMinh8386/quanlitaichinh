import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface MonthlyData {
  month: number;
  year: number;
  income: number;
  expense: number;
  savings: number;
}

export interface HistoricalAverage {
  income: number;
  expense: number;
  savings: number;
  savingsRate: number;
}

export interface MonthlyPrediction {
  month: number;
  year: number;
  predictedIncome: number;
  predictedExpense: number;
  predictedSavings: number;
}

export interface ForecastResult {
  hasEnoughData: boolean;
  warningMessage?: string;
  historicalData?: {
    months: MonthlyData[];
    averages: HistoricalAverage;
  };
  prediction?: MonthlyPrediction;
  recommendations: string[];
  chartData?: {
    historical: Array<{ x: string; y: number }>;
    predicted: Array<{ x: string; y: number }>;
  };
}

export class ForecastService {
  private readonly MIN_MONTHS_REQUIRED = 3;
  private readonly ANALYSIS_MONTHS = 6;

  /**
   * Generate financial forecast for next month
   * Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5
   */
  async generateForecast(userId: string): Promise<ForecastResult> {
    // Get historical data
    const historicalData = await this.getHistoricalData(userId, this.ANALYSIS_MONTHS);

    // Check if we have enough data
    if (historicalData.length < this.MIN_MONTHS_REQUIRED) {
      return {
        hasEnoughData: false,
        warningMessage: `Insufficient data for forecast. Need at least ${this.MIN_MONTHS_REQUIRED} months of transaction history. Currently have ${historicalData.length} months.`,
        recommendations: [
          'Continue tracking your transactions for more accurate predictions',
          'Connect your bank accounts to automatically sync transactions',
        ],
      };
    }

    // Calculate averages
    const averages = this.calculateAverages(historicalData);

    // Generate prediction for next month
    const prediction = this.predictNextMonth(historicalData, averages);

    // Generate recommendations
    const recommendations = this.generateRecommendations(averages, historicalData);

    // Format chart data
    const chartData = this.formatChartData(historicalData, prediction);

    return {
      hasEnoughData: true,
      historicalData: {
        months: historicalData,
        averages,
      },
      prediction,
      recommendations,
      chartData,
    };
  }

  /**
   * Get historical monthly data
   */
  private async getHistoricalData(
    userId: string,
    months: number
  ): Promise<MonthlyData[]> {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth() - months, 1);

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        postedAt: {
          gte: startDate,
        },
      },
      orderBy: {
        postedAt: 'asc',
      },
    });

    // Group by month
    const monthlyMap = new Map<string, MonthlyData>();

    transactions.forEach((txn) => {
      const date = new Date(txn.postedAt);
      const key = `${date.getFullYear()}-${date.getMonth() + 1}`;

      if (!monthlyMap.has(key)) {
        monthlyMap.set(key, {
          month: date.getMonth() + 1,
          year: date.getFullYear(),
          income: 0,
          expense: 0,
          savings: 0,
        });
      }

      const monthData = monthlyMap.get(key)!;
      const amount = Number(txn.amount);

      if (txn.type === 'income') {
        monthData.income += amount;
      } else {
        monthData.expense += amount;
      }
    });

    // Calculate savings for each month
    const result = Array.from(monthlyMap.values()).map((data) => ({
      ...data,
      savings: data.income - data.expense,
    }));

    return result.sort((a, b) => {
      if (a.year !== b.year) return a.year - b.year;
      return a.month - b.month;
    });
  }

  /**
   * Calculate historical averages
   * Validates: Requirements 9.3
   */
  private calculateAverages(data: MonthlyData[]): HistoricalAverage {
    if (data.length === 0) {
      return {
        income: 0,
        expense: 0,
        savings: 0,
        savingsRate: 0,
      };
    }

    const totalIncome = data.reduce((sum, d) => sum + d.income, 0);
    const totalExpense = data.reduce((sum, d) => sum + d.expense, 0);
    const totalSavings = data.reduce((sum, d) => sum + d.savings, 0);

    const avgIncome = totalIncome / data.length;
    const avgExpense = totalExpense / data.length;
    const avgSavings = totalSavings / data.length;
    const savingsRate = avgIncome > 0 ? (avgSavings / avgIncome) * 100 : 0;

    return {
      income: avgIncome,
      expense: avgExpense,
      savings: avgSavings,
      savingsRate,
    };
  }

  /**
   * Predict next month values
   * Validates: Requirements 9.4
   */
  private predictNextMonth(
    historicalData: MonthlyData[],
    averages: HistoricalAverage
  ): MonthlyPrediction {
    const now = new Date();
    const nextMonth = now.getMonth() + 2; // +1 for 0-index, +1 for next month
    const nextYear = nextMonth > 12 ? now.getFullYear() + 1 : now.getFullYear();
    const adjustedMonth = nextMonth > 12 ? 1 : nextMonth;

    // Simple trend analysis: compare recent 3 months vs older data
    const recentData = historicalData.slice(-3);
    const olderData = historicalData.slice(0, -3);

    let incomeAdjustment = 1.0;
    let expenseAdjustment = 1.0;

    if (olderData.length > 0 && recentData.length > 0) {
      const recentAvgIncome =
        recentData.reduce((sum, d) => sum + d.income, 0) / recentData.length;
      const olderAvgIncome =
        olderData.reduce((sum, d) => sum + d.income, 0) / olderData.length;

      const recentAvgExpense =
        recentData.reduce((sum, d) => sum + d.expense, 0) / recentData.length;
      const olderAvgExpense =
        olderData.reduce((sum, d) => sum + d.expense, 0) / olderData.length;

      if (olderAvgIncome > 0) {
        incomeAdjustment = recentAvgIncome / olderAvgIncome;
      }
      if (olderAvgExpense > 0) {
        expenseAdjustment = recentAvgExpense / olderAvgExpense;
      }

      // Limit adjustments to reasonable range
      incomeAdjustment = Math.max(0.8, Math.min(1.2, incomeAdjustment));
      expenseAdjustment = Math.max(0.8, Math.min(1.2, expenseAdjustment));
    }

    const predictedIncome = averages.income * incomeAdjustment;
    const predictedExpense = averages.expense * expenseAdjustment;
    const predictedSavings = predictedIncome - predictedExpense;

    return {
      month: adjustedMonth,
      year: nextYear,
      predictedIncome,
      predictedExpense,
      predictedSavings,
    };
  }

  /**
   * Generate actionable recommendations
   * Validates: Requirements 9.5
   */
  private generateRecommendations(
    averages: HistoricalAverage,
    historicalData: MonthlyData[]
  ): string[] {
    const recommendations: string[] = [];

    // Savings rate recommendations
    if (averages.savingsRate < 10) {
      recommendations.push(
        'Your savings rate is below 10%. Try to reduce expenses or increase income to save more.'
      );
    } else if (averages.savingsRate < 20) {
      recommendations.push(
        'Good start! Aim to increase your savings rate to 20% or more for better financial health.'
      );
    } else {
      recommendations.push(
        `Excellent! You're saving ${averages.savingsRate.toFixed(1)}% of your income. Keep it up!`
      );
    }

    // Expense trend recommendations
    if (historicalData.length >= 3) {
      const recentExpenses = historicalData.slice(-3).map((d) => d.expense);
      const avgRecentExpense =
        recentExpenses.reduce((a, b) => a + b, 0) / recentExpenses.length;

      if (avgRecentExpense > averages.expense * 1.1) {
        recommendations.push(
          'Your expenses have been increasing recently. Review your spending categories to identify areas to cut back.'
        );
      }
    }

    // Income stability recommendations
    const incomeVariance = this.calculateVariance(
      historicalData.map((d) => d.income)
    );
    const incomeStdDev = Math.sqrt(incomeVariance);

    if (incomeStdDev > averages.income * 0.3) {
      recommendations.push(
        'Your income varies significantly month-to-month. Consider building an emergency fund to handle fluctuations.'
      );
    }

    // Negative savings recommendations
    if (averages.savings < 0) {
      recommendations.push(
        'You are spending more than you earn on average. This is unsustainable. Urgently review and reduce your expenses.'
      );
    }

    // General recommendations
    if (recommendations.length === 0) {
      recommendations.push(
        'Your financial health looks good. Continue monitoring your spending and saving regularly.'
      );
    }

    return recommendations;
  }

  /**
   * Calculate variance for trend analysis
   */
  private calculateVariance(values: number[]): number {
    if (values.length === 0) return 0;

    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const squaredDiffs = values.map((v) => Math.pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b, 0) / values.length;
  }

  /**
   * Format data for chart rendering
   */
  private formatChartData(
    historicalData: MonthlyData[],
    prediction: MonthlyPrediction
  ): { historical: Array<{ x: string; y: number }>; predicted: Array<{ x: string; y: number }> } {
    const historical = historicalData.map((d) => ({
      x: `${d.year}-${d.month.toString().padStart(2, '0')}`,
      y: d.expense,
    }));

    const predicted = [
      {
        x: `${prediction.year}-${prediction.month.toString().padStart(2, '0')}`,
        y: prediction.predictedExpense,
      },
    ];

    return { historical, predicted };
  }
}
