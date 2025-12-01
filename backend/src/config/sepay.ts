import dotenv from 'dotenv';

dotenv.config();

export const sepayConfig = {
  apiKey: process.env.SEPAY_API_KEY || '',
  webhookSecret: process.env.SEPAY_WEBHOOK_SECRET || '',
  baseUrl: process.env.SEPAY_BASE_URL || 'https://my.sepay.vn/userapi',
  
  // Thresholds for alerts
  alertThresholds: {
    // Ngưỡng giao dịch lớn (VND)
    largeTransactionAmount: parseInt(process.env.SEPAY_LARGE_TRANSACTION_THRESHOLD || '5000000', 10),
    // Số lần trung bình để coi là giao dịch lớn bất thường
    largeTransactionMultiplier: parseFloat(process.env.SEPAY_LARGE_TRANSACTION_MULTIPLIER || '3'),
    // Ngưỡng tăng đột biến theo danh mục (%)
    categorySpikeThreashold: parseFloat(process.env.SEPAY_CATEGORY_SPIKE_THRESHOLD || '150'),
  },
  
  // Webhook verification settings
  webhook: {
    signatureHeader: 'x-sepay-signature',
    timestampHeader: 'x-sepay-timestamp',
    // Tolerance for timestamp validation (5 minutes)
    timestampTolerance: 5 * 60 * 1000,
  },
};

// Validate config
export const validateSepayConfig = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];
  
  if (!sepayConfig.apiKey) {
    errors.push('SEPAY_API_KEY is not set');
  }
  
  if (!sepayConfig.webhookSecret) {
    errors.push('SEPAY_WEBHOOK_SECRET is not set');
  }
  
  return {
    valid: errors.length === 0,
    errors,
  };
};

