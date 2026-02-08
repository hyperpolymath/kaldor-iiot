// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed ReScript interface for the alerts Redux slice.
// The actual reducer logic lives in alertsSlice.js (Immer-based).

type alert = {
  id: int,
  loom_id: string,
  device_id: string,
  alert_type: string,
  severity: string,
  value: float,
  message: string,
  acknowledged: bool,
  created_at: string,
}

type alertsState = {
  alerts: array<alert>,
  unacknowledgedCount: int,
  loading: bool,
}

// Action creators imported from the JS wrapper
@module("./alertsSlice.js")
external setAlerts: array<alert> => {..} = "setAlerts"

@module("./alertsSlice.js")
external addAlert: alert => {..} = "addAlert"

@module("./alertsSlice.js")
external acknowledgeAlert: int => {..} = "acknowledgeAlert"

@module("./alertsSlice.js")
external setLoading: bool => {..} = "setLoading"

// Default export is the reducer
@module("./alertsSlice.js")
external reducer: (alertsState, {..}) => alertsState = "default"
