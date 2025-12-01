import { PrismaClient, Prisma } from '@prisma/client';
import axios, { AxiosInstance } from 'axios';
import crypto from 'crypto';
import { sepayConfig } from '../config/sepay';
import { logger } from '../utils/logger';
import { CategorizationService } from './categorization.service';
import { AlertService } from './alert.service';

const prisma = new PrismaClient();
const categorizationService = new CategorizationService();
const alertService = new AlertService();

// Sepay Webhook payload structure
export interface SepayWebhookPayload {
  id: number;
  gateway: string;
  transactionDate: string;
  accountNumber: string;
  subAccount: string | null;
  code: string | null;
  content: string;
  transferType: 'in' | 'out';
  description: string | null;
  transferAmount: number;
  referenceCode: string;
  accumulated: number;
}

// Sepay API Response types
export interface SepayTransaction {
  id: string;
  transaction_date: string;
  account_number: string;
  amount: number;
  description: string;
  reference_code: string;
  transaction_type: 'in' | 'out';
  bank_code: string;
}

export interface SepayBankAccount {
  id: string;
  account_number: string;
  bank_name: string;
  bank_code: string;
  status: string;
}

export class SepayService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: sepayConfig.baseUrl,
      headers: {
        'Authorization': `Bearer ${sepayConfig.apiKey}`,
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });

    // Add response interceptor for logging
    this.client.interceptors.response.use(
      (response) => {
        logger.info(`Sepay API Response: ${response.config.url} - ${response.status}`);
        return response;
      },
      (error) => {
        logger.error(`Sepay API Error: ${error.config?.url} - ${error.message}`);
        throw error;
      }
    );
  }

  /**
   * Test connection to Sepay API
   */
  async testConnection(): Promise<{ success: boolean; message: string }> {
    try {
      const response = await this.client.get('/transactions', {
        params: { limit: 1 },
      });
      
      return {
        success: true,
        message: 'Successfully connected to Sepay API',
      };
    } catch (error: any) {
      logger.error('Sepay connection test failed:', error);
      return {
        success: false,
        message: error.response?.data?.message || error.message || 'Connection failed',
      };
    }
  }

  /**
   * Get list of bank accounts from Sepay
   */
  async getBankAccounts(): Promise<SepayBankAccount[]> {
    try {
      const response = await this.client.get('/bankaccounts');
      return response.data.bankAccounts || [];
    } catch (error: any) {
      logger.error('Failed to get bank accounts from Sepay:', error);
      throw new Error(`Failed to fetch bank accounts: ${error.message}`);
    }
  }

  /**
   * Get transactions from Sepay API
   */
  async getTransactions(params: {
    accountNumber?: string;
    fromDate?: string;
    toDate?: string;
    limit?: number;
  }): Promise<SepayTransaction[]> {
    try {
      const response = await this.client.get('/transactions', {
        params: {
          account_number: params.accountNumber,
          transaction_date_min: params.fromDate,
          transaction_date_max: params.toDate,
          limit: params.limit || 100,
        },
      });
      return response.data.transactions || [];
    } catch (error: any) {
      logger.error('Failed to get transactions from Sepay:', error);
      throw new Error(`Failed to fetch transactions: ${error.message}`);
    }
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(
    payload: string,
    signature: string,
    timestamp?: string
  ): boolean {
    try {
      // Check timestamp if provided (prevent replay attacks)
      if (timestamp) {
        const timestampMs = parseInt(timestamp, 10);
        const now = Date.now();
        if (Math.abs(now - timestampMs) > sepayConfig.webhook.timestampTolerance) {
          logger.warn('Webhook timestamp out of tolerance range');
          return false;
        }
      }

      // Generate expected signature
      const dataToSign = timestamp ? `${timestamp}.${payload}` : payload;
      const expectedSignature = crypto
        .createHmac('sha256', sepayConfig.webhookSecret)
        .update(dataToSign)
        .digest('hex');

      // Compare signatures
      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
    } catch (error) {
      logger.error('Webhook signature verification failed:', error);
      return false;
    }
  }

  /**
   * Process webhook payload from Sepay
   * Idempotent: checks for duplicate transaction_code
   */
  async processWebhook(
    payload: SepayWebhookPayload,
    userId: string
  ): Promise<{
    success: boolean;
    transaction?: any;
    message: string;
    isDuplicate?: boolean;
  }> {
    const transactionCode = payload.referenceCode || `sepay_${payload.id}`;
    
    logger.info(`Processing Sepay webhook: ${transactionCode}`);

    try {
      // Check for duplicate (idempotency)
      const existingTransaction = await prisma.transaction.findFirst({
        where: {
          userId,
          externalTxnId: transactionCode,
        },
      });

      if (existingTransaction) {
        logger.info(`Duplicate transaction detected: ${transactionCode}`);
        return {
          success: true,
          message: 'Transaction already exists',
          isDuplicate: true,
          transaction: existingTransaction,
        };
      }

      // Find or create bank account
      const bankAccount = await this.findOrCreateBankAccount(
        userId,
        payload.accountNumber,
        payload.gateway
      );

      // Determine transaction type
      const type = payload.transferType === 'in' ? 'income' : 'expense';
      const amount = Math.abs(payload.transferAmount);

      // Auto-categorize transaction
      const category = await categorizationService.categorizeTransaction({
        id: '',
        description: payload.content || payload.description || '',
        userId,
      });

      // Create transaction
      const transaction = await prisma.transaction.create({
        data: {
          userId,
          bankAccountId: bankAccount.id,
          externalTxnId: transactionCode,
          amount: type === 'income' ? amount : amount,
          type,
          rawDescription: payload.content || payload.description,
          normalizedDescription: this.normalizeDescription(payload.content || payload.description || ''),
          postedAt: new Date(payload.transactionDate),
          categoryId: category.id,
          classificationSource: 'AUTO',
        },
        include: {
          category: true,
          bankAccount: true,
        },
      });

      logger.info(`Transaction created: ${transaction.id}`);

      // Check for alerts (large transaction, unusual spending)
      await this.checkAndCreateAlerts(userId, transaction, amount, type);

      return {
        success: true,
        message: 'Transaction processed successfully',
        transaction,
      };
    } catch (error: any) {
      logger.error(`Failed to process webhook: ${error.message}`, error);
      return {
        success: false,
        message: `Failed to process transaction: ${error.message}`,
      };
    }
  }

  /**
   * Sync transactions from Sepay for a user
   */
  async syncTransactions(
    userId: string,
    accountNumber: string,
    fromDate?: string,
    toDate?: string
  ): Promise<{ synced: number; skipped: number; errors: number }> {
    const stats = { synced: 0, skipped: 0, errors: 0 };

    try {
      const transactions = await this.getTransactions({
        accountNumber,
        fromDate,
        toDate,
        limit: 100,
      });

      for (const txn of transactions) {
        const result = await this.processWebhook(
          {
            id: parseInt(txn.id, 10),
            gateway: txn.bank_code,
            transactionDate: txn.transaction_date,
            accountNumber: txn.account_number,
            subAccount: null,
            code: null,
            content: txn.description,
            transferType: txn.transaction_type,
            description: txn.description,
            transferAmount: txn.amount,
            referenceCode: txn.reference_code,
            accumulated: 0,
          },
          userId
        );

        if (result.success) {
          if (result.isDuplicate) {
            stats.skipped++;
          } else {
            stats.synced++;
          }
        } else {
          stats.errors++;
        }
      }

      logger.info(`Sync completed: ${stats.synced} synced, ${stats.skipped} skipped, ${stats.errors} errors`);
      return stats;
    } catch (error: any) {
      logger.error('Transaction sync failed:', error);
      throw error;
    }
  }

  /**
   * Find or create a bank account for the user
   */
  private async findOrCreateBankAccount(
    userId: string,
    accountNumber: string,
    bankCode: string
  ) {
    // Try to find existing account
    let bankAccount = await prisma.bankAccount.findFirst({
      where: {
        userId,
        accountNumberMask: this.maskAccountNumber(accountNumber),
      },
    });

    if (!bankAccount) {
      // Get or create bank provider
      let provider = await prisma.bankProvider.findFirst({
        where: { code: bankCode.toUpperCase() },
      });

      if (!provider) {
        provider = await prisma.bankProvider.create({
          data: {
            name: this.getBankName(bankCode),
            code: bankCode.toUpperCase(),
            authType: 'sepay',
            apiBaseUrl: sepayConfig.baseUrl,
          },
        });
      }

      // Get or create connection
      let connection = await prisma.bankConnection.findFirst({
        where: {
          userId,
          bankProviderId: provider.id,
          status: 'active',
        },
      });

      if (!connection) {
        connection = await prisma.bankConnection.create({
          data: {
            userId,
            bankProviderId: provider.id,
            accessToken: 'sepay_webhook',
            refreshToken: 'sepay_webhook',
            tokenExpiresAt: new Date('2099-12-31'),
            status: 'active',
          },
        });
      }

      // Create bank account
      bankAccount = await prisma.bankAccount.create({
        data: {
          userId,
          connectionId: connection.id,
          bankName: this.getBankName(bankCode),
          accountNumberMask: this.maskAccountNumber(accountNumber),
          accountType: 'checking',
          currency: 'VND',
          status: 'active',
        },
      });

      logger.info(`Created new bank account: ${bankAccount.id}`);
    }

    return bankAccount;
  }

  /**
   * Check and create alerts for unusual transactions
   */
  private async checkAndCreateAlerts(
    userId: string,
    transaction: any,
    amount: number,
    type: string
  ): Promise<void> {
    if (type !== 'expense') return;

    const { alertThresholds } = sepayConfig;

    // Check 1: Large transaction alert
    if (amount >= alertThresholds.largeTransactionAmount) {
      await alertService.createAlert({
        userId,
        alertType: 'LARGE_TRANSACTION' as any,
        message: `Phát hiện giao dịch lớn: ${amount.toLocaleString('vi-VN')} VND - ${transaction.normalizedDescription || 'Không có mô tả'}`,
        payload: {
          transactionId: transaction.id,
          amount,
          description: transaction.normalizedDescription,
          type: 'LARGE_TRANSACTION',
        },
      });
      logger.info(`Created large transaction alert for user ${userId}`);
    }

    // Check 2: Compare with average spending
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const recentTransactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'expense',
        postedAt: { gte: thirtyDaysAgo },
        id: { not: transaction.id },
      },
    });

    if (recentTransactions.length >= 5) {
      const avgAmount = recentTransactions.reduce(
        (sum, t) => sum + Number(t.amount), 0
      ) / recentTransactions.length;

      if (amount > avgAmount * alertThresholds.largeTransactionMultiplier) {
        await alertService.createAlert({
          userId,
          alertType: 'UNUSUAL_SPENDING' as any,
          message: `Giao dịch bất thường: ${amount.toLocaleString('vi-VN')} VND - gấp ${(amount / avgAmount).toFixed(1)} lần mức chi trung bình`,
          payload: {
            transactionId: transaction.id,
            amount,
            averageAmount: avgAmount,
            multiplier: amount / avgAmount,
            type: 'UNUSUAL_SPENDING',
          },
        });
        logger.info(`Created unusual spending alert for user ${userId}`);
      }
    }

    // Check 3: Category spike detection
    await this.checkCategorySpike(userId, transaction);
  }

  /**
   * Check if a category has spiked compared to historical average
   */
  private async checkCategorySpike(userId: string, transaction: any): Promise<void> {
    if (!transaction.categoryId) return;

    const { alertThresholds } = sepayConfig;
    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    // Get current month spending for this category
    const monthStart = new Date(currentYear, currentMonth, 1);
    const monthEnd = new Date(currentYear, currentMonth + 1, 0, 23, 59, 59);

    const currentMonthSpending = await prisma.transaction.aggregate({
      where: {
        userId,
        categoryId: transaction.categoryId,
        type: 'expense',
        postedAt: { gte: monthStart, lte: monthEnd },
      },
      _sum: { amount: true },
    });

    // Get average spending for this category over past 3 months
    const threeMonthsAgo = new Date(currentYear, currentMonth - 3, 1);
    const lastMonthEnd = new Date(currentYear, currentMonth, 0, 23, 59, 59);

    const historicalSpending = await prisma.transaction.findMany({
      where: {
        userId,
        categoryId: transaction.categoryId,
        type: 'expense',
        postedAt: { gte: threeMonthsAgo, lte: lastMonthEnd },
      },
    });

    // Calculate monthly average
    const monthlyTotals = new Map<string, number>();
    historicalSpending.forEach((t) => {
      const date = new Date(t.postedAt);
      const key = `${date.getFullYear()}-${date.getMonth()}`;
      monthlyTotals.set(key, (monthlyTotals.get(key) || 0) + Number(t.amount));
    });

    if (monthlyTotals.size >= 2) {
      const avgMonthlySpending = Array.from(monthlyTotals.values()).reduce(
        (sum, val) => sum + val, 0
      ) / monthlyTotals.size;

      const currentSpending = Number(currentMonthSpending._sum.amount || 0);
      const spikePercentage = (currentSpending / avgMonthlySpending) * 100;

      if (spikePercentage >= alertThresholds.categorySpikeThreashold) {
        // Check if alert already exists for this category this month
        const existingAlert = await prisma.alert.findFirst({
          where: {
            userId,
            alertType: 'CATEGORY_SPIKE',
            payload: {
              path: ['categoryId'],
              equals: transaction.categoryId,
            },
            createdAt: { gte: monthStart },
          },
        });

        if (!existingAlert) {
          await alertService.createAlert({
            userId,
            alertType: 'CATEGORY_SPIKE' as any,
            message: `Chi tiêu danh mục "${transaction.category?.name || 'Không xác định'}" tăng ${spikePercentage.toFixed(0)}% so với trung bình`,
            payload: {
              categoryId: transaction.categoryId,
              categoryName: transaction.category?.name,
              currentSpending,
              averageSpending: avgMonthlySpending,
              spikePercentage,
              type: 'CATEGORY_SPIKE',
            },
          });
          logger.info(`Created category spike alert for user ${userId}, category ${transaction.categoryId}`);
        }
      }
    }
  }

  /**
   * Normalize transaction description
   */
  private normalizeDescription(description: string): string {
    return description
      .replace(/\s+/g, ' ')
      .trim()
      .substring(0, 500);
  }

  /**
   * Mask account number for privacy
   */
  private maskAccountNumber(accountNumber: string): string {
    if (accountNumber.length <= 4) return accountNumber;
    const visibleDigits = 4;
    const masked = '*'.repeat(accountNumber.length - visibleDigits);
    return masked + accountNumber.slice(-visibleDigits);
  }

  /**
   * Get bank name from bank code
   */
  private getBankName(bankCode: string): string {
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
      'MOMO': 'MoMo',
      'ZALOPAY': 'ZaloPay',
      'VNPAY': 'VNPay',
    };

    return bankNames[bankCode.toUpperCase()] || bankCode;
  }
}

