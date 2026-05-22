// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for @mui/material components used in kaldor-iiot frontend

module Box = {
  @module("@mui/material") @react.component
  external make: (
    ~component: string=?,
    ~sx: {..}=?,
    ~display: string=?,
    ~justifyContent: string=?,
    ~alignItems: string=?,
    ~mb: int=?,
    ~mt: int=?,
    ~children: React.element=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~onSubmit: ReactEvent.Form.t => unit=?,
  ) => React.element = "Box"
}

module Container = {
  @module("@mui/material") @react.component
  external make: (
    ~maxWidth: string=?,
    ~children: React.element=?,
  ) => React.element = "Container"
}

module Typography = {
  @module("@mui/material") @react.component
  external make: (
    ~variant: string=?,
    ~component: string=?,
    ~color: string=?,
    ~align: string=?,
    ~gutterBottom: bool=?,
    ~sx: {..}=?,
    ~children: React.element=?,
  ) => React.element = "Typography"
}

module Button = {
  @module("@mui/material") @react.component
  external make: (
    ~variant: string=?,
    ~color: string=?,
    ~size: string=?,
    ~\"type": string=?,
    ~fullWidth: bool=?,
    ~disabled: bool=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~sx: {..}=?,
    ~children: React.element=?,
  ) => React.element = "Button"
}

module TextField = {
  @module("@mui/material") @react.component
  external make: (
    ~margin: string=?,
    ~required: bool=?,
    ~fullWidth: bool=?,
    ~id: string=?,
    ~label: string=?,
    ~name: string=?,
    ~\"type": string=?,
    ~autoComplete: string=?,
    ~autoFocus: bool=?,
    ~value: string=?,
    ~onChange: ReactEvent.Form.t => unit=?,
  ) => React.element = "TextField"
}

module Paper = {
  @module("@mui/material") @react.component
  external make: (
    ~elevation: int=?,
    ~sx: {..}=?,
    ~children: React.element=?,
  ) => React.element = "Paper"
}

module AppBar = {
  @module("@mui/material") @react.component
  external make: (
    ~position: string=?,
    ~children: React.element=?,
  ) => React.element = "AppBar"
}

module Toolbar = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "Toolbar"
}

module Drawer = {
  @module("@mui/material") @react.component
  external make: (
    ~\"open": bool=?,
    ~onClose: ReactEvent.Synthetic.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "Drawer"
}

module IconButton = {
  @module("@mui/material") @react.component
  external make: (
    ~edge: string=?,
    ~color: string=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~sx: {..}=?,
    ~children: React.element=?,
  ) => React.element = "IconButton"
}

module List = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "List"
}

module ListItem = {
  @module("@mui/material") @react.component
  external make: (
    ~button: bool=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "ListItem"
}

module ListItemIcon = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "ListItemIcon"
}

module ListItemText = {
  @module("@mui/material") @react.component
  external make: (~primary: string=?) => React.element = "ListItemText"
}

module Badge = {
  @module("@mui/material") @react.component
  external make: (
    ~badgeContent: int=?,
    ~color: string=?,
    ~children: React.element=?,
  ) => React.element = "Badge"
}

module Grid = {
  @module("@mui/material") @react.component
  external make: (
    ~container: bool=?,
    ~item: bool=?,
    ~spacing: int=?,
    ~xs: int=?,
    ~sm: int=?,
    ~md: int=?,
    ~sx: {..}=?,
    ~children: React.element=?,
  ) => React.element = "Grid"
}

module Card = {
  @module("@mui/material") @react.component
  external make: (
    ~sx: {..}=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "Card"
}

module CardContent = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "CardContent"
}

module Chip = {
  @module("@mui/material") @react.component
  external make: (
    ~label: string=?,
    ~color: string=?,
    ~size: string=?,
  ) => React.element = "Chip"
}

module Table = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "Table"
}

module TableHead = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "TableHead"
}

module TableBody = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "TableBody"
}

module TableRow = {
  @module("@mui/material") @react.component
  external make: (
    ~key: string=?,
    ~children: React.element=?,
  ) => React.element = "TableRow"
}

module TableCell = {
  @module("@mui/material") @react.component
  external make: (~children: React.element=?) => React.element = "TableCell"
}

module CssBaseline = {
  @module("@mui/material") @react.component
  external make: unit => React.element = "CssBaseline"
}

// MUI theme functions
type themeOptions = {
  palette: {..},
  typography: {..},
}

type theme

@module("@mui/material/styles")
external createTheme: themeOptions => theme = "createTheme"

module ThemeProvider = {
  @module("@mui/material/styles") @react.component
  external make: (~theme: theme, ~children: React.element) => React.element = "ThemeProvider"
}

// MUI Icons
module DashboardIcon = {
  @module("@mui/icons-material/Dashboard") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module ViewListIcon = {
  @module("@mui/icons-material/ViewList") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module WarningIcon = {
  @module("@mui/icons-material/Warning") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module AnalyticsIcon = {
  @module("@mui/icons-material/Analytics") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module SettingsIcon = {
  @module("@mui/icons-material/Settings") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module MenuIcon = {
  @module("@mui/icons-material/Menu") @react.component
  external make: unit => React.element = "default"
}

module ExitToAppIcon = {
  @module("@mui/icons-material/ExitToApp") @react.component
  external make: unit => React.element = "default"
}

module WarningAmberIcon = {
  @module("@mui/icons-material/WarningAmber") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module CheckCircleIcon = {
  @module("@mui/icons-material/CheckCircle") @react.component
  external make: (~color: string=?) => React.element = "default"
}

module ErrorIcon = {
  @module("@mui/icons-material/Error") @react.component
  external make: (~color: string=?) => React.element = "default"
}
