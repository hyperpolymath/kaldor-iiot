// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Authentication middleware.
/// JWT-based authentication with Redis session storage.

/// Auth payload carried in JWT claims and attached to request context.
type authPayload = {
  userId: string,
  username: string,
  roles: array<string>,
  perimeter: int, // TPCF perimeter: 1, 2, or 3
}

/// JWT secret, read from environment or using a default for development.
let jwtSecret = {
  let encoder = Deno.makeTextEncoder()
  let secret =
    Deno.Env.get("JWT_SECRET")
    ->Js.Nullable.toOption
    ->Option.getOr("kaldor-secret-change-in-production")
  Deno.encode(encoder, secret)
}

let jwtAlgorithm = "HS256"

/// Generate a JWT token from an auth payload.
let generateToken = async (payload: authPayload): string => {
  let claims = Js.Dict.empty()
  Js.Dict.set(claims, "sub", Js.Json.string(payload.userId))
  Js.Dict.set(claims, "username", Js.Json.string(payload.username))
  Js.Dict.set(
    claims,
    "roles",
    Js.Json.array(payload.roles->Array.map(Js.Json.string)),
  )
  Js.Dict.set(claims, "perimeter", Js.Json.number(Int.toFloat(payload.perimeter)))
  Js.Dict.set(
    claims,
    "exp",
    Js.Json.number(Int.toFloat(Jose.getNumericDate(60 * 60 * 24))),
  ) // 24 hours
  Js.Dict.set(
    claims,
    "iat",
    Js.Json.number(Int.toFloat(Jose.getNumericDate(0))),
  )

  await Jose.create({"alg": jwtAlgorithm}, Js.Json.object_(claims), jwtSecret)
}

/// Verify a JWT token and extract the auth payload.
/// Returns None if verification fails.
let verifyToken = async (token: string): option<authPayload> => {
  try {
    let result = await Jose.verify(token, jwtSecret)
    let payload = result["payload"]

    // Extract fields from the JWT payload JSON
    let getStr = (json, key) => {
      switch Js.Json.decodeObject(json) {
      | Some(dict) =>
        switch Js.Dict.get(dict, key) {
        | Some(v) => Js.Json.decodeString(v)->Option.getOr("")
        | None => ""
        }
      | None => ""
      }
    }

    let getInt = (json, key) => {
      switch Js.Json.decodeObject(json) {
      | Some(dict) =>
        switch Js.Dict.get(dict, key) {
        | Some(v) => Js.Json.decodeNumber(v)->Option.map(Float.toInt)->Option.getOr(3)
        | None => 3
        }
      | None => 3
      }
    }

    let getRoles = json => {
      switch Js.Json.decodeObject(json) {
      | Some(dict) =>
        switch Js.Dict.get(dict, "roles") {
        | Some(v) =>
          switch Js.Json.decodeArray(v) {
          | Some(arr) => arr->Array.map(r => Js.Json.decodeString(r)->Option.getOr(""))
          | None => []
          }
        | None => []
        }
      | None => []
      }
    }

    Some({
      userId: getStr(payload, "sub"),
      username: getStr(payload, "username"),
      roles: getRoles(payload),
      perimeter: getInt(payload, "perimeter"),
    })
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(
        exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown"),
      ),
    )
    Logger.warn(Logger.logger, "JWT verification failed", ~meta)
    None
  }
}

/// Encode an authPayload as Js.Json.t for storing in context state.
let authPayloadToJson = (payload: authPayload): Js.Json.t => {
  let dict = Js.Dict.empty()
  Js.Dict.set(dict, "userId", Js.Json.string(payload.userId))
  Js.Dict.set(dict, "username", Js.Json.string(payload.username))
  Js.Dict.set(
    dict,
    "roles",
    Js.Json.array(payload.roles->Array.map(Js.Json.string)),
  )
  Js.Dict.set(dict, "perimeter", Js.Json.number(Int.toFloat(payload.perimeter)))
  Js.Json.object_(dict)
}

