// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Axios API client with interceptors for the Kaldor IIoT backend.
// Interceptors are set up via a JS helper since they require mutation
// and complex callback patterns.

@module("./api.js")
external api: Axios.instance = "default"

// Auth API
module AuthAPI = {
  @module("./api.js") @scope("authAPI")
  external login: (string, string) => promise<Axios.response<{..}>> = "login"

  @module("./api.js") @scope("authAPI")
  external register: (string, string, string) => promise<Axios.response<{..}>> = "register"
}

// Looms API
module LoomsAPI = {
  @module("./api.js") @scope("loomsAPI")
  external getAll: unit => promise<Axios.response<{..}>> = "getAll"

  @module("./api.js") @scope("loomsAPI")
  external getById: string => promise<Axios.response<{..}>> = "getById"

  @module("./api.js") @scope("loomsAPI")
  external updateConfig: (string, {..}) => promise<Axios.response<{..}>> = "updateConfig"
}

// Measurements API
module MeasurementsAPI = {
  @module("./api.js") @scope("measurementsAPI")
  external get: (string, ~params: {..}=?) => promise<Axios.response<{..}>> = "get"
}

// Alerts API
module AlertsAPI = {
  @module("./api.js") @scope("alertsAPI")
  external getAll: (~params: {..}=?) => promise<Axios.response<{..}>> = "getAll"

  @module("./api.js") @scope("alertsAPI")
  external acknowledge: int => promise<Axios.response<{..}>> = "acknowledge"
}

// Analytics API
module AnalyticsAPI = {
  @module("./api.js") @scope("analyticsAPI")
  external getSummary: string => promise<Axios.response<{..}>> = "getSummary"
}
