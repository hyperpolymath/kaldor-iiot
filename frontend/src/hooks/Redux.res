// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed Redux dispatch and selector hooks for the Kaldor IIoT store.

let useAppDispatch = () => ReduxToolkit.useDispatch()

let useAppSelector = (selector: Store.rootState => 'a): 'a => {
  ReduxToolkit.useSelector(selector)
}
