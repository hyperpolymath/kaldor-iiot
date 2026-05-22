// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Redux store configuration.
// Uses a thin JS helper for configureStore since it requires dynamic reducer map.

// Root state type matching all slice states
type rootState = {
  auth: AuthSlice.authState,
  looms: LoomsSlice.loomsState,
  alerts: AlertsSlice.alertsState,
  measurements: MeasurementsSlice.measurementsState,
}

// Re-export store from JS helper
@module("./store.js")
external store: ReduxToolkit.store = "store"