/// Decode an authPayload from Js.Json.t stored in context state.
let authPayloadFromJson = (json: Js.Json.t): option<authPayload> => {
  switch Js.Json.decodeObject(json) {
  | Some(dict) => {
      let userId =
        Js.Dict.get(dict, "userId")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
      let username =
        Js.Dict.get(dict, "username")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
      let roles = switch Js.Dict.get(dict, "roles")->Option.flatMap(Js.Json.decodeArray) {
      | Some(arr) =>
        arr->Array.map(r => Js.Json.decodeString(r)->Option.getOr(""))
      | None => []
      }
      let perimeter =
        Js.Dict.get(dict, "perimeter")
        ->Option.flatMap(Js.Json.decodeNumber)
        ->Option.map(Float.toInt)
        ->Option.getOr(3)
      Some({userId, username, roles, perimeter})
    }
  | None => None
  }
}

/// Authentication middleware. Validates JWT Bearer token and attaches
/// the auth payload to ctx.state.auth.
let authMiddleware: Oak.middleware = async (ctx, next) => {
  let authHeader =
    Oak.Context.request(ctx)
    ->Oak.Context.Request.headers
    ->Oak.Context.Request.Headers.get("Authorization")
    ->Js.Nullable.toOption

  switch authHeader {
  | None | Some("") =>
    Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
    let body = Js.Dict.empty()
    Js.Dict.set(body, "error", Js.Json.string("Unauthorized"))
    Js.Dict.set(body, "message", Js.Json.string("Missing or invalid authorization header"))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  | Some(header) =>
    if !String.startsWith(header, "Bearer ") {
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Unauthorized"))
      Js.Dict.set(body, "message", Js.Json.string("Missing or invalid authorization header"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    } else {
      let token = String.sliceToEnd(header, ~start=7)
      let payload = await verifyToken(token)

      switch payload {
      | None =>
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Unauthorized"))
        Js.Dict.set(body, "message", Js.Json.string("Invalid or expired token"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      | Some(auth) =>
        Oak.Context.state(ctx)->Oak.Context.State.set("auth", authPayloadToJson(auth))
        await next()
      }
    }
  }
}

/// Role-based authorization middleware factory.
/// Returns a middleware that checks if the user has any of the required roles.
let requireRole = (roles: array<string>): Oak.middleware => {
  async (ctx, next) => {
    let authJson = Oak.Context.state(ctx)->Oak.Context.State.get("auth")
    let auth = authJson->Option.flatMap(authPayloadFromJson)

    switch auth {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Unauthorized"))
      Js.Dict.set(body, "message", Js.Json.string("Authentication required"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(auth) =>
      let hasRole = roles->Array.some(role => auth.roles->Array.includes(role))
      if !hasRole {
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(403)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Forbidden"))
        Js.Dict.set(
          body,
          "message",
          Js.Json.string(`Required roles: ${Array.join(roles, ", ")}`),
        )
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      } else {
        await next()
      }
    }
  }
}

/// TPCF perimeter authorization middleware factory.
/// Returns a middleware that checks if the user's perimeter is at or below
/// the required maximum.
let requirePerimeter = (maxPerimeter: int): Oak.middleware => {
  async (ctx, next) => {
    let authJson = Oak.Context.state(ctx)->Oak.Context.State.get("auth")
    let auth = authJson->Option.flatMap(authPayloadFromJson)

    switch auth {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Unauthorized"))
      Js.Dict.set(body, "message", Js.Json.string("Authentication required"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(auth) =>
      if auth.perimeter > maxPerimeter {
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(403)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Forbidden"))
        Js.Dict.set(
          body,
          "message",
          Js.Json.string(
            `Required perimeter: ${Int.toString(maxPerimeter)} or lower (you have ${Int.toString(auth.perimeter)})`,
          ),
        )
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      } else {
        await next()
      }
    }
  }
}
