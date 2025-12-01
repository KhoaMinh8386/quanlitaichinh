import { Router } from 'express';
import { AlertController } from '../controllers/alert.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();
const controller = new AlertController();

// All routes require authentication
router.use(authenticate);

// Get all alerts (with optional unreadOnly filter)
router.get('/', controller.getAlerts.bind(controller));

// Get unread count
router.get('/unread-count', controller.getUnreadCount.bind(controller));

// Mark alert as read
router.patch('/:alertId/read', controller.markAsRead.bind(controller));

// Mark all alerts as read
router.patch('/read-all', controller.markAllAsRead.bind(controller));

// Delete alert
router.delete('/:alertId', controller.deleteAlert.bind(controller));

// Check budgets and create alerts
router.post('/check-budgets', controller.checkBudgets.bind(controller));

export default router;
