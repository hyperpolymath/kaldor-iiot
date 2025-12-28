// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Authentication routes
 * Login, logout, token refresh
 */

import { Router } from 'oak'
import { hash, compare } from 'bcrypt'
import { generateToken, AuthPayload } from '../middleware/auth.ts'
import { logger } from '../services/logger.ts'

const router = new Router()

// POST /api/v2/auth/register
router.post('/register', async (ctx) => {
  const body = await ctx.request.body({ type: 'json' }).value
  const { username, password, email } = body

  if (!username || !password) {
    ctx.response.status = 400
    ctx.response.body = { error: 'Username and password required' }
    return
  }

  try {
    // Hash password
    const passwordHash = await hash(password)

    // In production: Store in database
    // const user = await db.query(...)

    // For now, simulated user creation
    const userId = `user-${Date.now().toString(36)}`

    logger.info('User registered', { userId, username })

    ctx.response.body = {
      success: true,
      userId,
      message: 'User registered successfully',
    }
  } catch (error) {
    logger.error('Registration failed', { error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Registration failed' }
  }
})

// POST /api/v2/auth/login
router.post('/login', async (ctx) => {
  const body = await ctx.request.body({ type: 'json' }).value
  const { username, password } = body

  if (!username || !password) {
    ctx.response.status = 400
    ctx.response.body = { error: 'Username and password required' }
    return
  }

  try {
    // In production: Fetch user from database
    // const user = await db.queryOne('SELECT * FROM users WHERE username = $1', [username])

    // Simulated user lookup
    const user = {
      id: 'user-demo',
      username,
      passwordHash: await hash(password), // Simulated - would come from DB
      roles: ['user'],
      perimeter: 3 as const, // TPCF Perimeter 3 (Community)
    }

    // Verify password
    const valid = await compare(password, user.passwordHash)

    if (!valid) {
      ctx.response.status = 401
      ctx.response.body = { error: 'Invalid credentials' }
      return
    }

    // Generate JWT
    const payload: AuthPayload = {
      userId: user.id,
      username: user.username,
      roles: user.roles,
      perimeter: user.perimeter,
    }

    const token = await generateToken(payload)

    logger.info('User logged in', { userId: user.id, username })

    ctx.response.body = {
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        roles: user.roles,
        perimeter: user.perimeter,
      },
    }
  } catch (error) {
    logger.error('Login failed', { error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Login failed' }
  }
})

// POST /api/v2/auth/logout
router.post('/logout', async (ctx) => {
  // In production: Invalidate session in Redis
  // const auth = ctx.state.auth as AuthPayload
  // await redis.deleteSession(auth.userId)

  logger.info('User logged out')

  ctx.response.body = {
    success: true,
    message: 'Logged out successfully',
  }
})

// GET /api/v2/auth/me
router.get('/me', async (ctx) => {
  const auth = ctx.state.auth as AuthPayload | undefined

  if (!auth) {
    ctx.response.status = 401
    ctx.response.body = { error: 'Not authenticated' }
    return
  }

  ctx.response.body = {
    user: auth,
  }
})

export default router
