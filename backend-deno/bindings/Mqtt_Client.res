// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for MQTT client library.
/// Provides MQTT pub/sub for device telemetry.

/// Opaque type for the MQTT client.
type t

/// MQTT connection options.
type connectOptions = {
  clientId: string,
  clean: bool,
  reconnectPeriod: int,
  connectTimeout: int,
  username: option<string>,
  password: option<string>,
}

/// QoS publish options.
type publishOptions = {qos: int}

/// QoS subscribe options.
type subscribeOptions = {qos: int}

/// The default export of the mqtt module, containing the connect function.
type mqttModule = {connect: (string, connectOptions) => t}

@module("mqtt") external mqttDefault: mqttModule = "default"

@send
external on: (t, string, @uncurry (string, Js.TypedArray2.Uint8Array.t) => unit) => unit = "on"

@send
external onConnect: (t, @as("connect") _, @uncurry unit => unit) => unit = "on"

@send
external onError: (t, @as("error") _, @uncurry Js.Exn.t => unit) => unit = "on"

@send
external onOffline: (t, @as("offline") _, @uncurry unit => unit) => unit = "on"

@send
external onReconnect: (t, @as("reconnect") _, @uncurry unit => unit) => unit = "on"

@send
external onMessage: (
  t,
  @as("message") _,
  @uncurry (string, Js.TypedArray2.Uint8Array.t) => unit,
) => unit = "on"

@send
external publish: (
  t,
  string,
  string,
  publishOptions,
  @uncurry Js.Nullable.t<Js.Exn.t> => unit,
) => unit = "publish"

@send
external subscribe: (
  t,
  string,
  subscribeOptions,
  @uncurry Js.Nullable.t<Js.Exn.t> => unit,
) => unit = "subscribe"

@send
external unsubscribe: (
  t,
  string,
  @uncurry Js.Nullable.t<Js.Exn.t> => unit,
) => unit = "unsubscribe"

@send
external end_: (t, bool, Js.Json.t, @uncurry unit => unit) => unit = "end"
