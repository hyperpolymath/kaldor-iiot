// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Settings page placeholder for system configuration.

@react.component
let make = () => {
  <Mui.Box>
    <Mui.Typography variant="h4" gutterBottom={true}>
      {React.string("Settings")}
    </Mui.Typography>
    <Mui.Typography>
      {React.string("System configuration and preferences...")}
    </Mui.Typography>
  </Mui.Box>
}
