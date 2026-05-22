// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// WebSocket (Socket.io) client for real-time loom data.
// FIX: original TS had `subscribeTo Loom` (space) -- corrected to `subscribeToLoom`.
// Kept in JS because socket.io uses mutable module-level socket state.

import { io } from 'socket.io-client'
import { addAlert } from '../store/slices/alertsSlice.js'
import { updateRealTimeData } from '../store/slices/measurementsSlice.js'
import { updateLoomStatus } from '../store/slices/loomsSlice.js'
import { toast } from 'react-toastify'

let socket = null

export const connectWebSocket = (token, dispatch) => {
  socket = io('http://localhost:3000', {
    transports: ['websocket'],
  })

  socket.on('connect', () => {
    console.log('WebSocket connected')
    socket?.emit('authenticate', token)
  })

  socket.on('authenticated', (data) => {
    if (data.success) {
      console.log('WebSocket authenticated')
    } else {
      console.error('WebSocket authentication failed')
      socket?.disconnect()
    }
  })

  socket.on('measurement:update', (data) => {
    dispatch(updateRealTimeData({
      loomId: data.loom_id,
      data: {
        time: new Date().toISOString(),
        loom_id: data.loom_id,
        ...data.measurements,
      },
    }))
  })

  socket.on('alert:new', (data) => {
    dispatch(addAlert(data))
    toast.warning(`New alert: ${data.alert_type}`, {
      position: 'top-right',
      autoClose: 5000,
    })
  })

  socket.on('status:change', (data) => {
    dispatch(updateLoomStatus({
      id: data.loom_id,
      status: data.status,
    }))
  })

  socket.on('disconnect', () => {
    console.log('WebSocket disconnected')
  })

  socket.on('error', (error) => {
    console.error('WebSocket error:', error)
  })

  return socket
}

export const disconnectWebSocket = () => {
  if (socket) {
    socket.disconnect()
    socket = null
  }
}

export const subscribeToLoom = (loomId) => {
  socket?.emit('subscribe:loom', loomId)
}

export const unsubscribeFromLoom = (loomId) => {
  socket?.emit('unsubscribe:loom', loomId)
}

export default socket
