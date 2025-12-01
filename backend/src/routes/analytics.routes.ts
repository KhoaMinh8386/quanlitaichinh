import { Router } from 'express';
import { analyticsController } from '../controllers/analytics.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();

// All analytics routes require authentication
router.use(authenticate);

// Get spending summary
router.get('/summary', (req, res, next) => 
  analyticsController.getSummary(req, res, next)
);

// Get time series data for charts
router.get('/timeseries', (req, res, next) => 
  analyticsController.getTimeSeries(req, res, next)
);

// Get category trends
router.get('/category-trends/:categoryId', (req, res, next) => 
  analyticsController.getCategoryTrends(req, res, next)
);

// Get spending forecast
router.get('/forecast', (req, res, next) => 
  analyticsController.getForecast(req, res, next)
);

// Get top spending categories
router.get('/top-categories', (req, res, next) => 
  analyticsController.getTopCategories(req, res, next)
);

// Get period comparison
router.get('/comparison', (req, res, next) => 
  analyticsController.getPeriodComparison(req, res, next)
);

export default router;

