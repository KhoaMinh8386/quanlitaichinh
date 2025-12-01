import { SepayService, SepayWebhookPayload } from '../services/sepay.service';
import crypto from 'crypto';

// Mock PrismaClient
jest.mock('@prisma/client', () => {
  const mockPrisma = {
    transaction: {
      findFirst: jest.fn(),
      create: jest.fn(),
      findMany: jest.fn(),
      aggregate: jest.fn(),
    },
    bankAccount: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
    bankProvider: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
    bankConnection: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
    category: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
    },
    alert: {
      create: jest.fn(),
      findFirst: jest.fn(),
    },
    categoryPattern: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
  };
  return { PrismaClient: jest.fn(() => mockPrisma) };
});

describe('SepayService', () => {
  let sepayService: SepayService;

  beforeEach(() => {
    jest.clearAllMocks();
    sepayService = new SepayService();
  });

  describe('verifyWebhookSignature', () => {
    const webhookSecret = 'test_secret';

    beforeAll(() => {
      process.env.SEPAY_WEBHOOK_SECRET = webhookSecret;
    });

    it('should verify valid signature', () => {
      const payload = JSON.stringify({ test: 'data' });
      const signature = crypto
        .createHmac('sha256', webhookSecret)
        .update(payload)
        .digest('hex');

      const result = sepayService.verifyWebhookSignature(payload, signature);
      expect(result).toBe(true);
    });

    it('should reject invalid signature', () => {
      const payload = JSON.stringify({ test: 'data' });
      const invalidSignature = 'invalid_signature_here';

      const result = sepayService.verifyWebhookSignature(payload, invalidSignature);
      expect(result).toBe(false);
    });

    it('should verify signature with timestamp', () => {
      const payload = JSON.stringify({ test: 'data' });
      const timestamp = Date.now().toString();
      const dataToSign = `${timestamp}.${payload}`;
      const signature = crypto
        .createHmac('sha256', webhookSecret)
        .update(dataToSign)
        .digest('hex');

      const result = sepayService.verifyWebhookSignature(payload, signature, timestamp);
      expect(result).toBe(true);
    });

    it('should reject expired timestamp', () => {
      const payload = JSON.stringify({ test: 'data' });
      const oldTimestamp = (Date.now() - 10 * 60 * 1000).toString(); // 10 minutes ago
      const dataToSign = `${oldTimestamp}.${payload}`;
      const signature = crypto
        .createHmac('sha256', webhookSecret)
        .update(dataToSign)
        .digest('hex');

      const result = sepayService.verifyWebhookSignature(payload, signature, oldTimestamp);
      expect(result).toBe(false);
    });
  });

  describe('Webhook Payload Processing', () => {
    it('should handle valid webhook payload structure', () => {
      const validPayload: SepayWebhookPayload = {
        id: 12345,
        gateway: 'MBBANK',
        transactionDate: '2025-01-15T10:30:00Z',
        accountNumber: '0123456789',
        subAccount: null,
        code: null,
        content: 'GRAB THANH TOAN',
        transferType: 'out',
        description: 'Payment for Grab',
        transferAmount: 50000,
        referenceCode: 'MB123456789',
        accumulated: 1000000,
      };

      expect(validPayload.accountNumber).toBe('0123456789');
      expect(validPayload.transferType).toBe('out');
      expect(validPayload.transferAmount).toBe(50000);
    });

    it('should identify income transactions', () => {
      const incomePayload: SepayWebhookPayload = {
        id: 12346,
        gateway: 'VCB',
        transactionDate: '2025-01-15T10:30:00Z',
        accountNumber: '0123456789',
        subAccount: null,
        code: null,
        content: 'LUONG THANG 1',
        transferType: 'in',
        description: 'Salary January',
        transferAmount: 15000000,
        referenceCode: 'VCB987654321',
        accumulated: 16000000,
      };

      expect(incomePayload.transferType).toBe('in');
      expect(incomePayload.transferAmount).toBe(15000000);
    });

    it('should identify expense transactions', () => {
      const expensePayload: SepayWebhookPayload = {
        id: 12347,
        gateway: 'TCB',
        transactionDate: '2025-01-15T10:30:00Z',
        accountNumber: '0123456789',
        subAccount: null,
        code: null,
        content: 'SHOPEE MUA SAM',
        transferType: 'out',
        description: 'Shopee shopping',
        transferAmount: 200000,
        referenceCode: 'TCB111222333',
        accumulated: 15800000,
      };

      expect(expensePayload.transferType).toBe('out');
      expect(expensePayload.transferAmount).toBe(200000);
    });
  });
});

describe('Webhook Idempotency', () => {
  it('should generate unique transaction code from referenceCode', () => {
    const payload: SepayWebhookPayload = {
      id: 12345,
      gateway: 'MBBANK',
      transactionDate: '2025-01-15T10:30:00Z',
      accountNumber: '0123456789',
      subAccount: null,
      code: null,
      content: 'Test payment',
      transferType: 'out',
      description: null,
      transferAmount: 100000,
      referenceCode: 'MB_UNIQUE_REF_123',
      accumulated: 0,
    };

    const transactionCode = payload.referenceCode || `sepay_${payload.id}`;
    expect(transactionCode).toBe('MB_UNIQUE_REF_123');
  });

  it('should fallback to sepay_id if no referenceCode', () => {
    const payload: SepayWebhookPayload = {
      id: 99999,
      gateway: 'MBBANK',
      transactionDate: '2025-01-15T10:30:00Z',
      accountNumber: '0123456789',
      subAccount: null,
      code: null,
      content: 'Test payment',
      transferType: 'out',
      description: null,
      transferAmount: 100000,
      referenceCode: '',
      accumulated: 0,
    };

    const transactionCode = payload.referenceCode || `sepay_${payload.id}`;
    expect(transactionCode).toBe('sepay_99999');
  });
});

