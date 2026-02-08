// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// FFI bindings for recharts

module ResponsiveContainer = {
  @module("recharts") @react.component
  external make: (
    ~width: string=?,
    ~height: int=?,
    ~children: React.element=?,
  ) => React.element = "ResponsiveContainer"
}

module LineChart = {
  @module("recharts") @react.component
  external make: (
    ~data: array<'a>=?,
    ~children: React.element=?,
  ) => React.element = "LineChart"
}

module Line = {
  @module("recharts") @react.component
  external make: (
    ~\"type": string=?,
    ~dataKey: string=?,
    ~stroke: string=?,
    ~name: string=?,
  ) => React.element = "Line"
}

module XAxis = {
  @module("recharts") @react.component
  external make: (~dataKey: string=?) => React.element = "XAxis"
}

module YAxis = {
  @module("recharts") @react.component
  external make: unit => React.element = "YAxis"
}

module CartesianGrid = {
  @module("recharts") @react.component
  external make: (~strokeDasharray: string=?) => React.element = "CartesianGrid"
}

module Tooltip = {
  @module("recharts") @react.component
  external make: unit => React.element = "Tooltip"
}

module Legend = {
  @module("recharts") @react.component
  external make: unit => React.element = "Legend"
}

module BarChart = {
  @module("recharts") @react.component
  external make: (
    ~data: array<'a>=?,
    ~children: React.element=?,
  ) => React.element = "BarChart"
}

module Bar = {
  @module("recharts") @react.component
  external make: (
    ~dataKey: string=?,
    ~fill: string=?,
    ~name: string=?,
  ) => React.element = "Bar"
}

module PieChart = {
  @module("recharts") @react.component
  external make: (~children: React.element=?) => React.element = "PieChart"
}

module Pie = {
  @module("recharts") @react.component
  external make: (
    ~data: array<'a>=?,
    ~dataKey: string=?,
    ~cx: string=?,
    ~cy: string=?,
    ~outerRadius: int=?,
    ~fill: string=?,
    ~children: React.element=?,
  ) => React.element = "Pie"
}

module Cell = {
  @module("recharts") @react.component
  external make: (~fill: string=?) => React.element = "Cell"
}
