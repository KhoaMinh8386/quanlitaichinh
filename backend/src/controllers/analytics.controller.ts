import { Request, Response, NextFunction } from 'express';
import { AnalyticsService } from '../services/analytics.service';
import { ValidationError } from '../middlewares/errorHandler';

const analyticsService = new AnalyticsService();

export class AnalyticsController {
  /**
   * Get spending summary
   * GET /api/analytics/summary?from=YYYY-MM-DD&to=YYYY-MM-DD
   */
  async getSummary(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { from, to } = req.query;

      // Default to current month if no dates provided
      let fromDate: Date;
      let toDate: Date;

      if (from && to) {
        fromDate = new Date(from as string);
        toDate = new Date(to as string);
        toDate.setHours(23, 59, 59, 999);
      } else {
        const now = new Date();
        fromDate = new Date(now.getFullYear(), now.getMonth(), 1);
        toDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      }

      if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        throw new ValidationError('Invalid date format. Use YYYY-MM-DD');
      }

      const summary = await analyticsService.getSummary(userId, fromDate, toDate);

      res.json({
        success: true,
        data: summary,
        period: {
          from: fromDate.toISOString(),
          to: toDate.toISOString(),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get time series data
   * GET /api/analytics/timeseries?groupBy=day|month|year&from=YYYY-MM-DD&to=YYYY-MM-DD
   */
  async getTimeSeries(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { from, to, groupBy } = req.query;

      // Default to last 6 months
      let fromDate: Date;
      let toDate: Date;

      if (from && to) {
        fromDate = new Date(from as string);
        toDate = new Date(to as string);
        toDate.setHours(23, 59, 59, 999);
      } else {
        const now = new Date();
        toDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
        fromDate = new Date(now.getFullYear(), now.getMonth() - 5, 1);
      }

      if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        throw new ValidationError('Invalid date format. Use YYYY-MM-DD');
      }

      const validGroupBy = ['day', 'month', 'year'];
      const group = validGroupBy.includes(groupBy as string) 
        ? (groupBy as 'day' | 'month' | 'year') 
        : 'month';

      const timeSeries = await analyticsService.getTimeSeries(userId, fromDate, toDate, group);

      res.json({
        success: true,
        data: timeSeries,
        groupBy: group,
        period: {
          from: fromDate.toISOString(),
          to: toDate.toISOString(),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get category trends
   * GET /api/analytics/category-trends/:categoryId?months=6
   */
  async getCategoryTrends(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { categoryId } = req.params;
      const { months } = req.query;

      const numCategoryId = parseInt(categoryId, 10);
      if (isNaN(numCategoryId)) {
        throw new ValidationError('Invalid category ID');
      }

      const numMonths = months ? parseInt(months as string, 10) : 6;

      const trends = await analyticsService.getCategoryTrends(
        userId,
        numCategoryId,
        numMonths
      );

      res.json({
        success: true,
        data: trends,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get spending forecast
   * GET /api/analytics/forecast
   */
  async getForecast(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;

      const forecast = await analyticsService.getSpendingForecast(userId);

      res.json({
        success: true,
        data: forecast,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get top spending categories
   * GET /api/analytics/top-categories?limit=5
   */
  async getTopCategories(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { limit } = req.query;

      const numLimit = limit ? parseInt(limit as string, 10) : 5;

      const categories = await analyticsService.getTopCategories(userId, numLimit);

      res.json({
        success: true,
        data: categories,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get period comparison
   * GET /api/analytics/comparison?from=YYYY-MM-DD&to=YYYY-MM-DD
   */
  async getPeriodComparison(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { from, to } = req.query;

      // Default to current month vs previous month
      let fromDate: Date;
      let toDate: Date;

      if (from && to) {
        fromDate = new Date(from as string);
        toDate = new Date(to as string);
        toDate.setHours(23, 59, 59, 999);
      } else {
        const now = new Date();
        fromDate = new Date(now.getFullYear(), now.getMonth(), 1);
        toDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      }

      if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
        throw new ValidationError('Invalid date format. Use YYYY-MM-DD');
      }

      const comparison = await analyticsService.getPeriodComparison(
        userId,
        fromDate,
        toDate
      );

      res.json({
        success: true,
        data: comparison,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const analyticsController = new AnalyticsController();

