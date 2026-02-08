// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for react-toastify

module ToastContainer = {
  @module("react-toastify") @react.component
  external make: (
    ~position: string=?,
    ~autoClose: int=?,
    ~hideProgressBar: bool=?,
    ~newestOnTop: bool=?,
    ~closeOnClick: bool=?,
    ~rtl: bool=?,
    ~pauseOnFocusLoss: bool=?,
    ~draggable: bool=?,
    ~pauseOnHover: bool=?,
  ) => React.element = "ToastContainer"
}

type toastOptions = {
  position: string,
  autoClose: int,
}

@module("react-toastify")
external toastSuccess: string => unit = "toast.success"

@module("react-toastify")
external toastError: string => unit = "toast.error"

@module("react-toastify")
external toastWarning: string => unit = "toast.warning"

@module("react-toastify")
external toastWarningWithOptions: (string, toastOptions) => unit = "toast.warning"
