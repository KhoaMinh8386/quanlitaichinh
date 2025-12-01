import { Router } from 'express';
import { ForecastController } from '../controllers/forecast.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();
const controller = new ForecastController();

// All routes require authentication
router.use(authenticate);

// Get next month forecast
router.get('/next-month', controller.getNextMonthForecast.bind(controller));

export default router;
