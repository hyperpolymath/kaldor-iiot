// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Pattern generation routes.
/// 3D weave patterns, WASM-accelerated computation.

/// Simulated pattern storage.
let patterns: Js.Dict.t<Js.Json.t> = Js.Dict.empty()

/// Helper to extract a string field from parsed JSON.
let getStr = (json: Js.Json.t, key: string): option<string> => {
  switch Js.Json.decodeObject(json) {
  | Some(dict) => Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeString)
  | None => None
  }
}

/// Helper to extract a numeric field from parsed JSON.
let getNum = (json: Js.Json.t, key: string): option<float> => {
  switch Js.Json.decodeObject(json) {
  | Some(dict) => Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeNumber)
  | None => None
  }
}

/// Create and configure the pattern routes router.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // GET / - List all patterns
  Oak.Router.get(router, "/", async (ctx, _next) => {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "patterns", Js.Json.array(Js.Dict.values(patterns)))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  // POST /generate - Generate a new pattern
  Oak.Router.post(router, "/generate", async (ctx, _next) => {
    let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
    let json = await bodyObj["value"]

    let warp = getNum(json, "warp")
    let weft = getNum(json, "weft")
    let type_ = getStr(json, "type")

    switch (warp, weft, type_) {
    | (Some(warp), Some(weft), Some(type_)) => {
        let patternId = `pattern-${%raw(`Date.now().toString(36)`)}`

        let pattern = Js.Dict.empty()
        Js.Dict.set(pattern, "id", Js.Json.string(patternId))
        Js.Dict.set(pattern, "warp", Js.Json.number(warp))
        Js.Dict.set(pattern, "weft", Js.Json.number(weft))
        Js.Dict.set(pattern, "type", Js.Json.string(type_))
        Js.Dict.set(pattern, "data", Js.Json.array([]))
        Js.Dict.set(pattern, "createdAt", Js.Json.string(Js.Date.make()->Js.Date.toISOString))

        let patternJson = Js.Json.object_(pattern)
        Js.Dict.set(patterns, patternId, patternJson)

        let meta = Js.Dict.empty()
        Js.Dict.set(meta, "patternId", Js.Json.string(patternId))
        Js.Dict.set(meta, "type", Js.Json.string(type_))
        Logger.info(Logger.logger, "Pattern generated", ~meta)

        Oak.Context.response(ctx)->Oak.Context.Response.setStatus(201)
        Oak.Context.response(ctx)->Oak.Context.Response.setBody(patternJson)
      }
    | _ =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(400)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("warp, weft, and type required"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    }
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
