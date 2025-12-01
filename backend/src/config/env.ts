import dotenv from 'dotenv';

dotenv.config();

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL || '',
  jwt: {
    secret: process.env.JWT_SECRET || '',
    refreshSecret: process.env.JWT_REFRESH_SECRET || '',
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  encryption: {
    key: process.env.ENCRYPTION_KEY || '',
  },
  bankApi: {
    baseUrl: process.env.BANK_API_BASE_URL || '',
    clientId: process.env.BANK_CLIENT_ID || '',
    clientSecret: process.env.BANK_CLIENT_SECRET || '',
    redirectUri: process.env.OAUTH_REDIRECT_URI || '',
  },
  logLevel: process.env.LOG_LEVEL || 'info',
  // Webhook URL configuration
  webhookUrl: process.env.WEBHOOK_URL || process.env.RENDER_EXTERNAL_URL || '',
};
