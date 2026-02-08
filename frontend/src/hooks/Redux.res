// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Typed Redux dispatch and selector hooks for the Kaldor IIoT store.

let useAppDispatch = () => ReduxToolkit.useDispatch()

let useAppSelector = (selector: Store.rootState => 'a): 'a => {
  ReduxToolkit.useSelector(selector)
}
