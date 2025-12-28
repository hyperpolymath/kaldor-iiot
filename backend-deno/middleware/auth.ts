// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Authentication middleware
 * JWT-based authentication with Redis session storage
 */

import { Context, Next } from 'oak'
import { create, verify, getNumericDate } from 'jose'
import { logger } from '../services/logger.ts'

const JWT_SECRET = new TextEncoder().encode(
  Deno.env.get('JWT_SECRET') || 'kaldor-secret-change-in-production'
)

const JWT_ALGORITHM = 'HS256'

export interface AuthPayload {
  userId: string
  username: string
  roles: string[]
  perimeter: 1 | 2 | 3 // TPCF perimeter
}

// Generate JWT token
export async function generateToken(payload: AuthPayload): Promise<string> {
  const jwt = await create(
    { alg: JWT_ALGORITHM },
    {
      sub: payload.userId,
      username: payload.username,
      roles: payload.roles,
      perimeter: payload.perimeter,
      exp: getNumericDate(60 * 60 * 24), // 24 hours
      iat: getNumericDate(0),
    },
    JWT_SECRET
  )

  return jwt
}

// Verify JWT token
export async function verifyToken(token: string): Promise<AuthPayload | null> {
  try {
    const { payload } = await verify(token, JWT_SECRET)

    return {
      userId: payload.sub as string,
      username: payload.username as string,
      roles: payload.roles as string[],
      perimeter: payload.perimeter as 1 | 2 | 3,
    }
  } catch (error) {
    logger.warn('JWT verification failed', { error: error.message })
    return null
  }
}

// Authentication middleware
export async function authMiddleware(ctx: Context, next: Next) {
  const authHeader = ctx.request.headers.get('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    ctx.response.status = 401
    ctx.response.body = { error: 'Unauthorized', message: 'Missing or invalid authorization header' }
    return
  }

  const token = authHeader.substring(7) // Remove 'Bearer '
  const payload = await verifyToken(token)

  if (!payload) {
    ctx.response.status = 401
    ctx.response.body = { error: 'Unauthorized', message: 'Invalid or expired token' }
    return
  }

  // Attach auth payload to context state
  ctx.state.auth = payload

  await next()
}

// Role-based authorization middleware
export function requireRole(...roles: string[]) {
  return async (ctx: Context, next: Next) => {
    const auth = ctx.state.auth as AuthPayload | undefined

    if (!auth) {
      ctx.response.status = 401
      ctx.response.body = { error: 'Unauthorized', message: 'Authentication required' }
      return
    }

    const hasRole = roles.some((role) => auth.roles.includes(role))

    if (!hasRole) {
      ctx.response.status = 403
      ctx.response.body = {
        error: 'Forbidden',
        message: `Required roles: ${roles.join(', ')}`,
      }
      return
    }

    await next()
  }
}

// TPCF perimeter authorization
export function requirePerimeter(maxPerimeter: 1 | 2 | 3) {
  return async (ctx: Context, next: Next) => {
    const auth = ctx.state.auth as AuthPayload | undefined

    if (!auth) {
      ctx.response.status = 401
      ctx.response.body = { error: 'Unauthorized', message: 'Authentication required' }
      return
    }

    if (auth.perimeter > maxPerimeter) {
      ctx.response.status = 403
      ctx.response.body = {
        error: 'Forbidden',
        message: `Required perimeter: ${maxPerimeter} or lower (you have ${auth.perimeter})`,
      }
      return
    }

    await next()
  }
}

export default authMiddleware
