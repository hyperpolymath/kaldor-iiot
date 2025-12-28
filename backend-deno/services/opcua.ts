// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * OPC UA server service for SCADA/DCS interoperability
 * Exposes device data via OPC UA (IEC 62541) for industrial systems
 *
 * Note: Production implementation would use node-opcua or similar.
 * This is a simplified interface showing the integration pattern.
 */

import { logger } from './logger.ts'

export interface OPCUANode {
  nodeId: string
  browseName: string
  value: unknown
  dataType: string
  accessLevel: 'read' | 'write' | 'readwrite'
}

export class OPCUAServer {
  private port: string
  private isRunningFlag = false
  private nodes: Map<string, OPCUANode> = new Map()
  private namespaceUri = 'http://kaldor.community/manufacturing/'
  private namespaceIndex = 2 // 0=OPC UA, 1=local, 2=custom

  constructor(port: string) {
    this.port = port
  }

  async start(): Promise<void> {
    try {
      // In production: Initialize OPC UA server with node-opcua
      // const server = new OPCUAServer({
      //   port: parseInt(this.port),
      //   resourcePath: '/UA/KaldorServer',
      //   buildInfo: { ... }
      // })

      this.isRunningFlag = true

      // Initialize address space with standard nodes
      this.initializeAddressSpace()

      logger.info('OPC UA server started', {
        port: this.port,
        endpoint: `opc.tcp://localhost:${this.port}`,
        namespace: this.namespaceUri,
        securityMode: 'SignAndEncrypt',
      })
    } catch (error) {
      logger.error('Failed to start OPC UA server', { error })
      throw error
    }
  }

  async stop(): Promise<void> {
    // In production: await server.shutdown()
    this.isRunningFlag = false
    logger.info('OPC UA server stopped')
  }

  isRunning(): boolean {
    return this.isRunningFlag
  }

  private initializeAddressSpace(): void {
    // Create standard OPC UA object structure
    // Objects/
    //   └─ Devices/
    //       ├─ Loom001/
    //       │   ├─ Temperature
    //       │   ├─ Vibration
    //       │   └─ Status
    //       └─ Loom002/...

    this.addNode({
      nodeId: `ns=${this.namespaceIndex};s=Devices`,
      browseName: 'Devices',
      value: {},
      dataType: 'Object',
      accessLevel: 'read',
    })

    logger.debug('OPC UA address space initialized')
  }

  // Add device to address space
  addDevice(deviceId: string, deviceInfo: { name: string; type: string }): void {
    const deviceNodeId = `ns=${this.namespaceIndex};s=Devices.${deviceId}`

    this.addNode({
      nodeId: deviceNodeId,
      browseName: deviceInfo.name,
      value: { type: deviceInfo.type, id: deviceId },
      dataType: 'Object',
      accessLevel: 'read',
    })

    // Add standard variables for devices
    this.addNode({
      nodeId: `${deviceNodeId}.Status`,
      browseName: 'Status',
      value: 'Online',
      dataType: 'String',
      accessLevel: 'read',
    })

    this.addNode({
      nodeId: `${deviceNodeId}.Temperature`,
      browseName: 'Temperature',
      value: 0,
      dataType: 'Double',
      accessLevel: 'read',
    })

    this.addNode({
      nodeId: `${deviceNodeId}.Vibration`,
      browseName: 'Vibration',
      value: 0,
      dataType: 'Double',
      accessLevel: 'read',
    })

    logger.info('OPC UA device added', { deviceId, nodeId: deviceNodeId })
  }

  // Remove device from address space
  removeDevice(deviceId: string): void {
    const deviceNodeId = `ns=${this.namespaceIndex};s=Devices.${deviceId}`

    // Remove device and all child nodes
    const nodesToRemove = Array.from(this.nodes.keys()).filter((nodeId) =>
      nodeId.startsWith(deviceNodeId)
    )

    nodesToRemove.forEach((nodeId) => this.nodes.delete(nodeId))

    logger.info('OPC UA device removed', { deviceId })
  }

  // Add or update node
  addNode(node: OPCUANode): void {
    this.nodes.set(node.nodeId, node)
  }

  // Update node value
  updateNodeValue(nodeId: string, value: unknown): void {
    const node = this.nodes.get(nodeId)
    if (node) {
      node.value = value
      logger.debug('OPC UA node updated', { nodeId, value })
    } else {
      logger.warn('OPC UA node not found', { nodeId })
    }
  }

  // Read node value
  readNode(nodeId: string): OPCUANode | undefined {
    return this.nodes.get(nodeId)
  }

  // Browse nodes (get children)
  browseNode(nodeId: string): OPCUANode[] {
    const prefix = nodeId.endsWith('.') ? nodeId : `${nodeId}.`
    return Array.from(this.nodes.values()).filter(
      (node) => node.nodeId.startsWith(prefix) && !node.nodeId.substring(prefix.length).includes('.')
    )
  }

  // Update device metrics (called from telemetry handler)
  updateDeviceMetrics(deviceId: string, metrics: { temperature?: number; vibration?: number; status?: string }): void {
    const devicePrefix = `ns=${this.namespaceIndex};s=Devices.${deviceId}`

    if (metrics.temperature !== undefined) {
      this.updateNodeValue(`${devicePrefix}.Temperature`, metrics.temperature)
    }

    if (metrics.vibration !== undefined) {
      this.updateNodeValue(`${devicePrefix}.Vibration`, metrics.vibration)
    }

    if (metrics.status !== undefined) {
      this.updateNodeValue(`${devicePrefix}.Status`, metrics.status)
    }
  }

  // Get server info for API endpoint
  getServerInfo() {
    return {
      endpoint: `opc.tcp://localhost:${this.port}`,
      namespace: this.namespaceUri,
      namespaceIndex: this.namespaceIndex,
      securityMode: 'SignAndEncrypt',
      securityPolicy: 'Basic256Sha256',
      authentication: ['Anonymous', 'UserNamePassword'],
      nodeCount: this.nodes.size,
    }
  }

  // Get all nodes (for debugging)
  getAllNodes(): OPCUANode[] {
    return Array.from(this.nodes.values())
  }
}

export default OPCUAServer
