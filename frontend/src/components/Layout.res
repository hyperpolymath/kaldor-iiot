// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Layout wrapper with MUI AppBar, navigation Drawer, and main content area.

// Menu item record type for the sidebar navigation
type menuItem = {
  text: string,
  icon: React.element,
  path: string,
}

@react.component
let make = (~children: React.element) => {
  let (drawerOpen, setDrawerOpen) = React.useState(() => false)
  let navigate = ReactRouter.useNavigate()
  let dispatch = Redux.useAppDispatch()
  let alertsState = Redux.useAppSelector(state => state.alerts)

  let menuItems: array<menuItem> = [
    {text: "Dashboard", icon: <Mui.DashboardIcon />, path: "/"},
    {text: "Looms", icon: <Mui.ViewListIcon />, path: "/looms"},
    {
      text: "Alerts",
      icon: <Mui.Badge badgeContent={alertsState.unacknowledgedCount} color="error">
        <Mui.WarningIcon />
      </Mui.Badge>,
      path: "/alerts",
    },
    {text: "Analytics", icon: <Mui.AnalyticsIcon />, path: "/analytics"},
    {text: "Settings", icon: <Mui.SettingsIcon />, path: "/settings"},
  ]

  let handleLogout = _event => {
    dispatch(AuthSlice.logout())
  }

  <Mui.Box sx={{"display": "flex"}}>
    <Mui.AppBar position="fixed">
      <Mui.Toolbar>
        <Mui.IconButton
          edge="start"
          color="inherit"
          onClick={_event => setDrawerOpen(prev => !prev)}
          sx={{"mr": 2}}>
          <Mui.MenuIcon />
        </Mui.IconButton>
        <Mui.Typography variant="h6" sx={{"flexGrow": 1}}>
          {React.string("Kaldor IIoT")}
        </Mui.Typography>
        <Mui.IconButton color="inherit" onClick={handleLogout}>
          <Mui.ExitToAppIcon />
        </Mui.IconButton>
      </Mui.Toolbar>
    </Mui.AppBar>
    <Mui.Drawer \"open"={drawerOpen} onClose={_event => setDrawerOpen(_ => false)}>
      <Mui.Box sx={{"width": 250, "mt": 8}}>
        <Mui.List>
          {menuItems
          ->Array.map(item =>
            <Mui.ListItem
              key={item.text}
              button={true}
              onClick={_event => {
                navigate(item.path)
                setDrawerOpen(_ => false)
              }}>
              <Mui.ListItemIcon> {item.icon} </Mui.ListItemIcon>
              <Mui.ListItemText primary={item.text} />
            </Mui.ListItem>
          )
          ->React.array}
        </Mui.List>
      </Mui.Box>
    </Mui.Drawer>
    <Mui.Box component="main" sx={{"flexGrow": 1, "p": 3, "mt": 8}}>
      {children}
    </Mui.Box>
  </Mui.Box>
}
