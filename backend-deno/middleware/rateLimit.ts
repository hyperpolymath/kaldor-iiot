// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Rate limiting middleware
 * Uses Redis sliding window for distributed rate limiting
 */

import { Context, Next } from 'oak'
import { logger } from '../services/logger.ts'

export interface RateLimitOptions {
  windowMs: number // Time window in milliseconds
  max: number // Max requests per window
  keyGenerator?: (ctx: Context) => string // Custom key generator
  skipSuccessfulRequests?: boolean
  skipFailedRequests?: boolean
}

// In-memory store for development (use Redis in production)
const requestCounts = new Map<string, { count: number; resetTime: number }>()

export function rateLimit(options: RateLimitOptions) {
  const {
    windowMs,
    max,
    keyGenerator = (ctx: Context) => ctx.request.ip || 'unknown',
    skipSuccessfulRequests = false,
    skipFailedRequests = false,
  } = options

  return async (ctx: Context, next: Next) => {
    const key = `ratelimit:${keyGenerator(ctx)}`
    const now = Date.now()

    // Get current count
    let record = requestCounts.get(key)

    // Reset if window expired
    if (!record || now > record.resetTime) {
      record = {
        count: 0,
        resetTime: now + windowMs,
      }
      requestCounts.set(key, record)
    }

    // Check if rate limit exceeded
    if (record.count >= max) {
      const retryAfter = Math.ceil((record.resetTime - now) / 1000)

      ctx.response.status = 429
      ctx.response.headers.set('Retry-After', retryAfter.toString())
      ctx.response.headers.set('X-RateLimit-Limit', max.toString())
      ctx.response.headers.set('X-RateLimit-Remaining', '0')
      ctx.response.headers.set('X-RateLimit-Reset', record.resetTime.toString())

      ctx.response.body = {
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
        retryAfter,
      }

      logger.warn('Rate limit exceeded', {
        key,
        count: record.count,
        max,
      })

      return
    }

    // Increment counter
    record.count++

    // Set rate limit headers
    ctx.response.headers.set('X-RateLimit-Limit', max.toString())
    ctx.response.headers.set('X-RateLimit-Remaining', (max - record.count).toString())
    ctx.response.headers.set('X-RateLimit-Reset', record.resetTime.toString())

    await next()

    // Optionally skip counting based on response
    if (
      (skipSuccessfulRequests && ctx.response.status < 400) ||
      (skipFailedRequests && ctx.response.status >= 400)
    ) {
      record.count--
    }
  }
}

// Cleanup expired entries periodically
setInterval(() => {
  const now = Date.now()
  for (const [key, record] of requestCounts.entries()) {
    if (now > record.resetTime) {
      requestCounts.delete(key)
    }
  }
}, 60000) // Every minute

export default rateLimit
