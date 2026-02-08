// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Redux store configuration in JS.
// configureStore requires a plain object reducer map which is simpler in JS.

import { configureStore } from '@reduxjs/toolkit'
import authReducer from './slices/authSlice.js'
import loomsReducer from './slices/loomsSlice.js'
import alertsReducer from './slices/alertsSlice.js'
import measurementsReducer from './slices/measurementsSlice.js'

export const store = configureStore({
  reducer: {
    auth: authReducer,
    looms: loomsReducer,
    alerts: alertsReducer,
    measurements: measurementsReducer,
  },
})
