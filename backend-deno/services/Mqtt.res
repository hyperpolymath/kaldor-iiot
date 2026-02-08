// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// MQTT service for device telemetry and messaging.
/// Handles pub/sub for ESP32-C6 devices and real-time updates.

/// Message handler callback type: (topic, payload) => unit.
type messageHandler = (string, Js.TypedArray2.Uint8Array.t) => unit

/// MQTT service state.
type t = {
  mutable client: option<Mqtt_Client.t>,
  brokerUrl: string,
  mutable isConnectedFlag: bool,
  handlers: Js.Dict.t<array<messageHandler>>,
}

/// Create a new MQTT service wrapper (not yet connected).
let make = (brokerUrl: string): t => {
  client: None,
  brokerUrl,
  isConnectedFlag: false,
  handlers: Js.Dict.empty(),
}

/// Check if a topic matches an MQTT wildcard pattern.
/// + matches a single level, # matches multiple levels.
let topicMatches = (pattern: string, topic: string): bool => {
  let regexPattern =
    pattern
    ->String.replaceAll("+", "[^/]+")
    ->String.replaceAll("#", ".*")
    ->String.replaceAll("/", "\\/")

  let regex = %raw(`new RegExp("^" + regexPattern + "$")`)
  %raw(`regex.test(topic)`)
}

/// Internal: dispatch incoming messages to registered handlers.
let handleMessage = (service: t, topic: string, payload: Js.TypedArray2.Uint8Array.t): unit => {
  let entries = Js.Dict.entries(service.handlers)
  entries->Array.forEach(((pattern, handlerSet)) => {
    if topicMatches(pattern, topic) {
      handlerSet->Array.forEach(handler => {
        try {
          handler(topic, payload)
        } catch {
        | _exn =>
          let meta = Js.Dict.empty()
          Js.Dict.set(meta, "topic", Js.Json.string(topic))
          Logger.error(Logger.logger, "Error in MQTT message handler", ~meta)
        }
      })
    }
  })
}

/// Connect to the MQTT broker.
let connect = (service: t): promise<unit> => {
  Promise.make((resolve, reject) => {
    try {
      let parsed = %raw(`new URL(service.brokerUrl)`)
      let username: option<string> = %raw(`parsed.username || undefined`)
      let password: option<string> = %raw(`parsed.password || undefined`)

      let client = Mqtt_Client.mqttDefault.connect(
        service.brokerUrl,
        {
          clientId: `kaldor-backend-${Float.toString(Js.Date.now())}`,
          clean: true,
          reconnectPeriod: 5000,
          connectTimeout: 30000,
          username,
          password,
        },
      )

      service.client = Some(client)

      Mqtt_Client.onConnect(client, () => {
        service.isConnectedFlag = true
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "broker", Js.Json.string(service.brokerUrl))
        Logger.info(Logger.logger, "MQTT connected", ~meta)
        resolve()
      })

      Mqtt_Client.onError(client, error => {
        let meta = Js.Dict.empty()
        Js.Dict.set(
          meta,
          "error",
          Js.Json.string(error->Js.Exn.message->Option.getOr("unknown")),
        )
        Logger.error(Logger.logger, "MQTT error", ~meta)
        reject(error->Obj.magic)
      })

      Mqtt_Client.onMessage(client, (topic, payload) => {
        handleMessage(service, topic, payload)
      })

      Mqtt_Client.onOffline(client, () => {
        service.isConnectedFlag = false
        Logger.warn(Logger.logger, "MQTT offline")
      })

      Mqtt_Client.onReconnect(client, () => {
        Logger.info(Logger.logger, "MQTT reconnecting...")
      })
    } catch {
    | exn =>
      Logger.error(Logger.logger, "Failed to connect to MQTT broker")
      reject(exn->Obj.magic)
    }
  })
}

/// Disconnect from the MQTT broker.
let disconnect = (service: t): promise<unit> => {
  Promise.make((resolve, _reject) => {
    switch service.client {
    | Some(client) =>
      Mqtt_Client.end_(client, false, Js.Json.null, () => {
        service.isConnectedFlag = false
        Logger.info(Logger.logger, "MQTT disconnected")
        resolve()
      })
    | None => resolve()
    }
  })
}

/// Check if connected.
let isConnected = (service: t): bool => service.isConnectedFlag

/// Get the raw client, raising if not connected.
let getClient = (service: t): Mqtt_Client.t => {
  switch (service.client, service.isConnectedFlag) {
  | (Some(client), true) => client
  | _ => Js.Exn.raiseError("MQTT not connected")
  }
}

