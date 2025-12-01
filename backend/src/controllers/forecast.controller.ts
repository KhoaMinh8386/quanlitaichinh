import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middlewares/auth';
import { ForecastService } from '../services/forecast.service';

const forecastService = new ForecastService();

export class ForecastController {
  /**
   * Get financial forecast for next month
   */
  async getNextMonthForecast(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;

      const forecast = await forecastService.generateForecast(userId);

      res.status(200).json(forecast);
    } catch (error) {
      next(error);
    }
  }
}
