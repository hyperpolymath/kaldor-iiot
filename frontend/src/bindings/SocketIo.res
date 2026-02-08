// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for socket.io-client

type socket

type connectOptions = {transports: array<string>}

@module("socket.io-client")
external io: (string, connectOptions) => socket = "io"

@send
external on: (socket, string, {..} => unit) => unit = "on"

@send
external onConnect: (socket, @as("connect") _, unit => unit) => unit = "on"

@send
external onDisconnect: (socket, @as("disconnect") _, unit => unit) => unit = "on"

@send
external onError: (socket, @as("error") _, {..} => unit) => unit = "on"

@send
external emit: (socket, string, 'a) => unit = "emit"

@send
external disconnect: socket => unit = "disconnect"
