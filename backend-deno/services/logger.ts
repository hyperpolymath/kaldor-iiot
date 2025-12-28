// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Structured logging service for Kaldor IIoT
 * Provides leveled logging with timestamps and context
 */

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

interface LogContext {
  [key: string]: unknown
}

class Logger {
  private minLevel: LogLevel
  private context: LogContext

  constructor(minLevel: LogLevel = LogLevel.INFO, context: LogContext = {}) {
    this.minLevel = minLevel
    this.context = context
  }

  private log(level: LogLevel, message: string, meta: LogContext = {}) {
    if (level < this.minLevel) return

    const timestamp = new Date().toISOString()
    const levelName = LogLevel[level]
    const mergedContext = { ...this.context, ...meta }

    const logEntry = {
      timestamp,
      level: levelName,
      message,
      ...mergedContext,
    }

    const output = JSON.stringify(logEntry)

    if (level >= LogLevel.ERROR) {
      console.error(output)
    } else if (level === LogLevel.WARN) {
      console.warn(output)
    } else {
      console.log(output)
    }
  }

  debug(message: string, meta?: LogContext) {
    this.log(LogLevel.DEBUG, message, meta)
  }

  info(message: string, meta?: LogContext) {
    this.log(LogLevel.INFO, message, meta)
  }

  warn(message: string, meta?: LogContext) {
    this.log(LogLevel.WARN, message, meta)
  }

  error(message: string, meta?: LogContext) {
    this.log(LogLevel.ERROR, message, meta)
  }

  fatal(message: string, meta?: LogContext) {
    this.log(LogLevel.FATAL, message, meta)
  }

  child(context: LogContext): Logger {
    return new Logger(this.minLevel, { ...this.context, ...context })
  }
}

// Default logger instance
export const logger = new Logger(
  Deno.env.get('LOG_LEVEL') === 'DEBUG' ? LogLevel.DEBUG : LogLevel.INFO,
  { service: 'kaldor-iiot' }
)

export default Logger
