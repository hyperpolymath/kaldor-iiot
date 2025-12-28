// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Matter protocol bridge service
 * Manages ESP32-C6 devices using Matter 1.2+ over Thread/WiFi
 *
 * Note: This is a simplified implementation. Production would use
 * official Matter SDK (chip-tool) via subprocess or native bindings.
 */

import { logger } from './logger.ts'

export interface MatterDevice {
  id: string
  name: string
  vendorId: number
  productId: number
  commissioned: boolean
  online: boolean
  lastSeen: Date
  capabilities: string[]
  nodeId?: bigint
}

export class MatterBridge {
  private port: string
  private devices: Map<string, MatterDevice> = new Map()
  private isRunningFlag = false
  private fabricId: bigint = 1n // Fabric ID for this network

  constructor(port: string) {
    this.port = port
  }

  async start(): Promise<void> {
    try {
      // In production, this would initialize the Matter SDK
      // For now, we'll simulate the bridge starting

      this.isRunningFlag = true
      logger.info('Matter bridge started', {
        port: this.port,
        fabricId: this.fabricId.toString(),
        protocol: 'Matter 1.2+',
        transport: 'Thread/WiFi',
      })

      // Start discovery listener (simulated)
      this.startDiscovery()
    } catch (error) {
      logger.error('Failed to start Matter bridge', { error })
      throw error
    }
  }

  async stop(): Promise<void> {
    this.isRunningFlag = false
    logger.info('Matter bridge stopped')
  }

  isRunning(): boolean {
    return this.isRunningFlag
  }

  private startDiscovery(): void {
    // In production: Listen for mDNS advertisements from Matter devices
    // This would use the Matter SDK's discovery mechanisms

    logger.debug('Matter device discovery started')

    // Simulated device heartbeat check
    setInterval(() => {
      this.checkDeviceHeartbeats()
    }, 30000) // Every 30 seconds
  }

  private checkDeviceHeartbeats(): void {
    const now = new Date()
    this.devices.forEach((device) => {
      const timeSinceLastSeen = now.getTime() - device.lastSeen.getTime()
      if (timeSinceLastSeen > 60000) {
        // 1 minute timeout
        if (device.online) {
          device.online = false
          logger.warn('Matter device went offline', { deviceId: device.id })
        }
      }
    })
  }

  // Commission a new Matter device
  async commissionDevice(setupCode: string): Promise<{ success: boolean; deviceId?: string }> {
    try {
      // In production: Execute commissioning via Matter SDK
      // 1. Parse setup payload (QR code or manual pairing code)
      // 2. Establish PASE session
      // 3. Commission device to fabric
      // 4. Store device credentials

      logger.info('Commissioning Matter device', { setupCode: '***' })

      // Simulated commissioning
      const deviceId = `matter-${Date.now().toString(36)}`
      const device: MatterDevice = {
        id: deviceId,
        name: 'ESP32-C6 Loom Controller',
        vendorId: 0xfff1, // Test vendor ID
        productId: 0x8000,
        commissioned: true,
        online: true,
        lastSeen: new Date(),
        capabilities: ['temperature', 'vibration', 'loom-control'],
        nodeId: BigInt(this.devices.size + 1),
      }

      this.devices.set(deviceId, device)

      logger.info('Matter device commissioned', {
        deviceId,
        nodeId: device.nodeId?.toString(),
      })

      return { success: true, deviceId }
    } catch (error) {
      logger.error('Matter commissioning failed', { error })
      return { success: false }
    }
  }

  // Get all devices
  getDevices(): MatterDevice[] {
    return Array.from(this.devices.values())
  }

  // Get specific device
  getDevice(deviceId: string): MatterDevice | undefined {
    return this.devices.get(deviceId)
  }

