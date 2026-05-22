// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Loom detail page showing real-time measurements and BBW trend chart.

// Helper to safely format a nullable float to fixed decimal string
let formatFloat = (value: option<float>, decimals: int): string => {
  switch value {
  | Some(v) => Float.toFixedWithPrecision(v, ~digits=decimals)
  | None => "--"
  }
}

@react.component
let make = () => {
  let params = ReactRouter.useParams()
  let id = params.id
  let (historicalData, setHistoricalData) = React.useState(() => [])
  let measurementsState = Redux.useAppSelector(state => state.measurements)
  let realTimeData = Dict.get(measurementsState.realTimeData, id)

  let loadHistoricalData = () => {
    let _ =
      Api.MeasurementsAPI.get(id)
      ->Promise.then(response => {
        let data: array<MeasurementsSlice.measurement> = response.data.data
        setHistoricalData(_ => data)
        Promise.resolve()
      })
      ->Promise.catch(error => {
        Console.error2("Failed to load data:", error)
        Promise.resolve()
      })
  }

  React.useEffect1(() => {
    Websocket.subscribeToLoom(id)
    loadHistoricalData()
    Some(() => Websocket.unsubscribeFromLoom(id))
  }, [id])

  let bbwDisplay = switch realTimeData {
  | Some(d) => formatFloat(Some(d.bbw_avg), 2)
  | None => "--"
  }

  let tempDisplay = switch realTimeData {
  | Some(d) => formatFloat(Some(d.temperature), 1)
  | None => "--"
  }

  let vibDisplay = switch realTimeData {
  | Some(d) => formatFloat(Some(d.vibration), 2)
  | None => "--"
  }

  let qualDisplay = switch realTimeData {
  | Some(d) => Float.toFixedWithPrecision(d.quality, ~digits=0)
  | None => "--"
  }

  <Mui.Box>
    <Mui.Typography variant="h4" gutterBottom={true}>
      {React.string(`Loom ${id}`)}
    </Mui.Typography>
    <Mui.Grid container={true} spacing={3}>
      <Mui.Grid item={true} xs={12} md={3}>
        <Mui.Card>
          <Mui.CardContent>
            <Mui.Typography color="textSecondary">
              {React.string("BBW (Current)")}
            </Mui.Typography>
            <Mui.Typography variant="h4">
              {React.string(`${bbwDisplay} mm`)}
            </Mui.Typography>
          </Mui.CardContent>
        </Mui.Card>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} md={3}>
        <Mui.Card>
          <Mui.CardContent>
            <Mui.Typography color="textSecondary">
              {React.string("Temperature")}
            </Mui.Typography>
            <Mui.Typography variant="h4">
              {React.string(`${tempDisplay} °C`)}
            </Mui.Typography>
          </Mui.CardContent>
        </Mui.Card>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} md={3}>
        <Mui.Card>
          <Mui.CardContent>
            <Mui.Typography color="textSecondary">
              {React.string("Vibration")}
            </Mui.Typography>
            <Mui.Typography variant="h4">
              {React.string(`${vibDisplay} g`)}
            </Mui.Typography>
          </Mui.CardContent>
        </Mui.Card>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12} md={3}>
        <Mui.Card>
          <Mui.CardContent>
            <Mui.Typography color="textSecondary">
              {React.string("Quality")}
            </Mui.Typography>
            <Mui.Typography variant="h4">
              {React.string(`${qualDisplay}%`)}
            </Mui.Typography>
          </Mui.CardContent>
        </Mui.Card>
      </Mui.Grid>
      <Mui.Grid item={true} xs={12}>
        <Mui.Paper sx={{"p": 2}}>
          <Mui.Typography variant="h6" gutterBottom={true}>
            {React.string("BBW Trend (Last 24 Hours)")}
          </Mui.Typography>
          <Recharts.ResponsiveContainer width="100%" height={400}>
            <Recharts.LineChart data={historicalData}>
              <Recharts.CartesianGrid strokeDasharray="3 3" />
              <Recharts.XAxis dataKey="time" />
              <Recharts.YAxis />
              <Recharts.Tooltip />
              <Recharts.Legend />
              <Recharts.Line \"type"="monotone" dataKey="bbw_avg" stroke="#8884d8" name="Average BBW" />
              <Recharts.Line \"type"="monotone" dataKey="bbw_min" stroke="#82ca9d" name="Min BBW" />
              <Recharts.Line \"type"="monotone" dataKey="bbw_max" stroke="#ffc658" name="Max BBW" />
            </Recharts.LineChart>
          </Recharts.ResponsiveContainer>
        </Mui.Paper>
      </Mui.Grid>
    </Mui.Grid>
  </Mui.Box>
}
