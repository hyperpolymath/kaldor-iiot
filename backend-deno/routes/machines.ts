// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Device/machine routes
 * Manage IoT devices (looms, spinners, 3D printers)
 */

import { Router } from 'oak'
import { logger } from '../services/logger.ts'

const router = new Router()

// Simulated device storage (production would use database)
const devices = new Map()

// GET /api/v2/machines
router.get('/', async (ctx) => {
  try {
    const deviceList = Array.from(devices.values())

    ctx.response.body = {
      devices: deviceList,
      count: deviceList.length,
    }
  } catch (error) {
    logger.error('Failed to list devices', { error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Failed to list devices' }
  }
})

// GET /api/v2/machines/:id
router.get('/:id', async (ctx) => {
  const { id } = ctx.params

  const device = devices.get(id)

  if (!device) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Device not found' }
    return
  }

  ctx.response.body = device
})

// POST /api/v2/machines
router.post('/', async (ctx) => {
  try {
    const body = await ctx.request.body({ type: 'json' }).value
    const { name, type, location } = body

    if (!name || !type) {
      ctx.response.status = 400
      ctx.response.body = { error: 'Name and type required' }
      return
    }

    const deviceId = `device-${Date.now().toString(36)}`
    const device = {
      id: deviceId,
      name,
      type, // 'loom', 'spinner', '3d-printer'
      location,
      status: 'offline',
      commissioned: false,
      createdAt: new Date().toISOString(),
      metrics: {
        temperature: null,
        vibration: null,
        uptime: 0,
      },
    }

    devices.set(deviceId, device)

    logger.info('Device created', { deviceId, name, type })

    ctx.response.status = 201
    ctx.response.body = device
  } catch (error) {
    logger.error('Failed to create device', { error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Failed to create device' }
  }
})

// PUT /api/v2/machines/:id
router.put('/:id', async (ctx) => {
  const { id } = ctx.params

  const device = devices.get(id)

  if (!device) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Device not found' }
    return
  }

  try {
    const body = await ctx.request.body({ type: 'json' }).value

    // Update fields
    Object.assign(device, body, { updatedAt: new Date().toISOString() })

    devices.set(id, device)

    logger.info('Device updated', { deviceId: id })

    ctx.response.body = device
  } catch (error) {
    logger.error('Failed to update device', { deviceId: id, error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Failed to update device' }
  }
})

// DELETE /api/v2/machines/:id
router.delete('/:id', async (ctx) => {
  const { id } = ctx.params

  if (!devices.has(id)) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Device not found' }
    return
  }

  devices.delete(id)

  logger.info('Device deleted', { deviceId: id })

  ctx.response.body = {
    success: true,
    message: 'Device deleted',
  }
})

// GET /api/v2/machines/:id/metrics
router.get('/:id/metrics', async (ctx) => {
  const { id } = ctx.params

  const device = devices.get(id)

  if (!device) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Device not found' }
    return
  }

  // In production: Query TimescaleDB for time-series data
  // const metrics = await db.query(`
  //   SELECT * FROM device_metrics
  //   WHERE device_id = $1
  //   ORDER BY timestamp DESC
  //   LIMIT 100
  // `, [id])

  ctx.response.body = {
    deviceId: id,
    current: device.metrics,
    history: [], // Would come from TimescaleDB
  }
})

// POST /api/v2/machines/:id/command
router.post('/:id/command', async (ctx) => {
  const { id } = ctx.params

  const device = devices.get(id)

  if (!device) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Device not found' }
    return
  }

  try {
    const body = await ctx.request.body({ type: 'json' }).value
    const { command, params } = body

    if (!command) {
      ctx.response.status = 400
      ctx.response.body = { error: 'Command required' }
      return
    }

    // In production: Send command via MQTT
    // await mqtt.publishDeviceCommand(id, command, params)

    logger.info('Device command sent', { deviceId: id, command })

    ctx.response.body = {
      success: true,
      message: `Command '${command}' sent to device`,
      timestamp: Date.now(),
    }
  } catch (error) {
    logger.error('Failed to send device command', { deviceId: id, error })
    ctx.response.status = 500
    ctx.response.body = { error: 'Failed to send command' }
  }
})

export default router