/// Publish a message to a topic.
let publish = (service: t, topic: string, message: string, ~qos: int=0): promise<unit> => {
  let client = getClient(service)
  Promise.make((resolve, reject) => {
    Mqtt_Client.publish(client, topic, message, {qos: qos}, error => {
      switch error->Js.Nullable.toOption {
      | Some(err) =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.error(Logger.logger, "MQTT publish failed", ~meta)
        reject(err->Obj.magic)
      | None =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Js.Dict.set(meta, "size", Js.Json.number(String.length(message)->Int.toFloat))
        Logger.debug(Logger.logger, "MQTT published", ~meta)
        resolve()
      }
    })
  })
}

/// Publish a JSON payload to a topic.
let publishJSON = async (service: t, topic: string, data: Js.Json.t, ~qos: int=0): unit => {
  await publish(service, topic, Js.Json.stringify(data), ~qos)
}

/// Subscribe to a topic with a message handler.
let subscribeToTopic = (
  service: t,
  topic: string,
  handler: messageHandler,
  ~qos: int=0,
): promise<unit> => {
  let client = getClient(service)
  Promise.make((resolve, reject) => {
    Mqtt_Client.subscribe(client, topic, {qos: qos}, error => {
      switch error->Js.Nullable.toOption {
      | Some(err) =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.error(Logger.logger, "MQTT subscribe failed", ~meta)
        reject(err->Obj.magic)
      | None =>
        let existing = Js.Dict.get(service.handlers, topic)->Option.getOr([])
        Js.Dict.set(service.handlers, topic, Array.concat(existing, [handler]))
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.info(Logger.logger, "MQTT subscribed", ~meta)
        resolve()
      }
    })
  })
}

/// Subscribe to JSON messages on a topic.
let subscribeJSON = async (
  service: t,
  topic: string,
  handler: (string, Js.Json.t) => unit,
  ~qos: int=0,
): unit => {
  let decoder = Deno.makeTextDecoder()
  await subscribeToTopic(
    service,
    topic,
    (topic, payload) => {
      try {
        let text = Deno.decode(decoder, payload)
        let data = Js.Json.parseExn(text)
        handler(topic, data)
      } catch {
      | _exn =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.error(Logger.logger, "Failed to parse MQTT JSON message", ~meta)
      }
    },
    ~qos,
  )
}

/// Unsubscribe from a topic (removes all handlers for the topic).
let unsubscribeFromBroker = (service: t, topic: string): promise<unit> => {
  let client = getClient(service)
  Promise.make((resolve, reject) => {
    Mqtt_Client.unsubscribe(client, topic, error => {
      switch error->Js.Nullable.toOption {
      | Some(err) =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.error(Logger.logger, "MQTT unsubscribe failed", ~meta)
        reject(err->Obj.magic)
      | None =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "topic", Js.Json.string(topic))
        Logger.info(Logger.logger, "MQTT unsubscribed", ~meta)
        resolve()
      }
    })
  })
}

/// Unsubscribe a specific handler or all handlers from a topic.
let unsubscribe = async (service: t, topic: string): unit => {
  // Remove all handlers for this topic and unsubscribe from broker
  let _removed = %raw(`delete service.handlers[topic]`)
  await unsubscribeFromBroker(service, topic)
}

/// Subscribe to all telemetry from a device by ID.
let subscribeToDevice = async (service: t, deviceId: string, handler: Js.Json.t => unit): unit => {
  await subscribeJSON(service, `devices/${deviceId}/#`, (_topic, data) => handler(data))
}

/// Publish a command to a specific device.
let publishDeviceCommand = async (
  service: t,
  deviceId: string,
  command: string,
  params: Js.Json.t,
): unit => {
  let payload = Js.Dict.empty()
  Js.Dict.set(payload, "command", Js.Json.string(command))
  Js.Dict.set(payload, "params", params)
  Js.Dict.set(payload, "timestamp", Js.Json.number(Js.Date.now()))
  await publishJSON(service, `devices/${deviceId}/commands`, Js.Json.object_(payload))
}

/// Broadcast a system-wide event.
let broadcastEvent = async (service: t, event: string, data: Js.Json.t): unit => {
  let payload = Js.Dict.empty()
  Js.Dict.set(payload, "event", Js.Json.string(event))
  Js.Dict.set(payload, "data", data)
  Js.Dict.set(payload, "timestamp", Js.Json.number(Js.Date.now()))
  await publishJSON(service, `system/events/${event}`, Js.Json.object_(payload))
}
