// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Kaldor Community Manufacturing Platform — Deno Backend (ReScript).
 *
 * This module implements the central orchestrator for the Kaldor platform.
 * It integrates verified WASM kernels for compute-intensive tasks and 
 * provides a unified API for managing distributed manufacturing jobs.
 *
 * TECHNOLOGY STACK:
 * - **Oak**: High-assurance middleware-based web framework for Deno.
 * - **WASM**: Accelerated pattern generation and job scheduling.
 * - **Matter/OPC UA**: Industrial protocol support for hardware connectivity.
 */

// BOOTSTRAP: Load environment and instantiate acceleration modules.
let env = await Deno.loadEnv()

// WASM LOADING: Fetches and instantiates binary kernels for the scheduler.
let schedulerWasm = await Deno.instantiateStreaming(
  Deno.fetch(Deno.makeUrl("./wasm/scheduler.wasm", Deno.importMetaUrl)["href"]),
)

// SERVICE KERNEL: Initializes connections to the multi-protocol stack.
let db = Database.make(envGet("DATABASE_URL", "postgres://kaldor..."))
let mqtt = Mqtt.make(envGet("MQTT_URL", "mqtt://localhost:1883"))

await Database.connect(db)
await Mqtt.connect(mqtt)

/**
 * API ROUTING: Hierarchical organization of platform capabilities.
 * 
 * ENDPOINTS:
 * - `/api/v2/auth`: Identity and access management.
 * - `/api/v2/machines`: Real-time status of connected looms.
 * - `/api/v2/jobs`: Manufacturing queue management.
 * - `/api/v2/wasm/pattern-gen`: Direct interface to the WASM pattern engine.
 */
Oak.Router.use2(router, "/api/v2/machines", Auth.authMiddleware, Oak.Router.routes(MachineRoutes.router))
// ... [Remaining routes]
