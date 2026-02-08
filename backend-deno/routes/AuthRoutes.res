// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Authentication routes.
/// Login, logout, token refresh.

/// Helper to extract a string field from a parsed JSON body.
let getStr = (json: Js.Json.t, key: string): option<string> => {
  switch Js.Json.decodeObject(json) {
  | Some(dict) => Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeString)
  | None => None
  }
}

/// Create and configure the auth router with all authentication endpoints.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // POST /register
  Oak.Router.post(router, "/register", async (ctx, _next) => {
    let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
    let json = await bodyObj["value"]

    let username = getStr(json, "username")
    let password = getStr(json, "password")

    switch (username, password) {
    | (Some(username), Some(password)) =>
      try {
        let _passwordHash = await Bcrypt.hash(password)

        // Simulated user creation
        let userId = `user-${%raw(`Date.now().toString(36)`)}`

        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "userId", Js.Json.string(userId))
        Js.Dict.set(meta, "username", Js.Json.string(username))
        Logger.info(Logger.logger, "User registered", ~meta)

        let body = Js.Dict.empty()
        Js.Dict.set(body, "success", Js.Json.boolean(true))
        Js.Dict.set(body, "userId", Js.Json.string(userId))
        Js.Dict.set(body, "message", Js.Json.string("User registered successfully"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      } catch {
      | _exn =>
        Logger.error(Logger.logger, "Registration failed")
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Registration failed"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      }
    | _ =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Username and password required"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // POST /login
  Oak.Router.post(router, "/login", async (ctx, _next) => {
    let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
    let json = await bodyObj["value"]

    let username = getStr(json, "username")
    let password = getStr(json, "password")

    switch (username, password) {
    | (Some(username), Some(password)) =>
      try {
        // Simulated user lookup (in production: fetch from database)
        let passwordHash = await Bcrypt.hash(password)
        let valid = await Bcrypt.compare(password, passwordHash)

        if !valid {
          Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
          let body = Js.Dict.empty()
          Js.Dict.set(body, "error", Js.Json.string("Invalid credentials"))
          Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
        } else {
          let payload: Auth.authPayload = {
            userId: "user-demo",
            username,
            roles: ["user"],
            perimeter: 3,
          }

          let token = await Auth.generateToken(payload)

          let meta = Js.Dict.empty()
          Js.Dict.set(meta, "userId", Js.Json.string("user-demo"))
          Js.Dict.set(meta, "username", Js.Json.string(username))
          Logger.info(Logger.logger, "User logged in", ~meta)

          let userObj = Js.Dict.empty()
          Js.Dict.set(userObj, "id", Js.Json.string("user-demo"))
          Js.Dict.set(userObj, "username", Js.Json.string(username))
          Js.Dict.set(
            userObj,
            "roles",
            Js.Json.array(["user"]->Array.map(Js.Json.string)),
          )
          Js.Dict.set(userObj, "perimeter", Js.Json.number(3.0))

          let body = Js.Dict.empty()
          Js.Dict.set(body, "success", Js.Json.boolean(true))
          Js.Dict.set(body, "token", Js.Json.string(token))
          Js.Dict.set(body, "user", Js.Json.object_(userObj))
          Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
        }
      } catch {
      | _exn =>
        Logger.error(Logger.logger, "Login failed")
        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(500)
        let body = Js.Dict.empty()
        Js.Dict.set(body, "error", Js.Json.string("Login failed"))
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
      }
    | _ =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Username and password required"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  // POST /logout
  Oak.Router.post(router, "/logout", async (ctx, _next) => {
    Logger.info(Logger.logger, "User logged out")

    let body = Js.Dict.empty()
    Js.Dict.set(body, "success", Js.Json.boolean(true))
    Js.Dict.set(body, "message", Js.Json.string("Logged out successfully"))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  // GET /me
  Oak.Router.get(router, "/me", async (ctx, _next) => {
    let authJson = Oak.Context.state(ctx)->Oak.Context.State.get("auth")
    let auth = authJson->Option.flatMap(Auth.authPayloadFromJson)

    switch auth {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(401)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Not authenticated"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(authData) =>
      let body = Js.Dict.empty()
      Js.Dict.set(body, "user", Auth.authPayloadToJson(authData))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
