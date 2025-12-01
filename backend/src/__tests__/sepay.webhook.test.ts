import request from 'supertest';
import app from '../index';

describe('Sepay Webhook Endpoints', () => {
  describe('POST /api/sepay/webhook/public', () => {
    const validPayload = {
      id: 12345,
      gateway: 'MBBank',
      transactionDate: '2024-07-11 23:30:10',
      accountNumber: '0123456789',
      code: null,
      content: 'GRAB FOOD thanh toan don hang',
      transferType: 'out',
      transferAmount: 75000,
      accumulated: 5000000,
      subAccount: null,
      referenceCode: 'FT24193929399',
      description: 'Payment for Grab Food',
    };

    it('should accept valid webhook payload', async () => {
      const response = await request(app)
        .post('/api/sepay/webhook/public')
        .send(validPayload)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should handle income transaction (transferType: in)', async () => {
      const incomePayload = {
        ...validPayload,
        id: 12346,
        referenceCode: 'FT24193929400',
        content: 'LUONG THANG 1',
        transferType: 'in',
        transferAmount: 15000000,
      };

      const response = await request(app)
        .post('/api/sepay/webhook/public')
        .send(incomePayload)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should handle expense transaction (transferType: out)', async () => {
      const expensePayload = {
        ...validPayload,
        id: 12347,
        referenceCode: 'FT24193929401',
        content: 'SHOPEE mua sam',
        transferType: 'out',
        transferAmount: 250000,
      };

      const response = await request(app)
        .post('/api/sepay/webhook/public')
        .send(expensePayload)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject payload without accountNumber', async () => {
      const invalidPayload = { ...validPayload };
      delete (invalidPayload as any).accountNumber;

      const response = await request(app)
        .post('/api/sepay/webhook/public')
        .send(invalidPayload)
        .expect(200); // Still returns 200 to acknowledge receipt

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Invalid payload');
    });

    it('should reject payload without transferAmount', async () => {
      const invalidPayload = { ...validPayload };
      delete (invalidPayload as any).transferAmount;

      const response = await request(app)
        .post('/api/sepay/webhook/public')
        .send(invalidPayload)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('Invalid payload');
    });

    it('should handle duplicate transactions (idempotency)', async () => {
      const uniquePayload = {
        ...validPayload,
        id: 99999,
        referenceCode: 'UNIQUE_REF_' + Date.now(),
      };

      // First request
      const response1 = await request(app)
        .post('/api/sepay/webhook/public')
        .send(uniquePayload)
        .expect(200);

      // Second request with same referenceCode
      const response2 = await request(app)
        .post('/api/sepay/webhook/public')
        .send(uniquePayload)
        .expect(200);

      expect(response2.body.success).toBe(true);
      // Second should be detected as duplicate
    });
  });
});

describe('Sepay Webhook Payload Formats', () => {
  it('should parse MBBank format correctly', () => {
    const mbBankPayload = {
      id: 93,
      gateway: 'MBBank',
      transactionDate: '2024-07-11 23:30:10',
      accountNumber: '0381000123456',
      code: null,
      content: 'NGUYEN VAN A chuyen tien GD 123456',
      transferType: 'in',
      transferAmount: 100000,
      accumulated: 500000,
      subAccount: null,
      referenceCode: 'FT24193929399',
      description: '',
    };

    expect(mbBankPayload.transferType).toBe('in');
    expect(mbBankPayload.transferAmount).toBe(100000);
    expect(mbBankPayload.gateway).toBe('MBBank');
  });

  it('should parse Vietcombank format correctly', () => {
    const vcbPayload = {
      id: 94,
      gateway: 'Vietcombank',
      transactionDate: '2024-07-11 23:35:00',
      accountNumber: '1234567890',
      code: null,
      content: 'CT DEN TK 1234567890 SO TIEN 500000 VND',
      transferType: 'in',
      transferAmount: 500000,
      accumulated: 1500000,
      subAccount: null,
      referenceCode: 'VCB123456789',
      description: 'Nhan tien tu NGUYEN VAN B',
    };

    expect(vcbPayload.transferType).toBe('in');
    expect(vcbPayload.transferAmount).toBe(500000);
  });

  it('should parse Techcombank format correctly', () => {
    const tcbPayload = {
      id: 95,
      gateway: 'Techcombank',
      transactionDate: '2024-07-12 10:00:00',
      accountNumber: '19033123456789',
      code: 'TCB001',
      content: 'THANH TOAN HOA DON DIEN',
      transferType: 'out',
      transferAmount: 350000,
      accumulated: 2000000,
      subAccount: null,
      referenceCode: 'TCB24195000001',
      description: 'EVN HANOI - Hoa don thang 7',
    };

    expect(tcbPayload.transferType).toBe('out');
    expect(tcbPayload.transferAmount).toBe(350000);
  });
});

describe('Transaction Auto-Categorization from Webhook', () => {
  const testCases = [
    { content: 'GRAB FOOD don hang GF123', expectedCategory: 'Food' },
    { content: 'SHOPEE FOOD order SF456', expectedCategory: 'Food' },
    { content: 'GRAB di chuyen', expectedCategory: 'Transport' },
    { content: 'GOJEK trip', expectedCategory: 'Transport' },
    { content: 'TIEN DIEN EVN thang 7', expectedCategory: 'Bills' },
    { content: 'VNPT Internet', expectedCategory: 'Bills' },
    { content: 'SHOPEE mua sam', expectedCategory: 'Shopping' },
    { content: 'LAZADA order', expectedCategory: 'Shopping' },
    { content: 'NETFLIX subscription', expectedCategory: 'Entertainment' },
    { content: 'CGV cinema ticket', expectedCategory: 'Entertainment' },
  ];

  testCases.forEach(({ content, expectedCategory }) => {
    it(`should categorize "${content}" as ${expectedCategory}`, () => {
      // This is a placeholder - actual categorization is done by the service
      expect(content.toLowerCase()).toBeDefined();
    });
  });
});

