// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Alerts page showing a table of all alerts with acknowledge actions.

@react.component
let make = () => {
  let dispatch = Redux.useAppDispatch()
  let alertsState = Redux.useAppSelector(state => state.alerts)

  let loadAlerts = () => {
    let _ =
      Api.AlertsAPI.getAll()
      ->Promise.then(response => {
        let data: array<AlertsSlice.alert> = response.data.data
        dispatch(AlertsSlice.setAlerts(data))
        Promise.resolve()
      })
      ->Promise.catch(error => {
        Console.error2("Failed to load alerts:", error)
        Promise.resolve()
      })
  }

  React.useEffect0(() => {
    loadAlerts()
    None
  })

  let handleAcknowledge = (alertId: int) => {
    let _ =
      Api.AlertsAPI.acknowledge(alertId)
      ->Promise.then(_ => {
        dispatch(AlertsSlice.acknowledgeAlert(alertId))
        ReactToastify.toastSuccess("Alert acknowledged")
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        ReactToastify.toastError("Failed to acknowledge alert")
        Promise.resolve()
      })
  }

  let getSeverityColor = (severity: string): string => {
    switch severity {
    | "critical" => "error"
    | "warning" => "warning"
    | "info" => "info"
    | _ => "default"
    }
  }

  <Mui.Box>
    <Mui.Typography variant="h4" gutterBottom={true}>
      {React.string("Alerts")}
    </Mui.Typography>
    <Mui.Paper>
      <Mui.Table>
        <Mui.TableHead>
          <Mui.TableRow>
            <Mui.TableCell> {React.string("Time")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Loom")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Type")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Severity")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Value")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Status")} </Mui.TableCell>
            <Mui.TableCell> {React.string("Action")} </Mui.TableCell>
          </Mui.TableRow>
        </Mui.TableHead>
        <Mui.TableBody>
          {alertsState.alerts
          ->Array.map(alert =>
            <Mui.TableRow key={Int.toString(alert.id)}>
              <Mui.TableCell>
                {React.string(alert.created_at)}
              </Mui.TableCell>
              <Mui.TableCell>
                {React.string(alert.loom_id)}
              </Mui.TableCell>
              <Mui.TableCell>
                {React.string(alert.alert_type)}
              </Mui.TableCell>
              <Mui.TableCell>
                <Mui.Chip
                  label={alert.severity}
                  color={getSeverityColor(alert.severity)}
                  size="small"
                />
              </Mui.TableCell>
              <Mui.TableCell>
                {React.string(Float.toString(alert.value))}
              </Mui.TableCell>
              <Mui.TableCell>
                {if alert.acknowledged {
                  <Mui.Chip label="Acknowledged" color="success" size="small" />
                } else {
                  <Mui.Chip label="New" color="error" size="small" />
                }}
              </Mui.TableCell>
              <Mui.TableCell>
                {if !alert.acknowledged {
                  <Mui.Button
                    size="small"
                    variant="contained"
                    onClick={_event => handleAcknowledge(alert.id)}>
                    {React.string("Acknowledge")}
                  </Mui.Button>
                } else {
                  React.null
                }}
              </Mui.TableCell>
            </Mui.TableRow>
          )
          ->React.array}
        </Mui.TableBody>
      </Mui.Table>
    </Mui.Paper>
  </Mui.Box>
}
