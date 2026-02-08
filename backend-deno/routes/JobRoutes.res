// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Job queue routes.
/// Manage manufacturing jobs (spinning, weaving, printing).

/// Simulated job storage.
let jobs: Js.Dict.t<Js.Json.t> = Js.Dict.empty()

/// Create and configure the job routes router.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // GET / - List all jobs
  Oak.Router.get(router, "/", async (ctx, _next) => {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "jobs", Js.Json.array(Js.Dict.values(jobs)))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  // POST / - Create a new job
  Oak.Router.post(router, "/", async (ctx, _next) => {
    let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
    let json = await bodyObj["value"]

    let jobId = `job-${%raw(`Date.now().toString(36)`)}`

    // Merge the body with job metadata
    let job: Js.Json.t = %raw(`Object.assign({}, json, {
      id: jobId,
      status: "queued",
      createdAt: new Date().toISOString()
    })`)

    Js.Dict.set(jobs, jobId, job)

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "jobId", Js.Json.string(jobId))
    Logger.info(Logger.logger, "Job created", ~meta)

    Oak.Context.response(ctx)->Oak.Context.Response.setStatus(201)
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(job)
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
