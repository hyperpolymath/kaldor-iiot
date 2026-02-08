// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Kaldor Community Manufacturing Platform
/// Deno Backend Server
///
/// A hyperlocal, community-governed textile manufacturing system
/// Supporting Kaldor's Law 2: Productivity growth through manufacturing scale
///
/// @version 2.0.0

// --- Load environment variables ---
let env = await Deno.loadEnv()

/// Helper to get env var with fallback.
let envGet = (key: string, default: string): string => {
  switch Js.Dict.get(env, key) {
  | Some(v) if v !== "" => v
  | _ => default
  }
}

// --- Initialize application ---
let app = Oak.Application.make()
let router = Oak.Router.make()

// --- WASM module initialization ---
Logger.info(Logger.logger, "Loading WASM acceleration modules...")

let patternGenWasm = await Deno.instantiateStreaming(
  Deno.fetch(Deno.makeUrl("./wasm/pattern_gen.wasm", Deno.importMetaUrl)["href"]),
)
let schedulerWasm = await Deno.instantiateStreaming(
  Deno.fetch(Deno.makeUrl("./wasm/scheduler.wasm", Deno.importMetaUrl)["href"]),
)

Logger.info(Logger.logger, "WASM modules loaded")

// --- Initialize services ---
Logger.info(Logger.logger, "Initializing services...")

let db = Database.make(envGet("DATABASE_URL", "postgres://kaldor:password@localhost:5432/kaldor"))
let redis = Redis.make(envGet("REDIS_URL", "redis://localhost:6379"))
let mqtt = Mqtt.make(envGet("MQTT_URL", "mqtt://localhost:1883"))
let matter = Matter.make(envGet("MATTER_PORT", "5540"))
let opcua = Opcua.make(envGet("OPCUA_PORT", "4840"))

await Database.connect(db)
await Redis.connect(redis)
await Mqtt.connect(mqtt)
await Matter.start(matter)
await Opcua.start(opcua)

Logger.info(Logger.logger, "All services connected")

// --- Global middleware ---
Oak.Application.useMiddleware(
  app,
  Oak.oakCors({
    "origin": envGet("CORS_ORIGIN", "*"),
    "credentials": true,
  }),
)

Oak.Application.useMiddleware(app, Error.errorHandler)
Oak.Application.useMiddleware(app, RateLimit.rateLimit(~windowMs=15 * 60 * 1000, ~max=100))

// --- Health check endpoint ---
Oak.Router.get(router, "/health", async (ctx, _next) => {
  let services = Js.Dict.empty()
  Js.Dict.set(services, "database", Js.Json.boolean(Database.isConnected(db)))
  Js.Dict.set(services, "redis", Js.Json.boolean(Redis.isConnected(redis)))
  Js.Dict.set(services, "mqtt", Js.Json.boolean(Mqtt.isConnected(mqtt)))
  Js.Dict.set(services, "matter", Js.Json.boolean(Matter.isRunning(matter)))
  Js.Dict.set(services, "opcua", Js.Json.boolean(Opcua.isRunning(opcua)))

  let body = Js.Dict.empty()
  Js.Dict.set(body, "status", Js.Json.string("healthy"))
  Js.Dict.set(body, "timestamp", Js.Json.string(Js.Date.make()->Js.Date.toISOString))
  Js.Dict.set(body, "services", Js.Json.object_(services))
  Js.Dict.set(body, "kaldor_law", Js.Json.number(2.0))
  Js.Dict.set(body, "version", Js.Json.string("2.0.0"))
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
})

// --- API routes (protected by auth middleware where needed) ---
Oak.Router.use1(router, "/api/v2/auth", Oak.Router.routes(AuthRoutes.router))
Oak.Router.use2(
  router,
  "/api/v2/machines",
  Auth.authMiddleware,
  Oak.Router.routes(MachineRoutes.router),
)
Oak.Router.use2(
  router,
  "/api/v2/jobs",
  Auth.authMiddleware,
  Oak.Router.routes(JobRoutes.router),
)
Oak.Router.use2(
  router,
  "/api/v2/community",
  Auth.authMiddleware,
  Oak.Router.routes(CommunityRoutes.router),
)
Oak.Router.use2(
  router,
  "/api/v2/governance",
  Auth.authMiddleware,
  Oak.Router.routes(GovernanceRoutes.router),
)
Oak.Router.use2(
  router,
  "/api/v2/patterns",
  Auth.authMiddleware,
  Oak.Router.routes(PatternRoutes.router),
)

