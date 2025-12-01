import { config } from '../config/env';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const levels: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLevel = levels[config.logLevel as LogLevel] || levels.info;

function log(level: LogLevel, message: string, meta?: any): void {
  if (levels[level] >= currentLevel) {
    const timestamp = new Date().toISOString();
    const logMessage = {
      timestamp,
      level,
      message,
      ...(meta && { meta }),
    };
    console.log(JSON.stringify(logMessage));
  }
}

export const logger = {
  debug: (message: string, meta?: any) => log('debug', message, meta),
  info: (message: string, meta?: any) => log('info', message, meta),
  warn: (message: string, meta?: any) => log('warn', message, meta),
  error: (message: string, meta?: any) => log('error', message, meta),
};
