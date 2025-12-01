import { Request, Response, NextFunction } from 'express';
import { GoogleSheetsService } from '../services/googleSheets.service';
import { logger } from '../utils/logger';
import { ValidationError } from '../middlewares/errorHandler';

export class GoogleSheetsController {
  /**
   * Sync transactions from Google Sheets
   * POST /api/google-sheets/sync
   */
  async syncTransactions(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { spreadsheetId, range } = req.body;

      if (!spreadsheetId) {
        throw new ValidationError('Spreadsheet ID is required');
      }

      logger.info(`Syncing Google Sheets for user ${userId}, spreadsheet: ${spreadsheetId}`);

      const service = new GoogleSheetsService(spreadsheetId);
      const result = await service.syncTransactions(userId, range);

      res.json({
        success: result.success,
        message: result.message,
        data: {
          synced: result.synced,
          skipped: result.skipped,
          errors: result.errors,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Read and preview Google Sheets data
   * GET /api/google-sheets/preview
   */
  async previewData(req: Request, res: Response, next: NextFunction) {
    try {
      const { spreadsheetId, range } = req.query;

      if (!spreadsheetId) {
        throw new ValidationError('Spreadsheet ID is required');
      }

      logger.info(`Previewing Google Sheets: ${spreadsheetId}`);

      const service = new GoogleSheetsService(spreadsheetId as string);
      const rows = await service.readPublicSheet((range as string) || 'A1:J100');
      const transactions = service.parseRowsToTransactions(rows);

      res.json({
        success: true,
        data: {
          totalRows: rows.length,
          transactions: transactions.slice(0, 10), // Preview first 10
          sample: transactions[0] || null,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

export const googleSheetsController = new GoogleSheetsController();

