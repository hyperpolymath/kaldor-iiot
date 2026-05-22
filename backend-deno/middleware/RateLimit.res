// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Rate limiting middleware.
/// Uses an in-memory sliding window for development
/// (use Redis in production for distributed rate limiting).

/// Rate limit configuration options.
type rateLimitOptions = {
  windowMs: int,
  max: int,
  skipSuccessfulRequests: bool,
  skipFailedRequests: bool,
}

/// Internal record tracking request counts per key.
type requestRecord = {
  mutable count: int,
  resetTime: float,
}

/// In-memory store for rate limit tracking.
let requestCounts: Js.Dict.t<requestRecord> = Js.Dict.empty()

/// Create a rate limiter middleware with the given options.
let rateLimit = (~windowMs: int, ~max: int, ~skipSuccessfulRequests=false, ~skipFailedRequests=false): Oak.middleware => {
  let _ = {windowMs, max, skipSuccessfulRequests, skipFailedRequests}

  async (ctx, next) => {
    let ip =
      Oak.Context.request(ctx)
      ->Oak.Context.Request.ip
      ->Js.Nullable.toOption
      ->Option.getOr("unknown")
    let key = `ratelimit:${ip}`
    let now = Js.Date.now()

    // Get or create record
    let record = switch Js.Dict.get(requestCounts, key) {
    | Some(r) if now <= r.resetTime => r
    | _ => {
        let r = {count: 0, resetTime: now +. Int.toFloat(windowMs)}
        Js.Dict.set(requestCounts, key, r)
        r
      }
    }

    // Check if rate limit exceeded
    if record.count >= max {
      let retryAfter = Float.toInt(Math.ceil((record.resetTime -. now) /. 1000.0))

      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(429)
      let headers = Oak.Context.response(ctx)->Oak.Context.Response.headers
      Oak.Context.Response.Headers.set(headers, "Retry-After", Int.toString(retryAfter))
      Oak.Context.Response.Headers.set(headers, "X-RateLimit-Limit", Int.toString(max))
      Oak.Context.Response.Headers.set(headers, "X-RateLimit-Remaining", "0")
      Oak.Context.Response.Headers.set(
        headers,
        "X-RateLimit-Reset",
        Float.toString(record.resetTime),
      )

      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Too Many Requests"))
      Js.Dict.set(
        body,
        "message",
        Js.Json.string(`Rate limit exceeded. Try again in ${Int.toString(retryAfter)} seconds.`),
      )
      Js.Dict.set(body, "retryAfter", Js.Json.number(Int.toFloat(retryAfter)))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))

      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "key", Js.Json.string(key))
      Js.Dict.set(meta, "count", Js.Json.number(Int.toFloat(record.count)))
      Js.Dict.set(meta, "max", Js.Json.number(Int.toFloat(max)))
      Logger.warn(Logger.logger, "Rate limit exceeded", ~meta)
    } else {
      // Increment counter
      record.count = record.count + 1

      // Set rate limit headers
      let headers = Oak.Context.response(ctx)->Oak.Context.Response.headers
      Oak.Context.Response.Headers.set(headers, "X-RateLimit-Limit", Int.toString(max))
      Oak.Context.Response.Headers.set(
        headers,
        "X-RateLimit-Remaining",
        Int.toString(max - record.count),
      )
      Oak.Context.Response.Headers.set(
        headers,
        "X-RateLimit-Reset",
        Float.toString(record.resetTime),
      )

      await next()

      // Optionally skip counting based on response status
      let status: int = %raw(`ctx.response.status`)
      if (skipSuccessfulRequests && status < 400) || (skipFailedRequests && status >= 400) {
        record.count = record.count - 1
      }
    }
  }
}

/// Periodic cleanup of expired rate limit entries (every 60 seconds).
let _ = Deno.setInterval(() => {
  let now = Js.Date.now()
  Js.Dict.entries(requestCounts)->Array.forEach(((key, record)) => {
    if now > record.resetTime {
      let _ = %raw(`delete requestCounts[key]`)
    }
  })
}, 60000)