  // Send command to Matter device
  async sendCommand(
    deviceId: string,
    clusterId: number,
    commandId: number,
    payload: unknown
  ): Promise<{ success: boolean; response?: unknown }> {
    const device = this.devices.get(deviceId)

    if (!device) {
      logger.error('Device not found', { deviceId })
      return { success: false }
    }

    if (!device.online) {
      logger.error('Device offline', { deviceId })
      return { success: false }
    }

    try {
      // In production: Send Matter command via SDK
      // Uses Interaction Model Protocol (IMP)

      logger.debug('Sending Matter command', {
        deviceId,
        clusterId: `0x${clusterId.toString(16)}`,
        commandId: `0x${commandId.toString(16)}`,
      })

      // Simulated response
      device.lastSeen = new Date()

      return {
        success: true,
        response: { status: 'ok', timestamp: Date.now() },
      }
    } catch (error) {
      logger.error('Matter command failed', { deviceId, error })
      return { success: false }
    }
  }

  // Read attribute from Matter device
  async readAttribute(
    deviceId: string,
    clusterId: number,
    attributeId: number
  ): Promise<{ success: boolean; value?: unknown }> {
    const device = this.devices.get(deviceId)

    if (!device) {
      return { success: false }
    }

    try {
      // In production: Read attribute via Matter SDK
      logger.debug('Reading Matter attribute', {
        deviceId,
        clusterId: `0x${clusterId.toString(16)}`,
        attributeId: `0x${attributeId.toString(16)}`,
      })

      device.lastSeen = new Date()

      // Simulated values based on common clusters
      const value = this.simulateAttributeRead(clusterId, attributeId)

      return { success: true, value }
    } catch (error) {
      logger.error('Matter attribute read failed', { deviceId, error })
      return { success: false }
    }
  }

  private simulateAttributeRead(clusterId: number, attributeId: number): unknown {
    // Simulate common Matter cluster attributes
    switch (clusterId) {
      case 0x0028: // Basic Information Cluster
        if (attributeId === 0x0005) return 'Kaldor Loom v1.0' // NodeLabel
        break
      case 0x0402: // Temperature Measurement Cluster
        if (attributeId === 0x0000) return 2150 // 21.5°C (scaled by 100)
        break
      case 0x0406: // Occupancy Sensing Cluster
        if (attributeId === 0x0000) return 1 // Occupied
        break
    }
    return null
  }

  // Subscribe to attribute changes
  async subscribeAttribute(
    deviceId: string,
    clusterId: number,
    attributeId: number,
    callback: (value: unknown) => void
  ): Promise<{ success: boolean }> {
    // In production: Set up Matter subscription via SDK
    // Subscriptions use the Report mechanism in the Interaction Model

    logger.info('Matter attribute subscription created', {
      deviceId,
      clusterId: `0x${clusterId.toString(16)}`,
      attributeId: `0x${attributeId.toString(16)}`,
    })

    // Simulated periodic updates
    const interval = setInterval(async () => {
      const result = await this.readAttribute(deviceId, clusterId, attributeId)
      if (result.success && result.value !== undefined) {
        callback(result.value)
      }
    }, 5000) // Every 5 seconds

    // Store interval for cleanup (production would track subscriptions properly)
    return { success: true }
  }

  // Decommission device
  async decommissionDevice(deviceId: string): Promise<{ success: boolean }> {
    const device = this.devices.get(deviceId)

    if (!device) {
      return { success: false }
    }

    try {
      // In production: Remove device from fabric via Matter SDK
      this.devices.delete(deviceId)

      logger.info('Matter device decommissioned', { deviceId })
      return { success: true }
    } catch (error) {
      logger.error('Matter decommissioning failed', { deviceId, error })
      return { success: false }
    }
  }

  // Get fabric information
  getFabricInfo() {
    return {
      fabricId: this.fabricId.toString(),
      deviceCount: this.devices.size,
      onlineDevices: Array.from(this.devices.values()).filter((d) => d.online).length,
    }
  }
}

export default MatterBridge
