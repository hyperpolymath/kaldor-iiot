// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Matter protocol bridge service.
/// Manages ESP32-C6 devices using Matter 1.2+ over Thread/WiFi.
///
/// Note: This is a simplified implementation. Production would use
/// official Matter SDK (chip-tool) via subprocess or native bindings.

open Bindings.Matter

/// Matter bridge state.
type t = {
  port: string,
  devices: Js.Dict.t<matterDevice>,
  mutable isRunningFlag: bool,
  fabricId: float, // Using float since ReScript doesn't have BigInt
}

/// Create a new Matter bridge (not yet started).
let make = (port: string): t => {
  port,
  devices: Js.Dict.empty(),
  isRunningFlag: false,
  fabricId: 1.0,
}

/// Check device heartbeats and mark stale devices offline.
let checkDeviceHeartbeats = (bridge: t): unit => {
  let now = Js.Date.now()
  Js.Dict.values(bridge.devices)->Array.forEach(device => {
    let timeSinceLastSeen = now -. Js.Date.getTime(device.lastSeen)
    if timeSinceLastSeen > 60000.0 {
      // 1 minute timeout
      if device.online {
        let updated = {...device, online: false}
        Js.Dict.set(bridge.devices, device.id, updated)
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "deviceId", Js.Json.string(device.id))
        Logger.warn(Logger.logger, "Matter device went offline", ~meta)
      }
    }
  })
}

/// Start device discovery (simulated with periodic heartbeat checks).
let startDiscovery = (bridge: t): unit => {
  Logger.debug(Logger.logger, "Matter device discovery started")
  let _ = Deno.setInterval(() => checkDeviceHeartbeats(bridge), 30000)
}

/// Start the Matter bridge.
let start = async (bridge: t): unit => {
  try {
    bridge.isRunningFlag = true

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "port", Js.Json.string(bridge.port))
    Js.Dict.set(meta, "fabricId", Js.Json.string(Float.toString(bridge.fabricId)))
    Js.Dict.set(meta, "protocol", Js.Json.string("Matter 1.2+"))
    Js.Dict.set(meta, "transport", Js.Json.string("Thread/WiFi"))
    Logger.info(Logger.logger, "Matter bridge started", ~meta)

    startDiscovery(bridge)
  } catch {
  | exn =>
    Logger.error(Logger.logger, "Failed to start Matter bridge")
    raise(exn)
  }
}

/// Stop the Matter bridge.
let stop = async (bridge: t): unit => {
  bridge.isRunningFlag = false
  Logger.info(Logger.logger, "Matter bridge stopped")
}

/// Check if the bridge is running.
let isRunning = (bridge: t): bool => bridge.isRunningFlag

/// Commission a new Matter device.
let commissionDevice = async (bridge: t, _setupCode: string): commissionResult => {
  try {
    Logger.info(Logger.logger, "Commissioning Matter device")

    let deviceId = `matter-${%raw(`Date.now().toString(36)`)}`
    let deviceCount = Js.Dict.keys(bridge.devices)->Array.length

    let device: matterDevice = {
      id: deviceId,
      name: "ESP32-C6 Loom Controller",
      vendorId: 0xfff1,
      productId: 0x8000,
      commissioned: true,
      online: true,
      lastSeen: Js.Date.make(),
      capabilities: ["temperature", "vibration", "loom-control"],
      nodeId: Some(Int.toFloat(deviceCount + 1)),
    }

    Js.Dict.set(bridge.devices, deviceId, device)

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
    Logger.info(Logger.logger, "Matter device commissioned", ~meta)

    {success: true, deviceId: Some(deviceId)}
  } catch {
  | _exn =>
    Logger.error(Logger.logger, "Matter commissioning failed")
    {success: false, deviceId: None}
  }
}

/// Get all devices.
let getDevices = (bridge: t): array<matterDevice> => Js.Dict.values(bridge.devices)

/// Get a specific device by ID.
let getDevice = (bridge: t, deviceId: string): option<matterDevice> =>
  Js.Dict.get(bridge.devices, deviceId)

