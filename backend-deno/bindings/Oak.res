// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for Oak web framework (Deno).
/// Provides types and external declarations for Application, Router, and Context.

module Context = {
  /// Opaque type for Oak Context objects.
  type t

  module Request = {
    /// Opaque type for Oak Request objects.
    type t

    module Headers = {
      /// Opaque type for HTTP Headers.
      type t

      @send external get: (t, string) => Js.Nullable.t<string> = "get"
      @send external set: (t, string, string) => unit = "set"
    }

    @get external headers: t => Headers.t = "headers"
    @get external method: t => string = "method"
    @get external ip: t => Js.Nullable.t<string> = "ip"

    module Url = {
      type t
      @get external pathname: t => string = "pathname"
    }

    @get external url: t => Url.t = "url"

    /// Call ctx.request.body({ type: 'json' }).value to get parsed JSON body.
    @send external body: (t, {"type": string}) => {"value": promise<Js.Json.t>} = "body"
  }

  module Response = {
    /// Opaque type for Oak Response objects.
    type t

    @set external setBody: (t, Js.Json.t) => unit = "body"
    @set external setStatus: (t, int) => unit = "status"

    module Headers = {
      type t
      @send external set: (t, string, string) => unit = "set"
    }

    @get external headers: t => Headers.t = "headers"
  }

  @get external request: t => Request.t = "request"
  @get external response: t => Response.t = "response"
  @get external params: t => Js.Dict.t<string> = "params"

  module State = {
    /// Opaque type for context state storage.
    type t

    @get_index external get: (t, string) => option<Js.Json.t> = ""
    @set_index external set: (t, string, Js.Json.t) => unit = ""
  }

  @get external state: t => State.t = "state"
}

/// Type for Oak middleware next() function.
type next = unit => promise<unit>

/// Type alias for middleware functions.
type middleware = (Context.t, next) => promise<unit>

module Router = {
  /// Opaque type for Oak Router objects.
  type t

  module Routes = {
    /// Opaque type for the return value of router.routes().
    type t
  }

  module AllowedMethods = {
    /// Opaque type for the return value of router.allowedMethods().
    type t
  }

  @module("oak") @new external make: unit => t = "Router"

  @send external get: (t, string, middleware) => unit = "get"
  @send external post: (t, string, middleware) => unit = "post"
  @send external put: (t, string, middleware) => unit = "put"
  @send external delete: (t, string, middleware) => unit = "delete"

  /// Mount a sub-router's routes at a path prefix.
  @send external use1: (t, string, Routes.t) => unit = "use"

  /// Mount a middleware then sub-router routes at a path prefix.
  @send external use2: (t, string, middleware, Routes.t) => unit = "use"

  @send external routes: t => Routes.t = "routes"
  @send external allowedMethods: t => AllowedMethods.t = "allowedMethods"
}

module Application = {
  /// Opaque type for Oak Application objects.
  type t

  @module("oak") @new external make: unit => t = "Application"

  /// Register middleware on the application.
  @send external useMiddleware: (t, middleware) => unit = "use"

  /// Register router routes on the application.
  @send external useRoutes: (t, Router.Routes.t) => unit = "use"

  /// Register router allowed methods on the application.
  @send external useAllowedMethods: (t, Router.AllowedMethods.t) => unit = "use"

  /// Listen on a port.
  @send external listen: (t, {"port": int}) => promise<unit> = "listen"

  /// Add an event listener (e.g. 'listen').
  type listenEvent = {
    hostname: string,
    port: int,
    secure: bool,
  }

  @send
  external addEventListener: (t, string, listenEvent => unit) => unit = "addEventListener"
}

/// CORS middleware from deno.land/x/cors.
@module("https://deno.land/x/cors@v1.2.2/mod.ts")
external oakCors: {"origin": string, "credentials": bool} => middleware = "oakCors"

/// Check if an error is an Oak HTTP error.
@module("oak") external isHttpError: Js.Exn.t => bool = "isHttpError"

/// Get status code from HTTP error.
@get external httpErrorStatus: Js.Exn.t => int = "status"
