import { Router } from 'express';
import { TransactionController } from '../controllers/transaction.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();
const transactionController = new TransactionController();

// All routes require authentication
router.use(authenticate);

/**
 * @route   POST /api/transactions
 * @desc    Create a new transaction
 * @access  Private
 */
router.post('/', (req, res, next) =>
  transactionController.createTransaction(req, res, next)
);

/**
 * @route   POST /api/transactions/bulk-update-category
 * @desc    Bulk update transaction categories
 * @access  Private
 */
router.post('/bulk-update-category', (req, res, next) =>
  transactionController.bulkUpdateCategory(req, res, next)
);

/**
 * @route   GET /api/transactions
 * @desc    Get transactions with filters
 * @access  Private
 */
router.get('/', (req, res, next) =>
  transactionController.getTransactions(req, res, next)
);

/**
 * @route   GET /api/transactions/stats
 * @desc    Get transaction statistics
 * @access  Private
 */
router.get('/stats', (req, res, next) =>
  transactionController.getTransactionStats(req, res, next)
);

/**
 * @route   GET /api/transactions/:id
 * @desc    Get transaction by ID
 * @access  Private
 */
router.get('/:id', (req, res, next) =>
  transactionController.getTransactionById(req, res, next)
);

/**
 * @route   PATCH /api/transactions/:id/category
 * @desc    Update transaction category
 * @access  Private
 */
router.patch('/:id/category', (req, res, next) =>
  transactionController.updateTransactionCategory(req, res, next)
);

/**
 * @route   PATCH /api/transactions/:id
 * @desc    Update transaction (category, notes)
 * @access  Private
 */
router.patch('/:id', (req, res, next) =>
  transactionController.updateTransaction(req, res, next)
);

export default router;