/// Send a command to a Matter device (simulated).
let sendCommand = async (
  bridge: t,
  deviceId: string,
  clusterId: int,
  commandId: int,
  _payload: Js.Json.t,
): commandResult => {
  switch Js.Dict.get(bridge.devices, deviceId) {
  | None =>
    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
    Logger.error(Logger.logger, "Device not found", ~meta)
    {success: false, response: None}
  | Some(device) =>
    if !device.online {
      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
      Logger.error(Logger.logger, "Device offline", ~meta)
      {success: false, response: None}
    } else {
      try {
        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
        Js.Dict.set(
          meta,
          "clusterId",
          Js.Json.string(`0x${%raw(`clusterId.toString(16)`)}`),
        )
        Js.Dict.set(
          meta,
          "commandId",
          Js.Json.string(`0x${%raw(`commandId.toString(16)`)}`),
        )
        Logger.debug(Logger.logger, "Sending Matter command", ~meta)

        // Update last seen
        Js.Dict.set(bridge.devices, deviceId, {...device, lastSeen: Js.Date.make()})

        let resp = Js.Dict.empty()
        Js.Dict.set(resp, "status", Js.Json.string("ok"))
        Js.Dict.set(resp, "timestamp", Js.Json.number(Js.Date.now()))
        {success: true, response: Some(Js.Json.object_(resp))}
      } catch {
      | _exn =>
        Logger.error(Logger.logger, "Matter command failed")
        {success: false, response: None}
      }
    }
  }
}

/// Simulate reading an attribute based on cluster and attribute IDs.
let simulateAttributeRead = (clusterId: int, attributeId: int): option<Js.Json.t> => {
  switch (clusterId, attributeId) {
  | (0x0028, 0x0005) => Some(Js.Json.string("Kaldor Loom v1.0"))
  | (0x0402, 0x0000) => Some(Js.Json.number(2150.0))
  | (0x0406, 0x0000) => Some(Js.Json.number(1.0))
  | _ => None
  }
}

/// Read an attribute from a Matter device (simulated).
let readAttribute = async (
  bridge: t,
  deviceId: string,
  clusterId: int,
  attributeId: int,
): attributeResult => {
  switch Js.Dict.get(bridge.devices, deviceId) {
  | None => {success: false, value: None}
  | Some(device) =>
    try {
      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
      Js.Dict.set(
        meta,
        "clusterId",
        Js.Json.string(`0x${%raw(`clusterId.toString(16)`)}`),
      )
      Js.Dict.set(
        meta,
        "attributeId",
        Js.Json.string(`0x${%raw(`attributeId.toString(16)`)}`),
      )
      Logger.debug(Logger.logger, "Reading Matter attribute", ~meta)

      Js.Dict.set(bridge.devices, deviceId, {...device, lastSeen: Js.Date.make()})

      let value = simulateAttributeRead(clusterId, attributeId)
      {success: true, value}
    } catch {
    | _exn =>
      Logger.error(Logger.logger, "Matter attribute read failed")
      {success: false, value: None}
    }
  }
}

/// Subscribe to attribute changes (simulated with periodic polling).
let subscribeAttribute = async (
  bridge: t,
  deviceId: string,
  clusterId: int,
  attributeId: int,
  callback: Js.Json.t => unit,
): bool => {
  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
  Js.Dict.set(
    meta,
    "clusterId",
    Js.Json.string(`0x${%raw(`clusterId.toString(16)`)}`),
  )
  Js.Dict.set(
    meta,
    "attributeId",
    Js.Json.string(`0x${%raw(`attributeId.toString(16)`)}`),
  )
  Logger.info(Logger.logger, "Matter attribute subscription created", ~meta)

  // Simulated periodic updates
  let _ = Deno.setInterval(async () => {
    let result = await readAttribute(bridge, deviceId, clusterId, attributeId)
    if result.success {
      switch result.value {
      | Some(value) => callback(value)
      | None => ()
      }
    }
  }, 5000)

  true
}

/// Decommission (remove) a device from the bridge.
let decommissionDevice = async (bridge: t, deviceId: string): bool => {
  switch Js.Dict.get(bridge.devices, deviceId) {
  | None => false
  | Some(_) =>
    try {
      let _ = %raw(`delete bridge.devices[deviceId]`)
      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
      Logger.info(Logger.logger, "Matter device decommissioned", ~meta)
      true
    } catch {
    | _exn =>
      Logger.error(Logger.logger, "Matter decommissioning failed")
      false
    }
  }
}

/// Get fabric information.
let getFabricInfo = (bridge: t): fabricInfo => {
  let allDevices = Js.Dict.values(bridge.devices)
  {
    fabricId: Float.toString(bridge.fabricId),
    deviceCount: Array.length(allDevices),
    onlineDevices: allDevices->Array.filter(d => d.online)->Array.length,
  }
}
