// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// OPC UA server service for SCADA/DCS interoperability.
/// Exposes device data via OPC UA (IEC 62541) for industrial systems.
///
/// Note: Production implementation would use node-opcua or similar.
/// This is a simplified interface showing the integration pattern.

open Bindings.Opcua

/// OPC UA server state.
type t = {
  port: string,
  mutable isRunningFlag: bool,
  nodes: Js.Dict.t<opcuaNode>,
  namespaceUri: string,
  namespaceIndex: int,
}

/// Create a new OPC UA server (not yet started).
let make = (port: string): t => {
  port,
  isRunningFlag: false,
  nodes: Js.Dict.empty(),
  namespaceUri: "http://kaldor.community/manufacturing/",
  namespaceIndex: 2,
}

/// Add or update a node in the address space.
let addNode = (server: t, node: opcuaNode): unit => {
  Js.Dict.set(server.nodes, node.nodeId, node)
}

/// Initialize the default address space structure.
let initializeAddressSpace = (server: t): unit => {
  addNode(
    server,
    {
      nodeId: `ns=${Int.toString(server.namespaceIndex)};s=Devices`,
      browseName: "Devices",
      value: Js.Json.object_(Js.Dict.empty()),
      dataType: "Object",
      accessLevel: "read",
    },
  )
  Logger.debug(Logger.logger, "OPC UA address space initialized")
}

/// Start the OPC UA server.
let start = async (server: t): unit => {
  try {
    server.isRunningFlag = true
    initializeAddressSpace(server)

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "port", Js.Json.string(server.port))
    Js.Dict.set(meta, "endpoint", Js.Json.string(`opc.tcp://localhost:${server.port}`))
    Js.Dict.set(meta, "namespace", Js.Json.string(server.namespaceUri))
    Js.Dict.set(meta, "securityMode", Js.Json.string("SignAndEncrypt"))
    Logger.info(Logger.logger, "OPC UA server started", ~meta)
  } catch {
  | exn =>
    Logger.error(Logger.logger, "Failed to start OPC UA server")
    raise(exn)
  }
}

/// Stop the OPC UA server.
let stop = async (server: t): unit => {
  server.isRunningFlag = false
  Logger.info(Logger.logger, "OPC UA server stopped")
}

/// Check if the server is running.
let isRunning = (server: t): bool => server.isRunningFlag

/// Add a device to the OPC UA address space with standard variables.
let addDevice = (server: t, deviceId: string, info: deviceInfo): unit => {
  let ns = Int.toString(server.namespaceIndex)
  let deviceNodeId = `ns=${ns};s=Devices.${deviceId}`

  let deviceValue = Js.Dict.empty()
  Js.Dict.set(deviceValue, "type", Js.Json.string(info.type_))
  Js.Dict.set(deviceValue, "id", Js.Json.string(deviceId))

  addNode(
    server,
    {
      nodeId: deviceNodeId,
      browseName: info.name,
      value: Js.Json.object_(deviceValue),
      dataType: "Object",
      accessLevel: "read",
    },
  )

  addNode(
    server,
    {
      nodeId: `${deviceNodeId}.Status`,
      browseName: "Status",
      value: Js.Json.string("Online"),
      dataType: "String",
      accessLevel: "read",
    },
  )

  addNode(
    server,
    {
      nodeId: `${deviceNodeId}.Temperature`,
      browseName: "Temperature",
      value: Js.Json.number(0.0),
      dataType: "Double",
      accessLevel: "read",
    },
  )

  addNode(
    server,
    {
      nodeId: `${deviceNodeId}.Vibration`,
      browseName: "Vibration",
      value: Js.Json.number(0.0),
      dataType: "Double",
      accessLevel: "read",
    },
  )

  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
  Js.Dict.set(meta, "nodeId", Js.Json.string(deviceNodeId))
  Logger.info(Logger.logger, "OPC UA device added", ~meta)
}

/// Remove a device and all child nodes from the address space.
let removeDevice = (server: t, deviceId: string): unit => {
  let ns = Int.toString(server.namespaceIndex)
  let deviceNodeId = `ns=${ns};s=Devices.${deviceId}`

  let keysToRemove =
    Js.Dict.keys(server.nodes)->Array.filter(nodeId => String.startsWith(nodeId, deviceNodeId))

  keysToRemove->Array.forEach(nodeId => {
    let _ = %raw(`delete server.nodes[nodeId]`)
  })

  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "deviceId", Js.Json.string(deviceId))
  Logger.info(Logger.logger, "OPC UA device removed", ~meta)
}

/// Update a node's value.
let updateNodeValue = (server: t, nodeId: string, value: Js.Json.t): unit => {
  switch Js.Dict.get(server.nodes, nodeId) {
  | Some(node) =>
    Js.Dict.set(server.nodes, nodeId, {...node, value})
    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "nodeId", Js.Json.string(nodeId))
    Logger.debug(Logger.logger, "OPC UA node updated", ~meta)
  | None =>
    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "nodeId", Js.Json.string(nodeId))
    Logger.warn(Logger.logger, "OPC UA node not found", ~meta)
  }
}

/// Read a node's value.
let readNode = (server: t, nodeId: string): option<opcuaNode> =>
  Js.Dict.get(server.nodes, nodeId)

/// Browse child nodes (get direct children of a node).
let browseNode = (server: t, nodeId: string): array<opcuaNode> => {
  let prefix = if String.endsWith(nodeId, ".") {
    nodeId
  } else {
    nodeId ++ "."
  }
  Js.Dict.values(server.nodes)->Array.filter(node => {
    if String.startsWith(node.nodeId, prefix) {
      let suffix = String.sliceToEnd(node.nodeId, ~start=String.length(prefix))
      !String.includes(suffix, ".")
    } else {
      false
    }
  })
}

/// Update device metrics (temperature, vibration, status).
let updateDeviceMetrics = (server: t, deviceId: string, metrics: deviceMetrics): unit => {
  let ns = Int.toString(server.namespaceIndex)
  let devicePrefix = `ns=${ns};s=Devices.${deviceId}`

  switch metrics.temperature {
  | Some(temp) => updateNodeValue(server, `${devicePrefix}.Temperature`, Js.Json.number(temp))
  | None => ()
  }

  switch metrics.vibration {
  | Some(vib) => updateNodeValue(server, `${devicePrefix}.Vibration`, Js.Json.number(vib))
  | None => ()
  }

  switch metrics.status {
  | Some(status) => updateNodeValue(server, `${devicePrefix}.Status`, Js.Json.string(status))
  | None => ()
  }
}

/// Get server info for API endpoint.
let getServerInfo = (server: t): serverInfo => {
  endpoint: `opc.tcp://localhost:${server.port}`,
  namespace: server.namespaceUri,
  namespaceIndex: server.namespaceIndex,
  securityMode: "SignAndEncrypt",
  securityPolicy: "Basic256Sha256",
  authentication: ["Anonymous", "UserNamePassword"],
  nodeCount: Js.Dict.keys(server.nodes)->Array.length,
}

/// Get all nodes (for debugging).
let getAllNodes = (server: t): array<opcuaNode> => Js.Dict.values(server.nodes)
