// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Thin JS wrapper for Redux alerts slice.
// Immer-based reducers are kept in JS; typed ReScript interface imports from here.

import { createSlice } from '@reduxjs/toolkit'

const initialState = {
  alerts: [],
  unacknowledgedCount: 0,
  loading: false,
}

const alertsSlice = createSlice({
  name: 'alerts',
  initialState,
  reducers: {
    setAlerts: (state, action) => {
      state.alerts = action.payload
      state.unacknowledgedCount = action.payload.filter(a => !a.acknowledged).length
      state.loading = false
    },
    addAlert: (state, action) => {
      state.alerts.unshift(action.payload)
      if (!action.payload.acknowledged) {
        state.unacknowledgedCount++
      }
    },
    acknowledgeAlert: (state, action) => {
      const alert = state.alerts.find(a => a.id === action.payload)
      if (alert && !alert.acknowledged) {
        alert.acknowledged = true
        state.unacknowledgedCount--
      }
    },
    setLoading: (state, action) => {
      state.loading = action.payload
    },
  },
})

export const { setAlerts, addAlert, acknowledgeAlert, setLoading } = alertsSlice.actions
export default alertsSlice.reducer
