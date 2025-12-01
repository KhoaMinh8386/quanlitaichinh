import { Router } from 'express';
import { ReportService } from '../services/report.service';
import { authenticate, AuthRequest } from '../middlewares/auth';

const router = Router();
const reportService = new ReportService();

router.use(authenticate);

router.get('/overview', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { from, to } = req.query;
    const overview = await reportService.getOverview(
      userId,
      new Date(from as string),
      new Date(to as string)
    );
    res.status(200).json(overview);
  } catch (error) {
    next(error);
  }
});

router.get('/category-breakdown', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { from, to } = req.query;
    const breakdown = await reportService.getCategoryBreakdown(
      userId,
      new Date(from as string),
      new Date(to as string)
    );
    res.status(200).json(breakdown);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/reports/merchants
 * Get merchant breakdown for spending analysis
 * Validates: Requirements 21.1
 */
router.get('/merchants', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { from, to } = req.query;
    
    if (!from || !to) {
      return res.status(400).json({ error: 'from and to date parameters are required' });
    }

    const merchants = await reportService.getMerchantBreakdown(
      userId,
      new Date(from as string),
      new Date(to as string)
    );
    return res.status(200).json(merchants);
  } catch (error) {
    return next(error);
  }
});

/**
 * GET /api/reports/compare-months
 * Compare spending between two months
 * Validates: Requirements 21.2, 21.5
 */
router.get('/compare-months', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { month1, year1, month2, year2 } = req.query;
    
    if (!month1 || !year1 || !month2 || !year2) {
      return res.status(400).json({ 
        error: 'month1, year1, month2, and year2 parameters are required' 
      });
    }

    const comparison = await reportService.compareMonths(
      userId,
      parseInt(month1 as string),
      parseInt(year1 as string),
      parseInt(month2 as string),
      parseInt(year2 as string)
    );
    return res.status(200).json(comparison);
  } catch (error) {
    return next(error);
  }
});

/**
 * GET /api/reports/compare-years
 * Compare spending between two years
 * Validates: Requirements 21.3
 */
router.get('/compare-years', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { year1, year2 } = req.query;
    
    if (!year1 || !year2) {
      return res.status(400).json({ 
        error: 'year1 and year2 parameters are required' 
      });
    }

    const comparison = await reportService.compareYears(
      userId,
      parseInt(year1 as string),
      parseInt(year2 as string)
    );
    return res.status(200).json(comparison);
  } catch (error) {
    return next(error);
  }
});

/**
 * POST /api/reports/compare-ranges
 * Compare spending between two custom date ranges
 * Validates: Requirements 21.4
 */
router.post('/compare-ranges', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { range1Start, range1End, range2Start, range2End } = req.body;
    
    if (!range1Start || !range1End || !range2Start || !range2End) {
      return res.status(400).json({ 
        error: 'range1Start, range1End, range2Start, and range2End are required' 
      });
    }

    const comparison = await reportService.compareCustomRanges(
      userId,
      new Date(range1Start),
      new Date(range1End),
      new Date(range2Start),
      new Date(range2End)
    );
    return res.status(200).json(comparison);
  } catch (error) {
    return next(error);
  }
});

export default router;
