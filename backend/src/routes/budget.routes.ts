import { Router } from 'express';
import { BudgetService } from '../services/budget.service';
import { authenticate, AuthRequest } from '../middlewares/auth';

const router = Router();
const budgetService = new BudgetService();

router.use(authenticate);

router.post('/', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { month, year, categoryId, amountLimit } = req.body;
    const budget = await budgetService.createOrUpdateBudget({
      userId,
      month,
      year,
      categoryId,
      amountLimit,
    });
    res.status(200).json(budget);
  } catch (error) {
    next(error);
  }
});

router.get('/summary', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { month, year } = req.query;
    const summary = await budgetService.getBudgetSummary(
      userId,
      parseInt(month as string),
      parseInt(year as string)
    );
    res.status(200).json(summary);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;
    const result = await budgetService.deleteBudget(id, userId);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
});

router.get('/history', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const months = req.query.months ? parseInt(req.query.months as string) : 6;
    const history = await budgetService.getBudgetHistory(userId, months);
    res.status(200).json(history);
  } catch (error) {
    next(error);
  }
});

router.get('/compare', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { month1, year1, month2, year2 } = req.query;
    
    if (!month1 || !year1 || !month2 || !year2) {
      res.status(400).json({
        status: 400,
        message: 'Missing required parameters: month1, year1, month2, year2',
      });
      return;
    }
    
    const comparison = await budgetService.compareBudgets(
      userId,
      parseInt(month1 as string),
      parseInt(year1 as string),
      parseInt(month2 as string),
      parseInt(year2 as string)
    );
    res.status(200).json(comparison);
  } catch (error) {
    next(error);
  }
});

export default router;
