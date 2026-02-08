// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for deno.land/x/redis module.
/// Provides Redis client for Deno.

/// Opaque type for the Redis connection object.
type t

@module("redis")
external connect: {"hostname": string, "port": int} => promise<t> = "connect"

@send external get: (t, string) => promise<Js.Nullable.t<string>> = "get"
@send external set: (t, string, string) => promise<string> = "set"
@send external setex: (t, string, int, string) => promise<string> = "setex"
@send external del: (t, string) => promise<int> = "del"
@send external exists: (t, string) => promise<int> = "exists"
@send external close: t => unit = "close"

@send external publish: (t, string, string) => promise<int> = "publish"

/// Subscribe to a channel with a callback.
@send
external subscribe: (t, string, string => unit) => promise<unit> = "subscribe"

/// Sorted set operations for rate limiting.
@send
external zremrangebyscore: (t, string, string, string) => promise<int> = "zremrangebyscore"

@send external zcard: (t, string) => promise<int> = "zcard"
@send external zadd: (t, string, float, string) => promise<int> = "zadd"
@send external expire: (t, string, int) => promise<int> = "expire"
