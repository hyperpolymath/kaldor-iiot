// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed ReScript interface for the looms Redux slice.
// The actual reducer logic lives in loomsSlice.js (Immer-based).

type loom = {
  id: string,
  name: string,
  description: string,
  location: string,
  model: string,
  status: string,
  configuration: {..},
}

type loomsState = {
  looms: array<loom>,
  selectedLoom: Nullable.t<loom>,
  loading: bool,
  error: Nullable.t<string>,
}

type statusUpdate = {
  id: string,
  status: string,
}

// Action creators imported from the JS wrapper
@module("./loomsSlice.js")
external setLooms: array<loom> => {..} = "setLooms"

@module("./loomsSlice.js")
external setSelectedLoom: loom => {..} = "setSelectedLoom"

@module("./loomsSlice.js")
external updateLoomStatus: statusUpdate => {..} = "updateLoomStatus"

@module("./loomsSlice.js")
external setLoading: bool => {..} = "setLoading"

@module("./loomsSlice.js")
external setError: string => {..} = "setError"

// Default export is the reducer
@module("./loomsSlice.js")
external reducer: (loomsState, {..}) => loomsState = "default"
