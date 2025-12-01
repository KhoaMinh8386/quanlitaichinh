import { Router } from 'express';
import { CategoryService } from '../services/category.service';
import { authenticate, AuthRequest } from '../middlewares/auth';

const router = Router();
const categoryService = new CategoryService();

router.use(authenticate);

router.get('/', async (req: AuthRequest, res, next) => {
  try {
    const userId = req.userId!;
    const { type } = req.query;
    
    const categories = type
      ? await categoryService.getCategoriesByType(userId, type as 'income' | 'expense')
      : await categoryService.getCategories(userId);
    
    res.status(200).json(categories);
  } catch (error) {
    next(error);
  }
});

export default router;
