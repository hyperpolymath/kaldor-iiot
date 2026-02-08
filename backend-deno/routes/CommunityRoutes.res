// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Community routes.
/// Network statistics, node discovery, community metrics.

/// Create and configure the community routes router.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // GET /stats - Community statistics
  Oak.Router.get(router, "/stats", async (ctx, _next) => {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "nodes", Js.Json.number(12.0))
    Js.Dict.set(body, "activeDevices", Js.Json.number(36.0))
    Js.Dict.set(body, "totalProduction", Js.Json.number(450.0))
    Js.Dict.set(body, "communitySize", Js.Json.number(25.0))
    Js.Dict.set(body, "kaldorCoefficient", Js.Json.number(0.52))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  // GET /nodes - Community nodes
  Oak.Router.get(router, "/nodes", async (ctx, _next) => {
    let node1 = Js.Dict.empty()
    Js.Dict.set(node1, "id", Js.Json.string("node-1"))
    Js.Dict.set(node1, "type", Js.Json.string("household"))
    Js.Dict.set(node1, "devices", Js.Json.number(3.0))
    Js.Dict.set(node1, "status", Js.Json.string("online"))

    let node2 = Js.Dict.empty()
    Js.Dict.set(node2, "id", Js.Json.string("node-2"))
    Js.Dict.set(node2, "type", Js.Json.string("social-enterprise"))
    Js.Dict.set(node2, "devices", Js.Json.number(9.0))
    Js.Dict.set(node2, "status", Js.Json.string("online"))

    let body = Js.Dict.empty()
    Js.Dict.set(
      body,
      "nodes",
      Js.Json.array([Js.Json.object_(node1), Js.Json.object_(node2)]),
    )
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
