// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for deno.land/x/postgres module.
/// Provides PostgreSQL client for Deno.

module Client = {
  /// Opaque type for the postgres Client.
  type t

  @module("postgres") @new external make: string => t = "Client"

  @send external connect: t => promise<unit> = "connect"
  @send external end: t => promise<unit> = "end"

  module Session = {
    type t
    @get external dbName: t => string = "dbName"
  }

  @get external session: t => Session.t = "session"

  /// Execute a parameterized query, returning rows as an array of JSON objects.
  @send
  external queryObject: (t, string, option<array<Js.Json.t>>) => promise<{"rows": array<Js.Json.t>, "rowCount": Js.Nullable.t<int>}> = "queryObject"
}
