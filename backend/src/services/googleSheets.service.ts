import { google } from 'googleapis';
import axios from 'axios';
import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';
import { CategorizationService } from './categorization.service';

const prisma = new PrismaClient();
const categorizationService = new CategorizationService();

// Google Sheets row structure (from template)
interface GoogleSheetsRow {
  bank: string;              // A: Ngân hàng
  transactionDate: string;   // B: Ngày giao dịch
  accountNumber: string;      // C: Số tài khoản
  subAccount: string;         // D: Tài khoản phụ
  codeTT: string;            // E: Code TT
  content: string;           // F: Nội dung thanh toán
  type: string;              // G: Loại (in/out)
  amount: string;            // H: Số tiền
  referenceCode: string;     // I: Mã tham chiếu
  accumulated: string;       // J: Lũy kế
}

export class GoogleSheetsService {
  private sheets: any;
  private spreadsheetId: string;

  constructor(spreadsheetId: string, apiKey?: string) {
    this.spreadsheetId = spreadsheetId;
    
    // Initialize Google Sheets API
    // Option 1: Using API Key (public sheets)
    if (apiKey) {
      const auth = new google.auth.GoogleAuth({
        key: apiKey,
        scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
      });
      
      this.sheets = google.sheets({ version: 'v4', auth });
    } else {
      // Option 2: Public sheet (no auth needed for read-only)
      // We'll use a simple fetch approach for public sheets
      this.sheets = null;
    }
  }

  /**
   * Read data from Google Sheets (public sheet)
   * Using CSV export method for simplicity
   */
  async readPublicSheet(range: string = 'A1:J1000'): Promise<any[][]> {
    try {
      // Google Sheets CSV export URL
      const sheetId = this.spreadsheetId;
      const url = `https://docs.google.com/spreadsheets/d/${sheetId}/gviz/tq?tqx=out:csv&sheet=Sheet1&range=${range}`;
      
      logger.info(`Reading Google Sheets: ${url}`);
      
      const response = await axios.get(url, {
        responseType: 'text',
        headers: {
          'Accept': 'text/csv',
        },
      });
      
      const csvText = response.data;
      
      // Parse CSV
      const rows: any[][] = [];
      const lines = csvText.split('\n');
      
      for (const line of lines) {
        if (line.trim()) {
          // Simple CSV parsing (handles quoted fields)
          const row = this.parseCSVLine(line);
          if (row.length > 0) {
            rows.push(row);
          }
        }
      }
      
      logger.info(`Read ${rows.length} rows from Google Sheets`);
      return rows;
    } catch (error: any) {
      logger.error(`Error reading Google Sheets: ${error.message}`, error);
      throw error;
    }
  }

