// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for the jose JWT library.
/// Provides JWT creation and verification.

/// Create a JWT token.
/// create(header, payload, secret) => promise<string>
@module("jose")
external create: ({"alg": string}, Js.Json.t, Js.TypedArray2.Uint8Array.t) => promise<string> =
  "create"

/// Verify a JWT token.
/// verify(token, secret) => promise<{ payload: Js.Json.t }>
@module("jose")
external verify: (
  string,
  Js.TypedArray2.Uint8Array.t,
) => promise<{"payload": Js.Json.t}> = "verify"

/// Get a numeric date value (seconds since epoch + offset).
@module("jose")
external getNumericDate: int => int = "getNumericDate"
