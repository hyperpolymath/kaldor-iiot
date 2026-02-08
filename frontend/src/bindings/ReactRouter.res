// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for react-router-dom v6

module BrowserRouter = {
  @module("react-router-dom") @react.component
  external make: (~children: React.element) => React.element = "BrowserRouter"
}

module Routes = {
  @module("react-router-dom") @react.component
  external make: (~children: React.element) => React.element = "Routes"
}

module Route = {
  @module("react-router-dom") @react.component
  external make: (~path: string, ~element: React.element) => React.element = "Route"
}

module Navigate = {
  @module("react-router-dom") @react.component
  external make: (~\"to": string, ~replace: bool=?) => React.element = "Navigate"
}

module Link = {
  @module("react-router-dom") @react.component
  external make: (~\"to": string, ~children: React.element) => React.element = "Link"
}

@module("react-router-dom")
external useNavigate: unit => string => unit = "useNavigate"

type params = {id: string}

@module("react-router-dom")
external useParams: unit => params = "useParams"

type location = {pathname: string}

@module("react-router-dom")
external useLocation: unit => location = "useLocation"
