// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed ReScript interface for the measurements Redux slice.
// The actual reducer logic lives in measurementsSlice.js (Immer-based).

type measurement = {
  time: string,
  loom_id: string,
  bbw_avg: float,
  bbw_min: float,
  bbw_max: float,
  bbw_stddev: float,
  temperature: float,
  vibration: float,
  quality: float,
}

type measurementsState = {
  measurements: Dict.t<array<measurement>>,
  realTimeData: Dict.t<measurement>,
  loading: bool,
}

type measurementsPayload = {
  loomId: string,
  data: array<measurement>,
}

type realTimePayload = {
  loomId: string,
  data: measurement,
}

// Action creators imported from the JS wrapper
@module("./measurementsSlice.js")
external setMeasurements: measurementsPayload => {..} = "setMeasurements"

@module("./measurementsSlice.js")
external updateRealTimeData: realTimePayload => {..} = "updateRealTimeData"

@module("./measurementsSlice.js")
external setLoading: bool => {..} = "setLoading"

// Default export is the reducer
@module("./measurementsSlice.js")
external reducer: (measurementsState, {..}) => measurementsState = "default"
