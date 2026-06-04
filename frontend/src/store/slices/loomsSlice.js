// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Thin JS wrapper for Redux looms slice.
// Immer-based reducers are kept in JS; typed ReScript interface imports from here.

import { createSlice } from '@reduxjs/toolkit'

const initialState = {
  looms: [],
  selectedLoom: null,
  loading: false,
  error: null,
}

const loomsSlice = createSlice({
  name: 'looms',
  initialState,
  reducers: {
    setLooms: (state, action) => {
      state.looms = action.payload
      state.loading = false
    },
    setSelectedLoom: (state, action) => {
      state.selectedLoom = action.payload
    },
    updateLoomStatus: (state, action) => {
      const loom = state.looms.find(l => l.id === action.payload.id)
      if (loom) {
        loom.status = action.payload.status
      }
    },
    setLoading: (state, action) => {
      state.loading = action.payload
    },
    setError: (state, action) => {
      state.error = action.payload
      state.loading = false
    },
  },
})

export const { setLooms, setSelectedLoom, updateLoomStatus, setLoading, setError } = loomsSlice.actions
export default loomsSlice.reducer
