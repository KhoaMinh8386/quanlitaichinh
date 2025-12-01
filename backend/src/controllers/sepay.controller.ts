import { Request, Response, NextFunction } from 'express';
import { SepayService, SepayWebhookPayload } from '../services/sepay.service';
import { sepayConfig } from '../config/sepay';
import { logger } from '../utils/logger';
import { ValidationError, UnauthorizedError } from '../middlewares/errorHandler';
import { PrismaClient } from '@prisma/client';

const sepayService = new SepayService();
const prisma = new PrismaClient();

export class SepayController {
  /**
   * Test Sepay API connection
   * GET /api/sepay/test
   */
  async testConnection(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await sepayService.testConnection();
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get bank accounts from Sepay
   * GET /api/sepay/accounts
   */
  async getBankAccounts(req: Request, res: Response, next: NextFunction) {
    try {
      const accounts = await sepayService.getBankAccounts();
      res.json({
        success: true,
        accounts,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get transactions from Sepay
   * GET /api/sepay/transactions
   */
  async getTransactions(req: Request, res: Response, next: NextFunction) {
    try {
      const { accountNumber, fromDate, toDate, limit } = req.query;
      
      const transactions = await sepayService.getTransactions({
        accountNumber: accountNumber as string,
        fromDate: fromDate as string,
        toDate: toDate as string,
        limit: limit ? parseInt(limit as string, 10) : undefined,
      });

      res.json({
        success: true,
        transactions,
        count: transactions.length,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Webhook endpoint to receive transactions from Sepay
   * POST /api/sepay/webhook
   */
  async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const signature = req.headers[sepayConfig.webhook.signatureHeader] as string;
      const timestamp = req.headers[sepayConfig.webhook.timestampHeader] as string;
      const rawBody = JSON.stringify(req.body);

      logger.info('Received Sepay webhook');
      logger.debug('Webhook payload:', req.body);

      // Verify signature if secret is configured
      if (sepayConfig.webhookSecret) {
        if (!signature) {
          logger.warn('Webhook received without signature');
          // In development, we might allow unsigned webhooks
          if (process.env.NODE_ENV === 'production') {
            throw new UnauthorizedError('Missing webhook signature');
          }
        } else {
          const isValid = sepayService.verifyWebhookSignature(rawBody, signature, timestamp);
          if (!isValid) {
            logger.warn('Invalid webhook signature');
            throw new UnauthorizedError('Invalid webhook signature');
          }
        }
      }

      const payload: SepayWebhookPayload = req.body;

      // Validate required fields
      if (!payload.accountNumber || payload.transferAmount === undefined) {
        throw new ValidationError('Missing required fields in webhook payload');
      }

      // Find user by account number
      // For now, we'll use a default user or the user from auth
      // In production, you'd map account numbers to users
      const userId = (req as any).user?.id || await this.findUserByAccountNumber(payload.accountNumber);

      if (!userId) {
        logger.warn(`No user found for account number: ${payload.accountNumber}`);
        // Still return 200 to acknowledge receipt
        res.json({
          success: true,
          message: 'Webhook received but no matching user found',
        });
        return;
      }

      const result = await sepayService.processWebhook(payload, userId);

      res.json(result);
    } catch (error) {
      logger.error('Webhook processing error:', error);
      next(error);
    }
  }

  /**
   * Webhook endpoint without authentication (for Sepay to call)
   * POST /api/sepay/webhook/public
   * 
   * Sepay webhook payload format:
   * {
   *   "id": 93,
   *   "gateway": "MBBank",
   *   "transactionDate": "2024-07-11 23:30:10",
   *   "accountNumber": "0123456789",
   *   "code": null,
   *   "content": "NGUYEN VAN A chuyen tien",
   *   "transferType": "in",
   *   "transferAmount": 100000,
   *   "accumulated": 500000,
   *   "subAccount": null,
   *   "referenceCode": "FT24193929399",
   *   "description": ""
   * }
   */
  async handlePublicWebhook(req: Request, res: Response, _next: NextFunction): Promise<void> {
    try {
      logger.info('=== SEPAY WEBHOOK RECEIVED ===');
      logger.info('Headers:', JSON.stringify(req.headers, null, 2));
      logger.info('Body:', JSON.stringify(req.body, null, 2));

      const signature = req.headers[sepayConfig.webhook.signatureHeader] as string;
      const timestamp = req.headers[sepayConfig.webhook.timestampHeader] as string;
      const rawBody = JSON.stringify(req.body);

      // Verify signature if configured
      if (sepayConfig.webhookSecret && signature) {
        const isValid = sepayService.verifyWebhookSignature(rawBody, signature, timestamp);
        if (!isValid) {
          logger.warn('Invalid webhook signature on public endpoint');
          // Return 200 anyway to not expose validation details
          res.json({ success: true, message: 'Received' });
          return;
        }
        logger.info('Webhook signature verified successfully');
      }

      // Map Sepay payload to internal format
      const payload: SepayWebhookPayload = {
        id: req.body.id,
        gateway: req.body.gateway,
        transactionDate: req.body.transactionDate,
        accountNumber: req.body.accountNumber,
        subAccount: req.body.subAccount,
        code: req.body.code,
        content: req.body.content,
        transferType: req.body.transferType,
        description: req.body.description,
        transferAmount: req.body.transferAmount,
        referenceCode: req.body.referenceCode,
        accumulated: req.body.accumulated,
      };

      // Validate required fields
      if (!payload.accountNumber) {
        logger.warn('Missing accountNumber in payload');
        res.json({ success: true, message: 'Invalid payload - missing accountNumber' });
        return;
      }

      if (payload.transferAmount === undefined || payload.transferAmount === null) {
        logger.warn('Missing transferAmount in payload');
        res.json({ success: true, message: 'Invalid payload - missing transferAmount' });
        return;
      }

      // Find user by account number (match last 4 digits)
      const userId = await this.findUserByAccountNumber(payload.accountNumber);

      if (!userId) {
        logger.info(`No user found for account: ${payload.accountNumber}`);
        // Try to find any user with linked bank account (for demo purposes)
        const anyBankAccount = await prisma.bankAccount.findFirst({
          where: { status: 'active' },
          select: { userId: true },
        });
        
        if (anyBankAccount) {
          logger.info(`Using fallback user: ${anyBankAccount.userId}`);
          const result = await sepayService.processWebhook(payload, anyBankAccount.userId);
          res.json({
            success: true,
            message: result.isDuplicate ? 'Duplicate transaction' : 'Transaction processed (fallback user)',
            transactionId: result.transaction?.id,
          });
          return;
        }
        
        res.json({ success: true, message: 'No matching user found' });
        return;
      }

      logger.info(`Processing webhook for user: ${userId}`);
      const result = await sepayService.processWebhook(payload, userId);
      
      logger.info(`Webhook processed: ${result.message}`);
      
      // Always return 200 to Sepay
      res.json({
        success: true,
        message: result.isDuplicate ? 'Duplicate transaction' : 'Transaction processed',
        transactionId: result.transaction?.id,
      });
    } catch (error: any) {
      logger.error('Public webhook error:', error);
      // Always return 200 to Sepay to acknowledge receipt
      res.json({ success: true, message: 'Error processing webhook: ' + error.message });
    }
  }

  /**
   * Sync transactions from Sepay
   * POST /api/sepay/sync
   */
  async syncTransactions(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { accountNumber, fromDate, toDate } = req.body;

      if (!accountNumber) {
        throw new ValidationError('Account number is required');
      }

      const result = await sepayService.syncTransactions(
        userId,
        accountNumber,
        fromDate,
        toDate
      );

      res.json({
        success: true,
        ...result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Link a bank account to user's Sepay
   * POST /api/sepay/link-account
   * 
   * Request body:
   * {
   *   "accountNumber": "0123456789",  // Full account number from Sepay
   *   "bankCode": "MBBANK",            // Bank code (MBBank, VCB, TCB, etc.)
   *   "alias": "Tài khoản chính"       // Optional friendly name
   * }
   */
  async linkAccount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as any).user.id;
      const { accountNumber, bankCode, alias } = req.body;

      if (!accountNumber || !bankCode) {
        throw new ValidationError('Account number and bank code are required');
      }

      logger.info(`Linking account ${accountNumber} (${bankCode}) for user ${userId}`);

      // Get bank name mapping
      const bankNames: { [key: string]: string } = {
        'MBBANK': 'MB Bank',
        'MB': 'MB Bank',
        'VCB': 'Vietcombank',
        'VIETCOMBANK': 'Vietcombank',
        'TCB': 'Techcombank',
        'TECHCOMBANK': 'Techcombank',
        'BIDV': 'BIDV',
        'ACB': 'ACB',
        'VPB': 'VPBank',
        'VPBANK': 'VPBank',
        'TPB': 'TPBank',
        'TPBANK': 'TPBank',
        'MSB': 'MSB',
        'SHB': 'SHB',
        'VIB': 'VIB',
        'SACOMBANK': 'Sacombank',
        'STB': 'Sacombank',
        'AGRIBANK': 'Agribank',
        'VIETINBANK': 'VietinBank',
        'CTG': 'VietinBank',
      };

      const bankName = bankNames[bankCode.toUpperCase()] || bankCode;

      // Check if provider exists
      let provider = await prisma.bankProvider.findFirst({
        where: { code: bankCode.toUpperCase() },
      });

      if (!provider) {
        provider = await prisma.bankProvider.create({
          data: {
            name: bankName,
            code: bankCode.toUpperCase(),
            authType: 'sepay',
            apiBaseUrl: sepayConfig.baseUrl,
          },
        });
      }

      // Create or get connection
      let connection = await prisma.bankConnection.findFirst({
        where: {
          userId,
          bankProviderId: provider.id,
        },
      });

      if (!connection) {
        connection = await prisma.bankConnection.create({
          data: {
            userId,
            bankProviderId: provider.id,
            accessToken: 'sepay_linked',
            refreshToken: 'sepay_linked',
            tokenExpiresAt: new Date('2099-12-31'),
            status: 'active',
          },
        });
      }

      // Check if account already exists (match last 4 digits)
      const existingAccount = await prisma.bankAccount.findFirst({
        where: {
          userId,
          accountNumberMask: { endsWith: accountNumber.slice(-4) },
        },
      });

      if (existingAccount) {
        // Update existing account instead of throwing error
        const updated = await prisma.bankAccount.update({
          where: { id: existingAccount.id },
          data: {
            accountAlias: alias || existingAccount.accountAlias,
            status: 'active',
          },
        });

        res.json({
          success: true,
          message: 'Account already linked, updated alias',
          account: {
            id: updated.id,
            bankName: updated.bankName,
            alias: updated.accountAlias,
            accountMask: updated.accountNumberMask,
          },
        });
        return;
      }

      // Create bank account - store last 4 digits for webhook matching
      const bankAccount = await prisma.bankAccount.create({
        data: {
          userId,
          connectionId: connection.id,
          bankName: bankName,
          accountAlias: alias || `${bankName} - ${accountNumber.slice(-4)}`,
          // Store masked account but keep last 4 digits for matching
          accountNumberMask: '*'.repeat(Math.max(0, accountNumber.length - 4)) + accountNumber.slice(-4),
          accountType: 'checking',
          currency: 'VND',
          status: 'active',
        },
      });

      logger.info(`Account linked successfully: ${bankAccount.id}`);

      res.json({
        success: true,
        message: 'Account linked successfully',
        account: {
          id: bankAccount.id,
          bankName: bankAccount.bankName,
          alias: bankAccount.accountAlias,
          accountMask: bankAccount.accountNumberMask,
        },
        webhookInfo: {
          message: 'Webhook sẽ tự động nhận giao dịch từ tài khoản này',
          endpoint: '/api/sepay/webhook/public',
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Simulate webhook for testing
   * POST /api/sepay/webhook/simulate
   */
  async simulateWebhook(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { 
        amount, 
        type = 'out', 
        content = 'Test transaction', 
        bankCode = 'MBBANK',
        accountNumber = '0123456789'
      } = req.body;

      if (!amount) {
        throw new ValidationError('Amount is required');
      }

      // Create simulated payload
      const payload: SepayWebhookPayload = {
        id: Date.now(),
        gateway: bankCode,
        transactionDate: new Date().toISOString(),
        accountNumber: accountNumber,
        subAccount: null,
        code: null,
        content: content,
        transferType: type as 'in' | 'out',
        description: `Simulated transaction: ${content}`,
        transferAmount: Math.abs(amount),
        referenceCode: `SIM_${Date.now()}_${Math.random().toString(36).substring(7)}`,
        accumulated: 0,
      };

      logger.info('Simulating webhook:', payload);

      const result = await sepayService.processWebhook(payload, userId);

      res.json({
        success: true,
        message: 'Webhook simulated successfully',
        result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get webhook logs (for debugging)
   * GET /api/sepay/webhook/logs
   */
  async getWebhookLogs(req: Request, res: Response, next: NextFunction) {
    try {
      // Return recent transactions created via webhook
      const recentTransactions = await prisma.transaction.findMany({
        where: {
          externalTxnId: { not: null },
        },
        orderBy: { createdAt: 'desc' },
        take: 20,
        select: {
          id: true,
          externalTxnId: true,
          amount: true,
          type: true,
          rawDescription: true,
          postedAt: true,
          createdAt: true,
          bankAccount: {
            select: {
              bankName: true,
              accountNumberMask: true,
            },
          },
          category: {
            select: {
              name: true,
            },
          },
        },
      });

      res.json({
        success: true,
        transactions: recentTransactions,
        count: recentTransactions.length,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Helper: Find user by account number
   */
  private async findUserByAccountNumber(accountNumber: string): Promise<string | null> {
    // Find bank account with matching account number (last 4 digits)
    const bankAccount = await prisma.bankAccount.findFirst({
      where: {
        OR: [
          { accountNumberMask: { endsWith: accountNumber.slice(-4) } },
          { accountNumberMask: { contains: accountNumber } },
        ],
        status: 'active',
      },
    });

    if (bankAccount) {
      logger.info(`Found user ${bankAccount.userId} for account ${accountNumber}`);
    }

    return bankAccount?.userId || null;
  }
}

export const sepayController = new SepayController();