  /**
   * Parse CSV line (handles quoted fields)
   */
  private parseCSVLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;
    
    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.push(current.trim());
    return result;
  }

  /**
   * Convert Google Sheets rows to transaction format
   */
  parseRowsToTransactions(rows: any[][]): GoogleSheetsRow[] {
    if (rows.length < 2) {
      return []; // Need at least header + 1 data row
    }

    const transactions: GoogleSheetsRow[] = [];
    
    // Skip header row (row 0)
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      
      // Check if row has data (at least account number and amount)
      if (row.length >= 8 && row[2] && row[7]) {
        try {
          const transaction: GoogleSheetsRow = {
            bank: row[0] || '',
            transactionDate: row[1] || '',
            accountNumber: row[2] || '',
            subAccount: row[3] || '',
            codeTT: row[4] || '',
            content: row[5] || '',
            type: row[6] || '',
            amount: row[7] || '0',
            referenceCode: row[8] || '',
            accumulated: row[9] || '0',
          };
          
          transactions.push(transaction);
        } catch (error) {
          logger.warn(`Error parsing row ${i}: ${error}`);
        }
      }
    }
    
    return transactions;
  }

  /**
   * Convert Google Sheets transaction to Sepay format
   */
  convertToSepayFormat(row: GoogleSheetsRow): {
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
  } {
    // Parse date (assuming format: DD/MM/YYYY or YYYY-MM-DD)
    let dateStr = row.transactionDate.trim();
    let parsedDate: Date;
    
    if (dateStr.includes('/')) {
      // DD/MM/YYYY format
      const [day, month, year] = dateStr.split('/');
      parsedDate = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
    } else {
      parsedDate = new Date(dateStr);
    }
    
    // Parse amount (remove commas, spaces, currency symbols)
    const amountStr = row.amount.toString().replace(/[,\s₫đVND]/g, '');
    const amount = parseFloat(amountStr) || 0;
    
    // Parse accumulated
    const accumulatedStr = row.accumulated.toString().replace(/[,\s₫đVND]/g, '');
    const accumulated = parseFloat(accumulatedStr) || 0;
    
    // Determine transfer type
    const type = row.type.toLowerCase().trim();
    const transferType: 'in' | 'out' = type === 'in' || type === 'tiền vào' || type === 'thu' ? 'in' : 'out';
    
    return {
      id: Date.now() + Math.random(), // Generate unique ID
      gateway: row.bank || 'Unknown',
      transactionDate: parsedDate.toISOString(),
      accountNumber: row.accountNumber,
      subAccount: row.subAccount || null,
      code: row.codeTT || null,
      content: row.content || '',
      transferType,
      description: row.content || null,
      transferAmount: amount,
      referenceCode: row.referenceCode || `GS_${Date.now()}_${Math.random().toString(36).substring(7)}`,
      accumulated,
    };
  }

  /**
   * Sync transactions from Google Sheets to database
   */
  async syncTransactions(userId: string, range?: string): Promise<{
    success: boolean;
    synced: number;
    skipped: number;
    errors: number;
    message: string;
  }> {
    try {
      logger.info(`Starting Google Sheets sync for user ${userId}`);
      
      // Read data from Google Sheets
      const rows = await this.readPublicSheet(range);
      const sheetTransactions = this.parseRowsToTransactions(rows);
      
      logger.info(`Found ${sheetTransactions.length} transactions in Google Sheets`);
      
      let synced = 0;
      let skipped = 0;
      let errors = 0;
      
      for (const sheetTxn of sheetTransactions) {
        try {
          // Convert to Sepay format
          const sepayFormat = this.convertToSepayFormat(sheetTxn);
          
          // Check for duplicate
          const existing = await prisma.transaction.findFirst({
            where: {
              userId,
              externalTxnId: sepayFormat.referenceCode,
            },
          });
          
          if (existing) {
            skipped++;
            continue;
          }
          
          // Find or create bank account
          const bankAccount = await this.findOrCreateBankAccount(
            userId,
            sepayFormat.accountNumber,
            sepayFormat.gateway
          );
          
          // Determine transaction type
          const type = sepayFormat.transferType === 'in' ? 'income' : 'expense';
          const amount = Math.abs(sepayFormat.transferAmount);
          
          // Auto-categorize
          const category = await categorizationService.categorizeTransaction({
            id: '',
            description: sepayFormat.content || sepayFormat.description || '',
            userId,
          });
          
          // Create transaction
          await prisma.transaction.create({
            data: {
              userId,
              bankAccountId: bankAccount.id,
              externalTxnId: sepayFormat.referenceCode,
              amount,
              type,
              rawDescription: sepayFormat.content || sepayFormat.description || '',
              normalizedDescription: this.normalizeDescription(sepayFormat.content || ''),
              postedAt: new Date(sepayFormat.transactionDate),
              categoryId: category.id,
              classificationSource: 'GOOGLE_SHEETS',
            },
          });
          
          synced++;
        } catch (error: any) {
          logger.error(`Error syncing transaction: ${error.message}`, error);
          errors++;
        }
      }
      
      logger.info(`Google Sheets sync completed: ${synced} synced, ${skipped} skipped, ${errors} errors`);
      
      return {
        success: true,
        synced,
        skipped,
        errors,
        message: `Synced ${synced} transactions, skipped ${skipped} duplicates, ${errors} errors`,
      };
    } catch (error: any) {
      logger.error(`Google Sheets sync failed: ${error.message}`, error);
      return {
        success: false,
        synced: 0,
        skipped: 0,
        errors: 0,
        message: `Sync failed: ${error.message}`,
      };
    }
  }

  /**
   * Find or create bank account
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
            authType: 'google_sheets',
            apiBaseUrl: '',
          },
        });
      }

      // Get or create connection
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
            accessToken: 'google_sheets',
            refreshToken: 'google_sheets',
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
          accountAlias: `${this.getBankName(bankCode)} - ${accountNumber.slice(-4)}`,
          accountNumberMask: this.maskAccountNumber(accountNumber),
          accountType: 'checking',
          currency: 'VND',
          status: 'active',
        },
      });
    }

    return bankAccount;
  }

  private maskAccountNumber(accountNumber: string): string {
    if (accountNumber.length <= 4) {
      return '*'.repeat(accountNumber.length);
    }
    return '*'.repeat(accountNumber.length - 4) + accountNumber.slice(-4);
  }

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
    };
    
    return bankNames[bankCode.toUpperCase()] || bankCode;
  }

  private normalizeDescription(description: string): string {
    return description
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();
  }
}

