// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Login page with username/password form and Redux auth integration.

// Helper to extract target value from form event
@get
external formEventTargetValue: ReactEvent.Form.t => string = "target.value"

@react.component
let make = () => {
  let dispatch = Redux.useAppDispatch()
  let (username, setUsername) = React.useState(() => "")
  let (password, setPassword) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => false)

  let handleSubmit = event => {
    ReactEvent.Form.preventDefault(event)
    setLoading(_ => true)
    dispatch(AuthSlice.loginStart())

    let _ = Api.AuthAPI.login(username, password)
    ->Promise.then(response => {
      let data = response.data.data
      dispatch(
        AuthSlice.loginSuccess({
          token: data["token"],
          user: {
            id: data["user"]["id"],
            username: data["user"]["username"],
            email: data["user"]["email"],
            role: data["user"]["role"],
          },
        }),
      )
      ReactToastify.toastSuccess("Login successful!")
      Promise.resolve()
    })
    ->Promise.catch(error => {
      let message = "Login failed"
      dispatch(AuthSlice.loginFailure(message))
      ReactToastify.toastError(message)
      setLoading(_ => false)
      let _ = error
      Promise.resolve()
    })
  }

  <Mui.Container maxWidth="sm">
    <Mui.Box
      sx={{
        "marginTop": 8,
        "display": "flex",
        "flexDirection": "column",
        "alignItems": "center",
      }}>
      <Mui.Paper elevation={3} sx={{"p": 4, "width": "100%"}}>
        <Mui.Typography component="h1" variant="h4" align="center" gutterBottom={true}>
          {React.string("Kaldor IIoT")}
        </Mui.Typography>
        <Mui.Typography variant="h6" align="center" color="textSecondary" gutterBottom={true}>
          {React.string("Loom Monitoring System")}
        </Mui.Typography>
        <Mui.Box component="form" onSubmit={handleSubmit} sx={{"mt": 3}}>
          <Mui.TextField
            margin="normal"
            required={true}
            fullWidth={true}
            id="username"
            label="Username"
            name="username"
            autoComplete="username"
            autoFocus={true}
            value={username}
            onChange={e => setUsername(_ => formEventTargetValue(e))}
          />
          <Mui.TextField
            margin="normal"
            required={true}
            fullWidth={true}
            name="password"
            label="Password"
            \"type"="password"
            id="password"
            autoComplete="current-password"
            value={password}
            onChange={e => setPassword(_ => formEventTargetValue(e))}
          />
          <Mui.Button
            \"type"="submit"
            fullWidth={true}
            variant="contained"
            sx={{"mt": 3, "mb": 2}}
            disabled={loading}>
            {React.string(loading ? "Logging in..." : "Sign In")}
          </Mui.Button>
        </Mui.Box>
        <Mui.Typography
          variant="body2" color="textSecondary" align="center" sx={{"mt": 2}}>
          {React.string("Default credentials: admin / admin123")}
        </Mui.Typography>
      </Mui.Paper>
    </Mui.Box>
  </Mui.Container>
}
