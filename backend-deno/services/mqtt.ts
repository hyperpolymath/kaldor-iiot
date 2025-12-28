// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * MQTT service for device telemetry and messaging
 * Handles pub/sub for ESP32-C6 devices and real-time updates
 */

import { MqttClient } from 'mqtt'
import { logger } from './logger.ts'

type MessageHandler = (topic: string, payload: Uint8Array) => void

export class MQTTService {
  private client: MqttClient | null = null
  private brokerUrl: string
  private isConnectedFlag = false
  private handlers: Map<string, Set<MessageHandler>> = new Map()

  constructor(brokerUrl: string) {
    this.brokerUrl = brokerUrl
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const url = new URL(this.brokerUrl)

        // Dynamic import for MQTT (Deno-compatible)
        import('mqtt').then(({ default: mqtt }) => {
          this.client = mqtt.connect(this.brokerUrl, {
            clientId: `kaldor-backend-${Date.now()}`,
            clean: true,
            reconnectPeriod: 5000,
            connectTimeout: 30000,
            username: url.username || undefined,
            password: url.password || undefined,
          })

          this.client.on('connect', () => {
            this.isConnectedFlag = true
            logger.info('MQTT connected', { broker: this.brokerUrl })
            resolve()
          })

          this.client.on('error', (error) => {
            logger.error('MQTT error', { error })
            reject(error)
          })

          this.client.on('message', (topic, payload) => {
            this.handleMessage(topic, payload)
          })

          this.client.on('offline', () => {
            this.isConnectedFlag = false
            logger.warn('MQTT offline')
          })

          this.client.on('reconnect', () => {
            logger.info('MQTT reconnecting...')
          })
        })
      } catch (error) {
        logger.error('Failed to connect to MQTT broker', { error })
        reject(error)
      }
    })
  }

  async disconnect(): Promise<void> {
    return new Promise((resolve) => {
      if (this.client) {
        this.client.end(false, {}, () => {
          this.isConnectedFlag = false
          logger.info('MQTT disconnected')
          resolve()
        })
      } else {
        resolve()
      }
    })
  }

  isConnected(): boolean {
    return this.isConnectedFlag
  }

  private getClient(): MqttClient {
    if (!this.client || !this.isConnectedFlag) {
      throw new Error('MQTT not connected')
    }
    return this.client
  }

  private handleMessage(topic: string, payload: Uint8Array): void {
    // Find matching handlers (support wildcards)
    this.handlers.forEach((handlerSet, pattern) => {
      if (this.topicMatches(pattern, topic)) {
        handlerSet.forEach((handler) => {
          try {
            handler(topic, payload)
          } catch (error) {
            logger.error('Error in MQTT message handler', { topic, error })
          }
        })
      }
    })
  }

  private topicMatches(pattern: string, topic: string): boolean {
    // Convert MQTT wildcards to regex
    // + matches single level, # matches multiple levels
    const regexPattern = pattern
      .replace(/\+/g, '[^/]+')
      .replace(/#/g, '.*')
      .replace(/\//g, '\\/')

    const regex = new RegExp(`^${regexPattern}$`)
    return regex.test(topic)
  }

  // Publish message
  async publish(topic: string, message: string | Uint8Array, qos: 0 | 1 | 2 = 0): Promise<void> {
    const client = this.getClient()

    return new Promise((resolve, reject) => {
      client.publish(topic, message, { qos }, (error) => {
        if (error) {
          logger.error('MQTT publish failed', { topic, error })
          reject(error)
        } else {
          logger.debug('MQTT published', { topic, size: message.length })
          resolve()
        }
      })
    })
  }

  // Publish JSON
  async publishJSON<T>(topic: string, data: T, qos: 0 | 1 | 2 = 0): Promise<void> {
    await this.publish(topic, JSON.stringify(data), qos)
  }

  // Subscribe to topic
  async subscribe(topic: string, handler: MessageHandler, qos: 0 | 1 | 2 = 0): Promise<void> {
    const client = this.getClient()

    return new Promise((resolve, reject) => {
      client.subscribe(topic, { qos }, (error) => {
        if (error) {
          logger.error('MQTT subscribe failed', { topic, error })
          reject(error)
        } else {
          if (!this.handlers.has(topic)) {
            this.handlers.set(topic, new Set())
          }
          this.handlers.get(topic)!.add(handler)

          logger.info('MQTT subscribed', { topic })
          resolve()
        }
      })
    })
  }

  // Subscribe to JSON messages
  async subscribeJSON<T>(
    topic: string,
    handler: (topic: string, data: T) => void,
    qos: 0 | 1 | 2 = 0
  ): Promise<void> {
    await this.subscribe(
      topic,
      (topic, payload) => {
        try {
          const text = new TextDecoder().decode(payload)
          const data = JSON.parse(text) as T
          handler(topic, data)
        } catch (error) {
          logger.error('Failed to parse MQTT JSON message', { topic, error })
        }
      },
      qos
    )
  }

  // Unsubscribe from topic
  async unsubscribe(topic: string, handler?: MessageHandler): Promise<void> {
    const client = this.getClient()

    if (handler) {
      const handlers = this.handlers.get(topic)
      if (handlers) {
        handlers.delete(handler)
        if (handlers.size === 0) {
          this.handlers.delete(topic)
          await this.unsubscribeFromBroker(topic)
        }
      }
    } else {
      this.handlers.delete(topic)
      await this.unsubscribeFromBroker(topic)
    }
  }

  private async unsubscribeFromBroker(topic: string): Promise<void> {
    const client = this.getClient()

    return new Promise((resolve, reject) => {
      client.unsubscribe(topic, (error) => {
        if (error) {
          logger.error('MQTT unsubscribe failed', { topic, error })
          reject(error)
        } else {
          logger.info('MQTT unsubscribed', { topic })
          resolve()
        }
      })
    })
  }

  // Device telemetry helpers
  async subscribeToDevice(deviceId: string, handler: (data: unknown) => void): Promise<void> {
    await this.subscribeJSON(`devices/${deviceId}/#`, (_topic, data) => {
      handler(data)
    })
  }

  async publishDeviceCommand(deviceId: string, command: string, params: unknown): Promise<void> {
    await this.publishJSON(`devices/${deviceId}/commands`, {
      command,
      params,
      timestamp: Date.now(),
    })
  }

  // System-wide broadcasts
  async broadcastEvent(event: string, data: unknown): Promise<void> {
    await this.publishJSON(`system/events/${event}`, {
      event,
      data,
      timestamp: Date.now(),
    })
  }
}

export default MQTTService
