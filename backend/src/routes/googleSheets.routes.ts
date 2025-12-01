import { Router } from 'express';
import { googleSheetsController } from '../controllers/googleSheets.controller';
import { authenticate } from '../middlewares/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route POST /api/google-sheets/sync
 * @desc Sync transactions from Google Sheets
 * @access Private (requires authentication)
 * 
 * Request body:
 * {
 *   "spreadsheetId": "1dUnR5LJ57Q4BQLviOsckPGySkb3YtjD5_gRAvZrgt0s",
 *   "range": "A1:J1000" (optional)
 * }
 */
router.post('/sync', (req, res, next) => 
  googleSheetsController.syncTransactions(req, res, next)
);

/**
 * @route GET /api/google-sheets/preview
 * @desc Preview Google Sheets data without syncing
 * @access Private (requires authentication)
 * 
 * Query params:
 * - spreadsheetId: Google Sheets ID (required)
 * - range: Range to read (optional, default: A1:J100)
 */
router.get('/preview', (req, res, next) => 
  googleSheetsController.previewData(req, res, next)
);

export default router;

