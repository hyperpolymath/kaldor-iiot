// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Redis service for caching and pub/sub
 * Supports real-time updates and session management
 */

import { connect, Redis } from 'redis'
import { logger } from './logger.ts'

export class RedisClient {
  private client: Redis | null = null
  private connectionUrl: string
  private isConnectedFlag = false
  private subscribers: Map<string, Set<(message: string) => void>> = new Map()

  constructor(connectionUrl: string) {
    this.connectionUrl = connectionUrl
  }

  async connect(): Promise<void> {
    try {
      this.client = await connect({ hostname: this.parseHostname(), port: this.parsePort() })
      this.isConnectedFlag = true
      logger.info('Redis connected', { url: this.connectionUrl })
    } catch (error) {
      logger.error('Failed to connect to Redis', { error })
      throw error
    }
  }

  async disconnect(): Promise<void> {
    if (this.client) {
      this.client.close()
      this.isConnectedFlag = false
      logger.info('Redis disconnected')
    }
  }

  isConnected(): boolean {
    return this.isConnectedFlag
  }

  private parseHostname(): string {
    const url = new URL(this.connectionUrl)
    return url.hostname || 'localhost'
  }

  private parsePort(): number {
    const url = new URL(this.connectionUrl)
    return url.port ? parseInt(url.port) : 6379
  }

  private getClient(): Redis {
    if (!this.client) {
      throw new Error('Redis not connected')
    }
    return this.client
  }

  // Cache operations
  async get(key: string): Promise<string | null> {
    const client = this.getClient()
    return await client.get(key)
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    const client = this.getClient()
    if (ttlSeconds) {
      await client.setex(key, ttlSeconds, value)
    } else {
      await client.set(key, value)
    }
  }

  async del(key: string): Promise<void> {
    const client = this.getClient()
    await client.del(key)
  }

  async exists(key: string): Promise<boolean> {
    const client = this.getClient()
    const result = await client.exists(key)
    return result === 1
  }

  // JSON helpers
  async getJSON<T>(key: string): Promise<T | null> {
    const value = await this.get(key)
    return value ? JSON.parse(value) : null
  }

  async setJSON<T>(key: string, value: T, ttlSeconds?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttlSeconds)
  }

  // Pub/Sub
  async publish(channel: string, message: string): Promise<void> {
    const client = this.getClient()
    await client.publish(channel, message)
    logger.debug('Published to channel', { channel, messageLength: message.length })
  }

  async publishJSON<T>(channel: string, data: T): Promise<void> {
    await this.publish(channel, JSON.stringify(data))
  }

  async subscribe(channel: string, callback: (message: string) => void): Promise<void> {
    if (!this.subscribers.has(channel)) {
      this.subscribers.set(channel, new Set())

      // Create dedicated subscriber connection
      const subscriber = await connect({
        hostname: this.parseHostname(),
        port: this.parsePort(),
      })

      await subscriber.subscribe(channel, (message) => {
        const callbacks = this.subscribers.get(channel)
        if (callbacks) {
          callbacks.forEach((cb) => cb(message))
        }
      })

      logger.info('Subscribed to Redis channel', { channel })
    }

    this.subscribers.get(channel)!.add(callback)
  }

  async unsubscribe(channel: string, callback: (message: string) => void): Promise<void> {
    const callbacks = this.subscribers.get(channel)
    if (callbacks) {
      callbacks.delete(callback)
      if (callbacks.size === 0) {
        this.subscribers.delete(channel)
        logger.info('Unsubscribed from Redis channel', { channel })
      }
    }
  }

  // Session management
  async setSession(sessionId: string, data: unknown, ttlSeconds: number = 3600): Promise<void> {
    await this.setJSON(`session:${sessionId}`, data, ttlSeconds)
  }

  async getSession<T>(sessionId: string): Promise<T | null> {
    return await this.getJSON<T>(`session:${sessionId}`)
  }

  async deleteSession(sessionId: string): Promise<void> {
    await this.del(`session:${sessionId}`)
  }

  // Rate limiting
  async checkRateLimit(
    key: string,
    maxRequests: number,
    windowSeconds: number
  ): Promise<{ allowed: boolean; remaining: number }> {
    const client = this.getClient()
    const now = Date.now()
    const windowStart = now - windowSeconds * 1000

    const rateLimitKey = `ratelimit:${key}`

    // Remove old entries
    await client.zremrangebyscore(rateLimitKey, '-inf', windowStart.toString())

    // Count requests in current window
    const count = await client.zcard(rateLimitKey)

    if (count >= maxRequests) {
      return { allowed: false, remaining: 0 }
    }

    // Add current request
    await client.zadd(rateLimitKey, now, `${now}`)
    await client.expire(rateLimitKey, windowSeconds)

    return { allowed: true, remaining: maxRequests - count - 1 }
  }
}

export default RedisClient
