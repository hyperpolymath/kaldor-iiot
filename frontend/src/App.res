// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Root application component. Handles authentication gating and
// WebSocket lifecycle. Routes authenticated users through Layout.

@react.component
let make = () => {
  let dispatch = Redux.useAppDispatch()
  let authState = Redux.useAppSelector(state => state.auth)

  React.useEffect2(() => {
    if authState.isAuthenticated {
      switch Nullable.toOption(authState.token) {
      | Some(token) => {
          let _ = Websocket.connectWebSocket(token, dispatch)
          Some(() => Websocket.disconnectWebSocket())
        }
      | None => None
      }
    } else {
      None
    }
  }, (authState.isAuthenticated, authState.token))

  if !authState.isAuthenticated {
    <Login />
  } else {
    <Layout>
      <ReactRouter.Routes>
        <ReactRouter.Route path="/" element={<Dashboard />} />
        <ReactRouter.Route path="/loom/:id" element={<LoomDetail />} />
        <ReactRouter.Route path="/alerts" element={<Alerts />} />
        <ReactRouter.Route path="/analytics" element={<Analytics />} />
        <ReactRouter.Route path="/settings" element={<Settings />} />
        <ReactRouter.Route path="*" element={<ReactRouter.Navigate \"to"="/" replace={true} />} />
      </ReactRouter.Routes>
    </Layout>
  }
}
