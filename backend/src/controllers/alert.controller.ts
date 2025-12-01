import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middlewares/auth';
import { AlertService } from '../services/alert.service';

const alertService = new AlertService();

export class AlertController {
  /**
   * Get all alerts for current user
   */
  async getAlerts(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const unreadOnly = req.query.unreadOnly === 'true';

      const alerts = await alertService.getUserAlerts(userId, unreadOnly);

      res.status(200).json({ alerts });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get unread alert count
   */
  async getUnreadCount(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;

      const count = await alertService.getUnreadCount(userId);

      res.status(200).json({ count });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mark alert as read
   */
  async markAsRead(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { alertId } = req.params;
      const userId = req.userId!;

      await alertService.markAsRead(alertId, userId);

      res.status(200).json({ message: 'Alert marked as read' });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mark all alerts as read
   */
  async markAllAsRead(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;

      const count = await alertService.markAllAsRead(userId);

      res.status(200).json({
        message: 'All alerts marked as read',
        count,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete an alert
   */
  async deleteAlert(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { alertId } = req.params;
      const userId = req.userId!;

      await alertService.deleteAlert(alertId, userId);

      res.status(200).json({ message: 'Alert deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check budgets and create alerts
   */
  async checkBudgets(
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.userId!;
      const now = new Date();
      const month = req.query.month ? parseInt(req.query.month as string) : now.getMonth() + 1;
      const year = req.query.year ? parseInt(req.query.year as string) : now.getFullYear();

      await alertService.checkBudgetsAndCreateAlerts(userId, month, year);

      res.status(200).json({ message: 'Budget check completed' });
    } catch (error) {
      next(error);
    }
  }
}
