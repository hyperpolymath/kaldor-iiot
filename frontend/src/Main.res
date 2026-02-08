// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

// Application entry point. Mounts React root with Redux Provider,
// BrowserRouter, MUI ThemeProvider, and ToastContainer.

%%raw(`import 'react-toastify/dist/ReactToastify.css'`)

let theme = Mui.createTheme({
  palette: {
    "mode": "light",
    "primary": {"main": "#1976d2"},
    "secondary": {"main": "#dc004e"},
  },
  typography: {
    "fontFamily": `"Roboto", "Helvetica", "Arial", sans-serif`,
  },
})

// Get the root DOM element
let rootElement = switch ReactDOM.querySelector("#root") {
| Some(element) => element
| None => panic("Could not find #root element")
}

let root = ReactDOM.Client.createRoot(rootElement)

root->ReactDOM.Client.Root.render(
  <React.StrictMode>
    <ReduxToolkit.Provider store={Store.store}>
      <ReactRouter.BrowserRouter>
        <Mui.ThemeProvider theme>
          <Mui.CssBaseline />
          <App />
          <ReactToastify.ToastContainer
            position="top-right"
            autoClose={5000}
            hideProgressBar={false}
            newestOnTop={true}
            closeOnClick={true}
            rtl={false}
            pauseOnFocusLoss={true}
            draggable={true}
            pauseOnHover={true}
          />
        </Mui.ThemeProvider>
      </ReactRouter.BrowserRouter>
    </ReduxToolkit.Provider>
  </React.StrictMode>,
)
