// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Dashboard page showing loom summary cards and status overview.

@react.component
let make = () => {
  let dispatch = Redux.useAppDispatch()
  let navigate = ReactRouter.useNavigate()
  let loomsState = Redux.useAppSelector(state => state.looms)
  let alertsState = Redux.useAppSelector(state => state.alerts)

  let loadLooms = () => {
    dispatch(LoomsSlice.setLoading(true))
    let _ =
      Api.LoomsAPI.getAll()
      ->Promise.then(response => {
        let data: array<LoomsSlice.loom> = response.data.data
        dispatch(LoomsSlice.setLooms(data))
        Promise.resolve()
      })
      ->Promise.catch(error => {
        Console.error2("Failed to load looms:", error)
        Promise.resolve()
      })
  }

  React.useEffect0(() => {
    loadLooms()
    None
  })

  let getStatusIcon = (status: string) => {
    switch status {
    | "online" => <Mui.CheckCircleIcon color="success" />
    | "warning" => <Mui.WarningAmberIcon color="warning" />
    | "error" => <Mui.ErrorIcon color="error" />
    | _ => <Mui.ErrorIcon color="disabled" />
    }
  }

  let activeCount =
    loomsState.looms->Array.filter(l => l.status === "active")->Array.length

  <Mui.Box>
    <Mui.Typography variant="h4" gutterBottom={true}>
      {React.string("Dashboard")}
    </Mui.Typography>
    <Mui.Grid container={true} spacing={3} sx={{"mb": 3}}>
      <Mui.Grid item={true} xs={12} sm={6} md={3}>
        <Mui.Paper sx={{"p": 2}}>
          <Mui.Typography color="textSecondary" gutterBottom={true}>
            {React.string("Total Looms")}
          </Mui.Typography>
          <Mui.Typography variant="h4">
            {React.string(Int.toString(Array.length(loomsState.looms)))}
          </Mui.Typography>
        </Mui.Paper>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} sm={6} md={3}>
        <Mui.Paper sx={{"p": 2}}>
          <Mui.Typography color="textSecondary" gutterBottom={true}>
            {React.string("Active Looms")}
          </Mui.Typography>
          <Mui.Typography variant="h4" color="success.main">
            {React.string(Int.toString(activeCount))}
          </Mui.Typography>
        </Mui.Paper>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} sm={6} md={3}>
        <Mui.Paper sx={{"p": 2}}>
          <Mui.Typography color="textSecondary" gutterBottom={true}>
            {React.string("Alerts")}
          </Mui.Typography>
          <Mui.Typography variant="h4" color="warning.main">
            {React.string(Int.toString(alertsState.unacknowledgedCount))}
          </Mui.Typography>
        </Mui.Paper>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} sm={6} md={3}>
        <Mui.Paper sx={{"p": 2}}>
          <Mui.Typography color="textSecondary" gutterBottom={true}>
            {React.string("System Health")}
          </Mui.Typography>
          <Mui.Typography variant="h4" color="success.main">
            {React.string("98%")}
          </Mui.Typography>
        </Mui.Paper>
      </Mui.Grid>
    </Mui.Grid>
    <Mui.Typography variant="h5" gutterBottom={true}>
      {React.string("Looms")}
    </Mui.Typography>
    <Mui.Grid container={true} spacing={2}>
      {loomsState.looms
      ->Array.map(loom =>
        <Mui.Grid item={true} xs={12} sm={6} md={4} key={loom.id}>
          <Mui.Card
            sx={{"cursor": "pointer", "&:hover": {"boxShadow": 6}}}
            onClick={_event => navigate(`/loom/${loom.id}`)}>
            <Mui.CardContent>
              <Mui.Box
                display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                <Mui.Typography variant="h6">
                  {React.string(loom.name)}
                </Mui.Typography>
                {getStatusIcon(loom.status)}
              </Mui.Box>
              <Mui.Typography color="textSecondary" variant="body2" gutterBottom={true}>
                {React.string(loom.location)}
              </Mui.Typography>
              <Mui.Typography variant="body2">
                {React.string(loom.model)}
              </Mui.Typography>
              <Mui.Box mt={1}>
                <Mui.Chip
                  label={loom.status}
                  color={loom.status === "active" ? "success" : "default"}
                  size="small"
                />
              </Mui.Box>
            </Mui.CardContent>
          </Mui.Card>
        </Mui.Grid>
      )
      ->React.array}
    </Mui.Grid>
  </Mui.Box>
}
