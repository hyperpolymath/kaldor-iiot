// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Error handling middleware.
/// Catches and formats errors for API responses.

/// Error handling middleware. Wraps downstream middleware in a try/catch
/// and returns structured JSON error responses.
let errorHandler: Oak.middleware = async (ctx, next) => {
  try {
    await next()
  } catch {
  | exn =>
    let jsExn = exn->Js.Exn.asJsExn
    let errorMessage = jsExn->Option.flatMap(Js.Exn.message)->Option.getOr("Unknown error")
    let errorStack =
      jsExn->Option.flatMap(e => %raw(`e.stack || undefined`))->Option.getOr("")
    let errorName =
      jsExn->Option.flatMap(e => %raw(`e.name || undefined`))->Option.getOr("Error")

    // Log the error
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "method",
      Js.Json.string(Oak.Context.request(ctx)->Oak.Context.Request.method),
    )
    Js.Dict.set(
      meta,
      "url",
      Js.Json.string(
        Oak.Context.request(ctx)->Oak.Context.Request.url->Oak.Context.Request.Url.pathname,
      ),
    )
    Js.Dict.set(meta, "error", Js.Json.string(errorMessage))
    Js.Dict.set(meta, "stack", Js.Json.string(errorStack))
    Logger.error(Logger.logger, "Request error", ~meta)

    // Handle HTTP errors (thrown by Oak)
    let isHttp = switch jsExn {
    | Some(e) => Oak.isHttpError(e)
    | None => false
    }

    if isHttp {
      let status = switch jsExn {
      | Some(e) => Oak.httpErrorStatus(e)
      | None => 500
      }
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(status)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string(errorName))
      Js.Dict.set(body, "message", Js.Json.string(errorMessage))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    } else if errorName === "ValidationError" {
      // Handle validation errors
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Validation Error"))
      Js.Dict.set(body, "message", Js.Json.string(errorMessage))
      let details = switch jsExn {
      | Some(e) => %raw(`e.details || []`)
      | None => Js.Json.array([])
      }
      Js.Dict.set(body, "details", details)
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    } else if errorName === "PostgresError" {
      // Handle database errors
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Database Error"))
      Js.Dict.set(body, "message", Js.Json.string("A database error occurred"))
      let code = switch jsExn {
      | Some(e) => %raw(`e.code || "unknown"`)
      | None => Js.Json.string("unknown")
      }
      Js.Dict.set(body, "code", code)
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    } else {
      // Generic server error
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Internal Server Error"))
      let isProd =
        Deno.Env.get("NODE_ENV")->Js.Nullable.toOption->Option.getOr("") === "production"
      let msg = if isProd {
        "An unexpected error occurred"
      } else {
        errorMessage
      }
      Js.Dict.set(body, "message", Js.Json.string(msg))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  }
}
