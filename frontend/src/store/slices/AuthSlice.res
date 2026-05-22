// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed ReScript interface for the auth Redux slice.
// The actual reducer logic lives in authSlice.js (Immer-based).

type user = {
  id: int,
  username: string,
  email: string,
  role: string,
}

type authState = {
  isAuthenticated: bool,
  token: Nullable.t<string>,
  user: Nullable.t<user>,
  loading: bool,
  error: Nullable.t<string>,
}

type loginPayload = {
  token: string,
  user: user,
}

// Action creators imported from the JS wrapper
@module("./authSlice.js")
external loginStart: unit => {..} = "loginStart"

@module("./authSlice.js")
external loginSuccess: loginPayload => {..} = "loginSuccess"

@module("./authSlice.js")
external loginFailure: string => {..} = "loginFailure"

@module("./authSlice.js")
external logout: unit => {..} = "logout"

// Default export is the reducer
@module("./authSlice.js")
external reducer: (authState, {..}) => authState = "default"
