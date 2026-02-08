// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Thin JS wrapper for Redux measurements slice.
// Immer-based reducers are kept in JS; typed ReScript interface imports from here.

import { createSlice } from '@reduxjs/toolkit'

const initialState = {
  measurements: {},
  realTimeData: {},
  loading: false,
}

const measurementsSlice = createSlice({
  name: 'measurements',
  initialState,
  reducers: {
    setMeasurements: (state, action) => {
      state.measurements[action.payload.loomId] = action.payload.data
      state.loading = false
    },
    updateRealTimeData: (state, action) => {
      state.realTimeData[action.payload.loomId] = action.payload.data

      // Also add to measurements history (keep last 100 points)
      if (!state.measurements[action.payload.loomId]) {
        state.measurements[action.payload.loomId] = []
      }
      state.measurements[action.payload.loomId].unshift(action.payload.data)
      if (state.measurements[action.payload.loomId].length > 100) {
        state.measurements[action.payload.loomId].pop()
      }
    },
    setLoading: (state, action) => {
      state.loading = action.payload
    },
  },
})

export const { setMeasurements, updateRealTimeData, setLoading } = measurementsSlice.actions
export default measurementsSlice.reducer
