// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for OPC UA server types.
/// These types match the OPC UA service in services/Opcua.res.

/// OPC UA node representation.
type opcuaNode = {
  nodeId: string,
  browseName: string,
  value: Js.Json.t,
  dataType: string,
  accessLevel: string,
}

/// Device info for adding a device to the OPC UA address space.
type deviceInfo = {
  name: string,
  @as("type") type_: string,
}

/// Device metrics update payload.
type deviceMetrics = {
  temperature: option<float>,
  vibration: option<float>,
  status: option<string>,
}

/// Server info returned by getServerInfo.
type serverInfo = {
  endpoint: string,
  namespace: string,
  namespaceIndex: int,
  securityMode: string,
  securityPolicy: string,
  authentication: array<string>,
  nodeCount: int,
}
