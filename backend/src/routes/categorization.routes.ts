import { Router } from 'express';
import { CategorizationController } from '../controllers/categorization.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();
const controller = new CategorizationController();

// All routes require authentication
router.use(authenticate);

// Update transaction category (and learn from it)
router.patch(
  '/transactions/:transactionId/category',
  controller.updateTransactionCategory.bind(controller)
);

// Auto-categorize all pending transactions
router.post('/auto-categorize', controller.autoCategorizePending.bind(controller));

// Get user's categorization patterns
router.get('/patterns', controller.getPatterns.bind(controller));

// Delete a categorization pattern
router.delete('/patterns/:patternId', controller.deletePattern.bind(controller));

export default router;
