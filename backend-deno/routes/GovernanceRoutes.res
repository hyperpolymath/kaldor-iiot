// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Governance routes.
/// CURP consensus, quadratic voting, proposals.

/// Simulated proposal storage.
let proposals: Js.Dict.t<Js.Json.t> = Js.Dict.empty()

/// Create and configure the governance routes router.
let makeRouter = (): Oak.Router.t => {
  let router = Oak.Router.make()

  // GET /proposals - List all proposals
  Oak.Router.get(router, "/proposals", async (ctx, _next) => {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "proposals", Js.Json.array(Js.Dict.values(proposals)))
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
  })

  // POST /proposals - Create a new proposal
  Oak.Router.post(router, "/proposals", async (ctx, _next) => {
    let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
    let json = await bodyObj["value"]

    let proposalId = `prop-${%raw(`Date.now().toString(36)`)}`

    // Merge body with proposal metadata
    let proposal: Js.Json.t = %raw(`Object.assign({}, json, {
      id: proposalId,
      votes: [],
      status: "active",
      createdAt: new Date().toISOString()
    })`)

    Js.Dict.set(proposals, proposalId, proposal)

    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "proposalId", Js.Json.string(proposalId))
    Logger.info(Logger.logger, "Proposal created", ~meta)

    Oak.Context.response(ctx)->Oak.Context.Response.setStatus(201)
    Oak.Context.response(ctx)->Oak.Context.Response.setBody(proposal)
  })

  // POST /proposals/:id/vote - Vote on a proposal
  Oak.Router.post(router, "/proposals/:id/vote", async (ctx, _next) => {
    let id = Js.Dict.get(Oak.Context.params(ctx), "id")->Option.getOr("")

    switch Js.Dict.get(proposals, id) {
    | None =>
      Oak.Context.response(ctx)->Oak.Context.Response.setStatus(404)
      let body = Js.Dict.empty()
      Js.Dict.set(body, "error", Js.Json.string("Proposal not found"))
      Oak.Context.response(ctx)->Oak.Context.Response.setBody(Js.Json.object_(body))
    | Some(proposal) =>
      let bodyObj = Oak.Context.request(ctx)->Oak.Context.Request.body({"type": "json"})
      let json = await bodyObj["value"]

      // Add vote with timestamp to the proposal
      let updated: Js.Json.t = %raw(`(() => {
        const p = Object.assign({}, proposal);
        const vote = Object.assign({}, json, { timestamp: Date.now() });
        p.votes = [...(p.votes || []), vote];
        return p;
      })()`)

      Js.Dict.set(proposals, id, updated)

      let meta = Js.Dict.empty()
      Js.Dict.set(meta, "proposalId", Js.Json.string(id))
      Logger.info(Logger.logger, "Vote cast", ~meta)

      Oak.Context.response(ctx)->Oak.Context.Response.setBody(updated)
    }
  })

  router
}

/// Pre-built router instance.
let router = makeRouter()
