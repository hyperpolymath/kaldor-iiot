// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// FFI bindings for the bcrypt password hashing library.

/// Hash a plaintext password. Returns a bcrypt hash string.
@module("bcrypt")
external hash: string => promise<string> = "hash"

/// Compare a plaintext password with a bcrypt hash.
/// Returns true if they match.
@module("bcrypt")
external compare: (string, string) => promise<bool> = "compare"
