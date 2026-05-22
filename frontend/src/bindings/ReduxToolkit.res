// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for @reduxjs/toolkit and react-redux

// Generic store type - opaque
type store

// Generic dispatch type
type dispatch = {..} => unit

module Provider = {
  @module("react-redux") @react.component
  external make: (~store: store, ~children: React.element) => React.element = "Provider"
}

@module("react-redux")
external useDispatch: unit => dispatch = "useDispatch"

@module("react-redux")
external useSelector: ('state => 'a) => 'a = "useSelector"
