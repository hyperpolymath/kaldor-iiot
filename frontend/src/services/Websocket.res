// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// WebSocket (Socket.io) client for real-time loom data.
// FIX: original TS had `subscribeTo Loom` (space) -- corrected to `subscribeToLoom`.

// Import connect/disconnect/subscribe functions from the JS helper
// since socket.io relies on mutable module-level state.

@module("./websocket.js")
external connectWebSocket: (string, ReduxToolkit.dispatch) => SocketIo.socket = "connectWebSocket"

@module("./websocket.js")
external disconnectWebSocket: unit => unit = "disconnectWebSocket"

@module("./websocket.js")
external subscribeToLoom: string => unit = "subscribeToLoom"

@module("./websocket.js")
external unsubscribeFromLoom: string => unit = "unsubscribeFromLoom"
