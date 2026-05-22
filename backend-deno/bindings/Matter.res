// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for Matter protocol bridge service.
/// These types match the Matter bridge implementation in services/Matter.res.

/// Matter device record, matching MatterDevice interface in the TS original.
type matterDevice = {
  id: string,
  name: string,
  vendorId: int,
  productId: int,
  commissioned: bool,
  online: bool,
  lastSeen: Js.Date.t,
  capabilities: array<string>,
  nodeId: option<float>,
}

/// Commission result returned by commissionDevice.
type commissionResult = {
  success: bool,
  deviceId: option<string>,
}

/// Command result returned by sendCommand.
type commandResult = {
  success: bool,
  response: option<Js.Json.t>,
}

/// Attribute read result returned by readAttribute.
type attributeResult = {
  success: bool,
  value: option<Js.Json.t>,
}

/// Fabric information.
type fabricInfo = {
  fabricId: string,
  deviceCount: int,
  onlineDevices: int,
}
