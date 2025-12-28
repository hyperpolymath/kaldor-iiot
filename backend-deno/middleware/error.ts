// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Error handling middleware
 * Catches and formats errors for API responses
 */

import { Context, Next, isHttpError } from 'oak'
import { logger } from '../services/logger.ts'

export async function errorHandler(ctx: Context, next: Next) {
  try {
    await next()
  } catch (error) {
    // Log the error
    logger.error('Request error', {
      method: ctx.request.method,
      url: ctx.request.url.pathname,
      error: error.message,
      stack: error.stack,
    })

    // Handle HTTP errors (thrown by Oak)
    if (isHttpError(error)) {
      ctx.response.status = error.status
      ctx.response.body = {
        error: error.name,
        message: error.message,
      }
      return
    }

    // Handle validation errors
    if (error.name === 'ValidationError') {
      ctx.response.status = 400
      ctx.response.body = {
        error: 'Validation Error',
        message: error.message,
        details: error.details || [],
      }
      return
    }

    // Handle database errors
    if (error.name === 'PostgresError') {
      ctx.response.status = 500
      ctx.response.body = {
        error: 'Database Error',
        message: 'A database error occurred',
        code: error.code,
      }
      return
    }

    // Generic server error
    ctx.response.status = 500
    ctx.response.body = {
      error: 'Internal Server Error',
      message: Deno.env.get('NODE_ENV') === 'production'
        ? 'An unexpected error occurred'
        : error.message,
    }
  }
}

export default errorHandler
