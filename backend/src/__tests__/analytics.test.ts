import { AnalyticsService } from '../services/analytics.service';

// Mock PrismaClient
jest.mock('@prisma/client', () => {
  const mockTransactions = [
    {
      id: '1',
      userId: 'user-1',
      amount: 100000,
      type: 'expense',
      postedAt: new Date('2025-01-15'),
      categoryId: 1,
      category: { id: 1, name: 'Food', icon: 'restaurant', color: '#FF5722' },
    },
    {
      id: '2',
      userId: 'user-1',
      amount: 50000,
      type: 'expense',
      postedAt: new Date('2025-01-16'),
      categoryId: 1,
      category: { id: 1, name: 'Food', icon: 'restaurant', color: '#FF5722' },
    },
    {
      id: '3',
      userId: 'user-1',
      amount: 200000,
      type: 'expense',
      postedAt: new Date('2025-01-17'),
      categoryId: 2,
      category: { id: 2, name: 'Transport', icon: 'directions_car', color: '#2196F3' },
    },
    {
      id: '4',
      userId: 'user-1',
      amount: 5000000,
      type: 'income',
      postedAt: new Date('2025-01-10'),
      categoryId: null,
      category: null,
    },
  ];

  const mockPrisma = {
    transaction: {
      findMany: jest.fn().mockResolvedValue(mockTransactions),
      aggregate: jest.fn().mockResolvedValue({
        _sum: { amount: 350000 },
        _avg: { amount: 116667 },
        _count: 3,
      }),
    },
    category: {
      findUnique: jest.fn().mockResolvedValue({
        id: 1,
        name: 'Food',
      }),
    },
  };
  return { PrismaClient: jest.fn(() => mockPrisma) };
});

describe('AnalyticsService', () => {
  let service: AnalyticsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AnalyticsService();
  });

  describe('getSummary', () => {
    it('should return correct summary structure', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const summary = await service.getSummary(userId, from, to);

      expect(summary).toHaveProperty('totalIncome');
      expect(summary).toHaveProperty('totalExpense');
      expect(summary).toHaveProperty('netSavings');
      expect(summary).toHaveProperty('savingsRate');
      expect(summary).toHaveProperty('transactionCount');
      expect(summary).toHaveProperty('categoryBreakdown');
    });

    it('should calculate correct totals', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const summary = await service.getSummary(userId, from, to);

      // Based on mock data: 1 income (5M), 3 expenses (100k + 50k + 200k = 350k)
      expect(summary.totalIncome).toBe(5000000);
      expect(summary.totalExpense).toBe(350000);
      expect(summary.netSavings).toBe(4650000);
      expect(summary.transactionCount).toBe(4);
    });

    it('should calculate savings rate correctly', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const summary = await service.getSummary(userId, from, to);

      // Savings rate = (income - expense) / income * 100
      // = (5000000 - 350000) / 5000000 * 100 = 93%
      expect(summary.savingsRate).toBeCloseTo(93, 0);
    });

    it('should group expenses by category', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const summary = await service.getSummary(userId, from, to);

      // Should have 2 categories: Food (150000) and Transport (200000)
      expect(summary.categoryBreakdown.length).toBe(2);
      
      const foodCategory = summary.categoryBreakdown.find(c => c.categoryName === 'Food');
      const transportCategory = summary.categoryBreakdown.find(c => c.categoryName === 'Transport');

      expect(foodCategory?.total).toBe(150000);
      expect(foodCategory?.count).toBe(2);
      expect(transportCategory?.total).toBe(200000);
      expect(transportCategory?.count).toBe(1);
    });

    it('should calculate category percentages correctly', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const summary = await service.getSummary(userId, from, to);

      const totalExpense = 350000;
      const foodPercentage = (150000 / totalExpense) * 100;
      const transportPercentage = (200000 / totalExpense) * 100;

      const foodCategory = summary.categoryBreakdown.find(c => c.categoryName === 'Food');
      const transportCategory = summary.categoryBreakdown.find(c => c.categoryName === 'Transport');

      expect(foodCategory?.percentage).toBeCloseTo(foodPercentage, 1);
      expect(transportCategory?.percentage).toBeCloseTo(transportPercentage, 1);
    });
  });

  describe('getTimeSeries', () => {
    it('should return time series data structure', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const timeSeries = await service.getTimeSeries(userId, from, to, 'day');

      expect(Array.isArray(timeSeries)).toBe(true);
      if (timeSeries.length > 0) {
        expect(timeSeries[0]).toHaveProperty('label');
        expect(timeSeries[0]).toHaveProperty('totalExpense');
        expect(timeSeries[0]).toHaveProperty('totalIncome');
        expect(timeSeries[0]).toHaveProperty('netSavings');
      }
    });

    it('should group by day correctly', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-01-31');

      const timeSeries = await service.getTimeSeries(userId, from, to, 'day');

      // Should have entries for each day with transactions
      timeSeries.forEach(entry => {
        expect(entry.label).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      });
    });

    it('should group by month correctly', async () => {
      const userId = 'user-1';
      const from = new Date('2025-01-01');
      const to = new Date('2025-12-31');

      const timeSeries = await service.getTimeSeries(userId, from, to, 'month');

      // All mock transactions are in January
      timeSeries.forEach(entry => {
        expect(entry.label).toMatch(/^\d{4}-\d{2}$/);
      });
    });
  });

  describe('Spending Forecast', () => {
    it('should return forecast structure', async () => {
      const userId = 'user-1';

      const forecast = await service.getSpendingForecast(userId);

      expect(forecast).toHaveProperty('expectedTotalExpenseNextMonth');
      expect(forecast).toHaveProperty('expectedByCategory');
      expect(forecast).toHaveProperty('confidence');
      expect(forecast).toHaveProperty('basedOnMonths');
    });

    it('should include category forecasts', async () => {
      const userId = 'user-1';

      const forecast = await service.getSpendingForecast(userId);

      expect(Array.isArray(forecast.expectedByCategory)).toBe(true);
      forecast.expectedByCategory.forEach(cat => {
        expect(cat).toHaveProperty('categoryId');
        expect(cat).toHaveProperty('categoryName');
        expect(cat).toHaveProperty('expectedAmount');
        expect(cat).toHaveProperty('averageAmount');
        expect(cat).toHaveProperty('trend');
        expect(['increasing', 'decreasing', 'stable']).toContain(cat.trend);
      });
    });
  });
});

describe('Analytics Calculations', () => {
  it('should handle zero income correctly', () => {
    const income = 0;
    const expense = 100000;
    const savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;
    
    expect(savingsRate).toBe(0);
  });

  it('should handle zero expense correctly', () => {
    const income = 5000000;
    const expense = 0;
    const savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;
    
    expect(savingsRate).toBe(100);
  });

  it('should handle negative savings correctly', () => {
    const income = 1000000;
    const expense = 1500000;
    const savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;
    
    expect(savingsRate).toBe(-50);
  });
});

