import { Router } from 'express';
import { sepayController } from '../controllers/sepay.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();

// ============================================
// PUBLIC ENDPOINTS (No authentication required)
// ============================================

/**
 * @route POST /api/sepay/webhook/public
 * @desc Webhook endpoint for Sepay to send transaction notifications
 * @access Public (called by Sepay servers)
 * 
 * Expected payload from Sepay:
 * {
 *   "id": 93,
 *   "gateway": "MBBank",
 *   "transactionDate": "2024-07-11 23:30:10",
 *   "accountNumber": "0123456789",
 *   "code": null,
 *   "content": "NGUYEN VAN A chuyen tien",
 *   "transferType": "in" | "out",
 *   "transferAmount": 100000,
 *   "accumulated": 500000,
 *   "subAccount": null,
 *   "referenceCode": "FT24193929399",
 *   "description": ""
 * }
 */
router.post('/webhook/public', (req, res, next) => 
  sepayController.handlePublicWebhook(req, res, next)
);

// ============================================
// AUTHENTICATED ENDPOINTS
// ============================================
router.use(authenticate);

// Test Sepay connection
router.get('/test', (req, res, next) => 
  sepayController.testConnection(req, res, next)
);

// Get bank accounts from Sepay
router.get('/accounts', (req, res, next) => 
  sepayController.getBankAccounts(req, res, next)
);

// Get transactions from Sepay
router.get('/transactions', (req, res, next) => 
  sepayController.getTransactions(req, res, next)
);

// Authenticated webhook (for testing/manual trigger)
router.post('/webhook', (req, res, next) => 
  sepayController.handleWebhook(req, res, next)
);

/**
 * @route POST /api/sepay/webhook/simulate
 * @desc Simulate a webhook for testing purposes
 * @access Private (requires authentication)
 * 
 * Request body:
 * {
 *   "amount": 100000,
 *   "type": "out" | "in",
 *   "content": "GRAB FOOD order",
 *   "bankCode": "MBBANK",
 *   "accountNumber": "0123456789"
 * }
 */
router.post('/webhook/simulate', (req, res, next) => 
  sepayController.simulateWebhook(req, res, next)
);

/**
 * @route GET /api/sepay/webhook/logs
 * @desc Get recent webhook transaction logs
 * @access Private (requires authentication)
 */
router.get('/webhook/logs', (req, res, next) => 
  sepayController.getWebhookLogs(req, res, next)
);

/**
 * @route GET /api/sepay/webhook/raw
 * @desc Get raw webhook JSON payloads from Sepay
 * @access Private (requires authentication)
 */
router.get('/webhook/raw', (req, res, next) => 
  sepayController.getRawWebhookLogs(req, res, next)
);

/**
 * @route GET /api/sepay/webhook/info
 * @desc Get webhook URL information for configuration
 * @access Private (requires authentication)
 */
router.get('/webhook/info', (req, res, next) => 
  sepayController.getWebhookInfo(req, res, next)
);

// Sync transactions from Sepay
router.post('/sync', (req, res, next) => 
  sepayController.syncTransactions(req, res, next)
);

// Link a bank account
router.post('/link-account', (req, res, next) => 
  sepayController.linkAccount(req, res, next)
);

export default router;

