// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for Deno runtime APIs.
/// Provides access to environment variables, signals, versioning, and hostname.

module Env = {
  @val @scope(("Deno", "env"))
  external get: string => Js.Nullable.t<string> = "get"
}

module Version = {
  @val @scope(("Deno", "version"))
  external deno: string = "deno"
}

@val @scope("Deno")
external hostname: unit => string = "hostname"

@val @scope("Deno")
external addSignalListener: (string, unit => unit) => unit = "addSignalListener"

@val @scope("Deno")
external exit: int => unit = "exit"

/// Load .env file using deno std library.
@module("std/dotenv/mod.ts")
external loadEnv: unit => promise<Js.Dict.t<string>> = "load"

/// WebAssembly instantiateStreaming.
@val @scope("WebAssembly")
external instantiateStreaming: promise<Fetch.Response.t> => promise<{"instance": {"exports": Js.Json.t}}> = "instantiateStreaming"

/// Fetch API.
@val external fetch: string => promise<Fetch.Response.t> = "fetch"

module Fetch = {
  module Response = {
    type t
  }
}

/// URL constructor.
@new external makeUrl: (string, string) => {"href": string} = "URL"

/// import.meta.url
@val @scope("import.meta")
external importMetaUrl: string = "url"

/// TextEncoder for encoding strings to Uint8Array.
type textEncoder
@new external makeTextEncoder: unit => textEncoder = "TextEncoder"
@send external encode: (textEncoder, string) => Js.TypedArray2.Uint8Array.t = "encode"

/// TextDecoder for decoding Uint8Array to string.
type textDecoder
@new external makeTextDecoder: unit => textDecoder = "TextDecoder"
@send external decode: (textDecoder, Js.TypedArray2.Uint8Array.t) => string = "decode"

/// setInterval for periodic callbacks.
@val external setInterval: (unit => unit, int) => float = "setInterval"

/// parseInt.
@val external parseInt: (string, ~radix: int=?) => int = "parseInt"
