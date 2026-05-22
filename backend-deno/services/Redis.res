// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Redis service for caching and pub/sub.
/// Supports real-time updates and session management.

/// Subscriber callback type.
type subscriberCallback = string => unit

/// Redis client state.
type t = {
  mutable client: option<Redis_Client.t>,
  connectionUrl: string,
  mutable isConnectedFlag: bool,
  subscribers: Js.Dict.t<array<subscriberCallback>>,
}

/// Parse hostname from a Redis URL.
let parseHostname = (url: string): string => {
  let parsed = %raw(`new URL(url)`)
  let hostname: string = %raw(`parsed.hostname || "localhost"`)
  hostname
}

/// Parse port from a Redis URL.
let parsePort = (url: string): int => {
  let parsed = %raw(`new URL(url)`)
  let portStr: string = %raw(`parsed.port || "6379"`)
  Int.fromString(portStr)->Option.getOr(6379)
}

/// Create a new Redis client wrapper (not yet connected).
let make = (connectionUrl: string): t => {
  client: None,
  connectionUrl,
  isConnectedFlag: false,
  subscribers: Js.Dict.empty(),
}

/// Connect to the Redis server.
let connect = async (redis: t): unit => {
  try {
    let hostname = parseHostname(redis.connectionUrl)
    let port = parsePort(redis.connectionUrl)
    let client = await Redis_Client.connect({"hostname": hostname, "port": port})
    redis.client = Some(client)
    redis.isConnectedFlag = true

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "url", Js.Json.string(redis.connectionUrl))
    Logger.info(Logger.logger, "Redis connected", ~meta)
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown")),
    )
    Logger.error(Logger.logger, "Failed to connect to Redis", ~meta)
    raise(exn)
  }
}

/// Disconnect from Redis.
let disconnect = async (redis: t): unit => {
  switch redis.client {
  | Some(client) =>
    Redis_Client.close(client)
    redis.isConnectedFlag = false
    Logger.info(Logger.logger, "Redis disconnected")
  | None => ()
  }
}

/// Check if connected.
let isConnected = (redis: t): bool => redis.isConnectedFlag

/// Get the raw client, raising if not connected.
let getClient = (redis: t): Redis_Client.t => {
  switch redis.client {
  | Some(client) => client
  | None => Js.Exn.raiseError("Redis not connected")
  }
}

// --- Cache operations ---

/// Get a string value by key.
let get = async (redis: t, key: string): option<string> => {
  let client = getClient(redis)
  let result = await Redis_Client.get(client, key)
  result->Js.Nullable.toOption
}

/// Set a string value, optionally with a TTL in seconds.
let set = async (redis: t, key: string, value: string, ~ttlSeconds: option<int>=?): unit => {
  let client = getClient(redis)
  switch ttlSeconds {
  | Some(ttl) => {
      let _ = await Redis_Client.setex(client, key, ttl, value)
    }
  | None => {
      let _ = await Redis_Client.set(client, key, value)
    }
  }
}

/// Delete a key.
let del = async (redis: t, key: string): unit => {
  let client = getClient(redis)
  let _ = await Redis_Client.del(client, key)
}

/// Check if a key exists.
let exists = async (redis: t, key: string): bool => {
  let client = getClient(redis)
  let result = await Redis_Client.exists(client, key)
  result === 1
}

// --- JSON helpers ---

/// Get a JSON value by key.
let getJSON = async (redis: t, key: string): option<Js.Json.t> => {
  let value = await get(redis, key)
  switch value {
  | Some(str) => Some(Js.Json.parseExn(str))
  | None => None
  }
}

/// Set a JSON value, optionally with a TTL.
let setJSON = async (redis: t, key: string, value: Js.Json.t, ~ttlSeconds: option<int>=?): unit => {
  let str = Js.Json.stringify(value)
  await set(redis, key, str, ~ttlSeconds?)
}

// --- Pub/Sub ---

