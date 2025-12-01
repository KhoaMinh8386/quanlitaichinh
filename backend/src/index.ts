import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/env';
import { errorHandler } from './middlewares/errorHandler';
import { logger } from './utils/logger';
import authRoutes from './routes/auth.routes';
import transactionRoutes from './routes/transaction.routes';
import budgetRoutes from './routes/budget.routes';
import categoryRoutes from './routes/category.routes';
import reportRoutes from './routes/report.routes';
import categorizationRoutes from './routes/categorization.routes';
import forecastRoutes from './routes/forecast.routes';
import alertRoutes from './routes/alert.routes';
import sepayRoutes from './routes/sepay.routes';
import analyticsRoutes from './routes/analytics.routes';
import googleSheetsRoutes from './routes/googleSheets.routes';

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
}

// Health check (both with and without /api prefix for compatibility)
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/categorization', categorizationRoutes);
app.use('/api/forecast', forecastRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/sepay', sepayRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/google-sheets', googleSheetsRoutes);
// app.use('/api/banks', bankRoutes);

// Error handling
app.use(errorHandler);

// Start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  const PORT = config.port;
  app.listen(PORT, () => {
    logger.info(`Server running on port ${PORT} in ${config.nodeEnv} mode`);
  });
}

export default app;
