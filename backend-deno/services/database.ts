// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * PostgreSQL + TimescaleDB database service
 * Manages connections and provides query interface
 */

import { Client } from 'postgres'
import { logger } from './logger.ts'

export class PostgresClient {
  private client: Client | null = null
  private connectionString: string
  private isConnectedFlag = false

  constructor(connectionString: string) {
    this.connectionString = connectionString
  }

  async connect(): Promise<void> {
    try {
      this.client = new Client(this.connectionString)
      await this.client.connect()
      this.isConnectedFlag = true

      // Verify TimescaleDB extension
      const result = await this.client.queryObject<{ installed: boolean }>`
        SELECT EXISTS(
          SELECT 1 FROM pg_extension WHERE extname = 'timescaledb'
        ) as installed
      `

      if (result.rows[0]?.installed) {
        logger.info('TimescaleDB extension verified')
      } else {
        logger.warn('TimescaleDB extension not found - install with CREATE EXTENSION timescaledb')
      }

      logger.info('PostgreSQL connected', {
        database: this.client.session.dbName,
      })
    } catch (error) {
      logger.error('Failed to connect to PostgreSQL', { error })
      throw error
    }
  }

  async disconnect(): Promise<void> {
    if (this.client) {
      await this.client.end()
      this.isConnectedFlag = false
      logger.info('PostgreSQL disconnected')
    }
  }

  isConnected(): boolean {
    return this.isConnectedFlag
  }

  getClient(): Client {
    if (!this.client) {
      throw new Error('Database not connected')
    }
    return this.client
  }

  // Query helpers
  async query<T>(sql: string, params?: unknown[]): Promise<T[]> {
    const client = this.getClient()
    const result = await client.queryObject<T>(sql, params)
    return result.rows
  }

  async queryOne<T>(sql: string, params?: unknown[]): Promise<T | null> {
    const rows = await this.query<T>(sql, params)
    return rows[0] ?? null
  }

  async execute(sql: string, params?: unknown[]): Promise<number> {
    const client = this.getClient()
    const result = await client.queryObject(sql, params)
    return result.rowCount ?? 0
  }

  // TimescaleDB-specific helpers
  async createHypertable(
    tableName: string,
    timeColumn: string = 'timestamp'
  ): Promise<void> {
    try {
      await this.execute(`
        SELECT create_hypertable(
          '${tableName}',
          '${timeColumn}',
          if_not_exists => TRUE
        )
      `)
      logger.info(`Hypertable created: ${tableName}`)
    } catch (error) {
      logger.error(`Failed to create hypertable: ${tableName}`, { error })
      throw error
    }
  }

  async setCompressionPolicy(
    tableName: string,
    compressAfter: string = '7 days'
  ): Promise<void> {
    try {
      await this.execute(`
        SELECT add_compression_policy('${tableName}', INTERVAL '${compressAfter}')
      `)
      logger.info(`Compression policy set: ${tableName} after ${compressAfter}`)
    } catch (error) {
      logger.error(`Failed to set compression policy: ${tableName}`, { error })
      throw error
    }
  }

  async setRetentionPolicy(
    tableName: string,
    retainFor: string = '90 days'
  ): Promise<void> {
    try {
      await this.execute(`
        SELECT add_retention_policy('${tableName}', INTERVAL '${retainFor}')
      `)
      logger.info(`Retention policy set: ${tableName} retain ${retainFor}`)
    } catch (error) {
      logger.error(`Failed to set retention policy: ${tableName}`, { error })
      throw error
    }
  }
}

export default PostgresClient
