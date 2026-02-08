// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Device/machine routes.
/// Manage IoT devices (looms, spinners, 3D printers).

/// Simulated device storage (production would use database).
let devices: Js.Dict.t<Js.Json.t> = Js.Dict.empty()

/// Helper to extract a string field from parsed JSON.
let getStr = (json: Js.Json.t, key: string): option<string> => {
  switch Js.Json.decodeObject(json) {
  | Some(dict) => Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeString)
  | None => None
  }
}

/// Create and configure the machine routes router.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // GET / - List all devices
  Oak.Router.get(router, "/", async (ctx, _next) => {
    try {
      let deviceList = Js.Dict.values(devices)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "devices", Js.Json.array(deviceList))
      Js.Dict.set(body, "count", Js.Json.number(Array.length(deviceList)->Int.toFloat))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    } catch {
    | _exn =>
      Logger.error(Logger.logger, "Failed to list devices")
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Failed to list devices"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // GET /:id - Get a single device
  Oak.Router.get(router, "/:id", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(devices, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Device not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(device) =>
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(device)
    }
  })

  // POST / - Create a new device
  Oak.Router.post(router, "/", async (ctx, _next) => {
    try {
      let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
      let json = await bodyObj["value"]

      let name = getStr(json, "name")
      let type_ = getStr(json, "type")
      let location = getStr(json, "location")

      switch (name, type_) {
      | (Some(name), Some(type_)) => {
          let deviceId = `device-${%raw(`Date.now().toString(36)`)}`

          let metrics = Js.Dict.empty()
          Js.Dict.set(metrics, "temperature", Js.Json.null)
          Js.Dict.set(metrics, "vibration", Js.Json.null)
          Js.Dict.set(metrics, "uptime", Js.Json.number(0.0))

          let device = Js.Dict.empty()
          Js.Dict.set(device, "id", Js.Json.string(deviceId))
          Js.Dict.set(device, "name", Js.Json.string(name))
          Js.Dict.set(device, "type", Js.Json.string(type_))
          switch location {
          | Some(loc) => Js.Dict.set(device, "location", Js.Json.string(loc))
          | None => ()
          }
          Js.Dict.set(device, "status", Js.Json.string("offline"))
          Js.Dict.set(device, "commissioned", Js.Json.boolean(false))
          Js.Dict.set(device, "createdAt", Js.Json.string(Js.Date.make()->Js.Date.toISOString))
          Js.Dict.set(device, "metrics", Js.Json.object_(metrics))

          let deviceJson = Js.Json.object_(device)
          Js.Dict.set(devices, deviceId, deviceJson)

          let meta = Js.Dict.empty()
          Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
          Js.Dict.set(meta, "name", Js.Json.string(name))
          Js.Dict.set(meta, "type", Js.Json.string(type_))
          Logger.info(Logger.logger, "Device created", ~meta)

          Oak.Context.response(ctx)->Oak.Context.Response.setStatus(201)
          Oak.Context.response(ctx)->Oak.Context.Response.setBody(deviceJson)
        }
      | _ =>
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Name and type required"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      }
    } catch {
    | _exn =>
      Logger.error(Logger.logger, "Failed to create device")
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Failed to create device"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // PUT /:id - Update a device
  Oak.Router.put(router, "/:id", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(devices, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Device not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(existing) =>
      try {
        let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
        let updates = await bodyObj["value"]

        // Merge existing with updates
        let merged: Js.Json.t = %raw(`Object.assign({}, existing, updates, { updatedAt: new Date().toISOString() })`)
        Js.Dict.set(devices, id, merged)

        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "deviceId", Js.Json.string(id))
        Logger.info(Logger.logger, "Device updated", ~meta)

        Oak.Context.response(ctx)->Oak.Context.Response.setBody(merged)
      } catch {
      | _exn =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "deviceId", Js.Json.string(id))
        Logger.error(Logger.logger, "Failed to update device", ~meta)
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Failed to update device"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      }
    }
  })

  // DELETE /:id - Delete a device
  Oak.Router.delete(router, "/:id", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(devices, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Device not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(_) =>
      let _ = %raw(`delete devices[id]`)

      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "deviceId", Js.Json.string(id))
      Logger.info(Logger.logger, "Device deleted", ~meta)

      let body = Js.Dict.empty()
      Js.Dict.set(body, "success", Js.Json.boolean(true))
      Js.Dict.set(body, "message", Js.Json.string("Device deleted"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // GET /:id/metrics - Get device metrics
  Oak.Router.get(router, "/:id/metrics", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(devices, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Device not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(device) =>
      let metricsVal = switch Js.Json.decodeObject(device) {
      | Some(dict) => Js.Dict.get(dict, "metrics")->Option.getOr(Js.Json.null)
      | None => Js.Json.null
      }

      let body = Js.Dict.empty()
      Js.Dict.set(body, "deviceId", Js.Json.string(id))
      Js.Dict.set(body, "current", metricsVal)
      Js.Dict.set(body, "history", Js.Json.array([]))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // POST /:id/command - Send command to device
  Oak.Router.post(router, "/:id/command", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(devices, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Device not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(_) =>
      try {
        let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
        let json = await bodyObj["value"]

        let command = getStr(json, "command")

        switch command {
        | None =>
          Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
          let body = Js.Dict.empty()
          Js.Dict.set(body, "error", Js.Json.string("Command required"))
          Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
        | Some(cmd) =>
          let meta = Js.Dict.empty()
          Js.Dict.set(meta, "deviceId", Js.Json.string(id))
          Js.Dict.set(meta, "command", Js.Json.string(cmd))
          Logger.info(Logger.logger, "Device command sent", ~meta)

          let body = Js.Dict.empty()
          Js.Dict.set(body, "success", Js.Json.boolean(true))
          Js.Dict.set(body, "message", Js.Json.string(`Command '${cmd}' sent to device`))
          Js.Dict.set(body, "timestamp", Js.Json.number(Js.Date.now()))
          Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
        }
      } catch {
      | _exn =>
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "deviceId", Js.Json.string(id))
        Logger.error(Logger.logger, "Failed to send device command", ~meta)
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Failed to send command"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      }
    }
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
