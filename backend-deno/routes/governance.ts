// SPDX-License-Identifier: MIT OR Apache-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/**
 * Governance routes
 * CURP consensus, quadratic voting, proposals
 */

import { Router } from 'oak'
import { logger } from '../services/logger.ts'

const router = new Router()

const proposals = new Map()

router.get('/proposals', (ctx) => {
  ctx.response.body = { proposals: Array.from(proposals.values()) }
})

router.post('/proposals', async (ctx) => {
  const body = await ctx.request.body({ type: 'json' }).value
  const proposalId = `prop-${Date.now().toString(36)}`

  const proposal = {
    id: proposalId,
    ...body,
    votes: [],
    status: 'active',
    createdAt: new Date().toISOString(),
  }

  proposals.set(proposalId, proposal)
  logger.info('Proposal created', { proposalId })

  ctx.response.status = 201
  ctx.response.body = proposal
})

router.post('/proposals/:id/vote', async (ctx) => {
  const { id } = ctx.params
  const body = await ctx.request.body({ type: 'json' }).value

  const proposal = proposals.get(id)
  if (!proposal) {
    ctx.response.status = 404
    ctx.response.body = { error: 'Proposal not found' }
    return
  }

  proposal.votes.push({ ...body, timestamp: Date.now() })
  logger.info('Vote cast', { proposalId: id })

  ctx.response.body = proposal
})

export default router