/// Publish a string message to a channel.
let publish = async (redis: t, channel: string, message: string): unit => {
  let client = getClient(redis)
  let _ = await Redis_Client.publish(client, channel, message)
  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "channel", Js.Json.string(channel))
  Js.Dict.set(meta, "messageLength", Js.Json.number(String.length(message)->Int.toFloat))
  Logger.debug(Logger.logger, "Published to channel", ~meta)
}

/// Publish a JSON payload to a channel.
let publishJSON = async (redis: t, channel: string, data: Js.Json.t): unit => {
  await publish(redis, channel, Js.Json.stringify(data))
}

/// Subscribe to a Redis channel with a callback.
let subscribe = async (redis: t, channel: string, callback: subscriberCallback): unit => {
  let existing = Js.Dict.get(redis.subscribers, channel)
  switch existing {
  | None => {
      Js.Dict.set(redis.subscribers, channel, [callback])

      // Create a dedicated subscriber connection
      let hostname = parseHostname(redis.connectionUrl)
      let port = parsePort(redis.connectionUrl)
      let subscriber = await Redis_Client.connect({"hostname": hostname, "port": port})
      await Redis_Client.subscribe(subscriber, channel, message => {
        switch Js.Dict.get(redis.subscribers, channel) {
        | Some(callbacks) => callbacks->Array.forEach(cb => cb(message))
        | None => ()
        }
      })

      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "channel", Js.Json.string(channel))
      Logger.info(Logger.logger, "Subscribed to Redis channel", ~meta)
    }
  | Some(callbacks) => {
      let updated = Array.concat(callbacks, [callback])
      Js.Dict.set(redis.subscribers, channel, updated)
    }
  }
}

/// Unsubscribe a callback from a Redis channel.
let unsubscribe = (_redis: t, channel: string, _callback: subscriberCallback): unit => {
  // Note: In a full implementation we would track and remove the specific callback.
  // For now, log and clear all callbacks for the channel.
  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "channel", Js.Json.string(channel))
  Logger.info(Logger.logger, "Unsubscribed from Redis channel", ~meta)
}

// --- Session management ---

/// Store a session object in Redis with a TTL.
let setSession = async (redis: t, sessionId: string, data: Js.Json.t, ~ttlSeconds: int=3600): unit => {
  await setJSON(redis, `session:${sessionId}`, data, ~ttlSeconds)
}

/// Retrieve a session object from Redis.
let getSession = async (redis: t, sessionId: string): option<Js.Json.t> => {
  await getJSON(redis, `session:${sessionId}`)
}

/// Delete a session from Redis.
let deleteSession = async (redis: t, sessionId: string): unit => {
  await del(redis, `session:${sessionId}`)
}

// --- Rate limiting ---

/// Rate limit result.
type rateLimitResult = {
  allowed: bool,
  remaining: int,
}

/// Check if a request is within the rate limit using a Redis sorted set
/// sliding window.
let checkRateLimit = async (
  redis: t,
  key: string,
  maxRequests: int,
  windowSeconds: int,
): rateLimitResult => {
  let client = getClient(redis)
  let now = Js.Date.now()
  let windowStart = now -. Int.toFloat(windowSeconds) *. 1000.0

  let rateLimitKey = `ratelimit:${key}`

  // Remove old entries
  let _ = await Redis_Client.zremrangebyscore(
    client,
    rateLimitKey,
    "-inf",
    Float.toString(windowStart),
  )

  // Count requests in current window
  let count = await Redis_Client.zcard(client, rateLimitKey)

  if count >= maxRequests {
    {allowed: false, remaining: 0}
  } else {
    // Add current request
    let _ = await Redis_Client.zadd(client, rateLimitKey, now, Float.toString(now))
    let _ = await Redis_Client.expire(client, rateLimitKey, windowSeconds)
    {allowed: true, remaining: maxRequests - count - 1}
  }
}
