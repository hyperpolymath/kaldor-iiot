// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Community routes
 * Network statistics, node discovery, community metrics
 */

import { Router } from 'oak'
import { logger } from '../services/logger.ts'

const router = new Router()

router.get('/stats', (ctx) => {
  ctx.response.body = {
    nodes: 12,
    activeDevices: 36,
    totalProduction: 450,
    communitySize: 25,
    kaldorCoefficient: 0.52, // Verdoorn coefficient
  }
})

router.get('/nodes', (ctx) => {
  ctx.response.body = {
    nodes: [
      { id: 'node-1', type: 'household', devices: 3, status: 'online' },
      { id: 'node-2', type: 'social-enterprise', devices: 9, status: 'online' },
    ],
  }
})

export default router