// --- WASM endpoints for compute-intensive operations ---
Oak.Router.post(router, "/api/v2/wasm/pattern-gen", async (ctx, _next) => {
  let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
  let json = await bodyObj["value"]

  // Call WASM module for fast pattern generation
  let result: Js.Json.t = %raw(`patternGenWasm.instance.exports.generate_pattern(
    json.warp, json.weft, json.pattern_type
  )`)

  let body = Js.Dict.empty()
  Js.Dict.set(body, "pattern", result)
  Js.Dict.set(body, "computed_by", Js.Json.string("wasm"))
  Js.Dict.set(body, "performance", Js.Json.string("optimized"))
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
})

Oak.Router.post(router, "/api/v2/wasm/schedule", async (ctx, _next) => {
  let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
  let jobs = await bodyObj["value"]

  // Use WASM scheduler for optimal job allocation
  let schedule: Js.Json.t = %raw(`schedulerWasm.instance.exports.optimize_schedule(jobs)`)

  let body = Js.Dict.empty()
  Js.Dict.set(body, "schedule", schedule)
  Js.Dict.set(body, "algorithm", Js.Json.string("wasm-genetic-algorithm"))
  Js.Dict.set(body, "optimized_for", Js.Json.string("kaldors-law-productivity"))
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
})

// --- Matter device endpoints ---
Oak.Router.get(router, "/api/v2/matter/devices", async (ctx, _next) => {
  let devices = Matter.getDevices(matter)
  // Convert matterDevice array to JSON
  let devicesJson: Js.Json.t = %raw(`devices`)
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(devicesJson)
})

Oak.Router.post(router, "/api/v2/matter/commission", async (ctx, _next) => {
  let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
  let json = await bodyObj["value"]

  let deviceCode = switch Js.Json.decodeObject(json) {
  | Some(dict) => Js.Dict.get(dict, "deviceCode")->Option.flatMap(Js.Json.decodeString)->Option.getOr("")
  | None => ""
  }

  let result = await Matter.commissionDevice(matter, deviceCode)
  let resultJson: Js.Json.t = %raw(`result`)
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(resultJson)
})

// --- OPC UA endpoint information ---
Oak.Router.get(router, "/api/v2/opcua/info", async (ctx, _next) => {
  let hostname = Deno.hostname()
  let opcuaPort = envGet("OPCUA_PORT", "4840")

  let body = Js.Dict.empty()
  Js.Dict.set(body, "endpoint", Js.Json.string(`opc.tcp://${hostname}:${opcuaPort}`))
  Js.Dict.set(body, "namespace", Js.Json.string("http://kaldor.community/manufacturing/"))
  Js.Dict.set(body, "security_mode", Js.Json.string("SignAndEncrypt"))
  Js.Dict.set(body, "authentication", Js.Json.string("UserNamePassword"))
  Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
})

// --- Apply routes ---
Oak.Application.useRoutes(app, Oak.Router.routes(router))
Oak.Application.useAllowedMethods(app, Oak.Router.allowedMethods(router))

// --- Listen event handler (startup banner) ---
Oak.Application.addEventListener(app, "listen", ({hostname, port, secure}) => {
  let protocol = if secure { "https" } else { "http" }
  let opcuaPort = envGet("OPCUA_PORT", "4840")

  Logger.info(
    Logger.logger,
    `
Kaldor Community Manufacturing Platform v2.0

Backend: Deno ${Deno.Version.deno}
Runtime: WASM-accelerated, RISC-V ready
License: PMPL-1.0-or-later

Server running at: ${protocol}://${hostname}:${Int.toString(port)}

Services:
  PostgreSQL + TimescaleDB
  Redis cache
  MQTT broker
  Matter protocol bridge
  OPC UA server (port ${opcuaPort})

API Documentation: ${protocol}://${hostname}:${Int.toString(port)}/api-docs

Kaldor's Law 2: "The rate of growth in productivity is positively
related to the rate of growth of manufacturing output."

Press Ctrl+C to stop
`,
  )
})

// --- Graceful shutdown ---
let shutdown = async () => {
  Logger.info(Logger.logger, "Shutting down gracefully...")

  await Mqtt.disconnect(mqtt)
  await Matter.stop(matter)
  await Opcua.stop(opcua)
  await Redis.disconnect(redis)
  await Database.disconnect(db)

  Logger.info(Logger.logger, "All services stopped")
  Deno.exit(0)
}

// Note: Deno.addSignalListener expects a synchronous callback, so we
// fire-and-forget the async shutdown.
Deno.addSignalListener("SIGINT", () => {
  let _ = shutdown()
})
Deno.addSignalListener("SIGTERM", () => {
  let _ = shutdown()
})

// --- Start server ---
let port = Deno.parseInt(envGet("PORT", "8000"))
await Oak.Application.listen(app, {"port": port})
