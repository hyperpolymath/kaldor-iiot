// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Job queue routes
 * Manage manufacturing jobs (spinning, weaving, printing)
 */

import { Router } from 'oak'
import { logger } from '../services/logger.ts'

const router = new Router()

const jobs = new Map()

router.get('/', (ctx) => {
  ctx.response.body = { jobs: Array.from(jobs.values()) }
})

router.post('/', async (ctx) => {
  const body = await ctx.request.body({ type: 'json' }).value
  const jobId = `job-${Date.now().toString(36)}`

  const job = {
    id: jobId,
    ...body,
    status: 'queued',
    createdAt: new Date().toISOString(),
  }

  jobs.set(jobId, job)
  logger.info('Job created', { jobId })

  ctx.response.status = 201
  ctx.response.body = job
})

export default router
