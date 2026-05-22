// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// Structured logging service for Kaldor IIoT.
/// Provides leveled logging with timestamps and context.

/// Log levels ordered by severity.
type logLevel =
  | @as(0) DEBUG
  | @as(1) INFO
  | @as(2) WARN
  | @as(3) ERROR
  | @as(4) FATAL

/// Convert a log level to its string name.
let logLevelName = (level: logLevel): string =>
  switch level {
  | DEBUG => "DEBUG"
  | INFO => "INFO"
  | WARN => "WARN"
  | ERROR => "ERROR"
  | FATAL => "FATAL"
  }

/// Convert a log level to its numeric value for comparison.
let logLevelToInt = (level: logLevel): int =>
  switch level {
  | DEBUG => 0
  | INFO => 1
  | WARN => 2
  | ERROR => 3
  | FATAL => 4
  }

/// Log context is a dictionary of arbitrary key-value pairs.
type logContext = Js.Dict.t<Js.Json.t>

/// Internal: console.log binding.
@val external consoleLog: string => unit = "console.log"
/// Internal: console.warn binding.
@val external consoleWarn: string => unit = "console.warn"
/// Internal: console.error binding.
@val external consoleError: string => unit = "console.error"

/// Logger record holding the minimum log level and default context.
type t = {
  minLevel: logLevel,
  context: logContext,
}

/// Create a new logger with the given minimum level and context.
let make = (~minLevel: logLevel=INFO, ~context: logContext=Js.Dict.empty()): t => {
  minLevel,
  context,
}

/// Internal log method. Outputs structured JSON to the appropriate console
/// stream based on severity.
let log = (logger: t, level: logLevel, message: string, ~meta: logContext=Js.Dict.empty()) => {
  if logLevelToInt(level) >= logLevelToInt(logger.minLevel) {
    let timestamp = Js.Date.make()->Js.Date.toISOString
    let levelName = logLevelName(level)

    // Merge logger context with call-site meta
    let merged = Js.Dict.empty()
    Js.Dict.entries(logger.context)->Array.forEach(((k, v)) => Js.Dict.set(merged, k, v))
    Js.Dict.entries(meta)->Array.forEach(((k, v)) => Js.Dict.set(merged, k, v))

    // Build the log entry
    let entry = Js.Dict.empty()
    Js.Dict.set(entry, "timestamp", Js.Json.string(timestamp))
    Js.Dict.set(entry, "level", Js.Json.string(levelName))
    Js.Dict.set(entry, "message", Js.Json.string(message))
    Js.Dict.entries(merged)->Array.forEach(((k, v)) => Js.Dict.set(entry, k, v))

    let output = Js.Json.stringifyAny(entry)->Option.getOr("{}")

    if logLevelToInt(level) >= logLevelToInt(ERROR) {
      consoleError(output)
    } else if level == WARN {
      consoleWarn(output)
    } else {
      consoleLog(output)
    }
  }
}

let debug = (logger: t, message: string, ~meta: logContext=Js.Dict.empty()) =>
  log(logger, DEBUG, message, ~meta)

let info = (logger: t, message: string, ~meta: logContext=Js.Dict.empty()) =>
  log(logger, INFO, message, ~meta)

let warn = (logger: t, message: string, ~meta: logContext=Js.Dict.empty()) =>
  log(logger, WARN, message, ~meta)

let error = (logger: t, message: string, ~meta: logContext=Js.Dict.empty()) =>
  log(logger, ERROR, message, ~meta)

let fatal = (logger: t, message: string, ~meta: logContext=Js.Dict.empty()) =>
  log(logger, FATAL, message, ~meta)

/// Create a child logger that inherits and extends the parent's context.
let child = (logger: t, context: logContext): t => {
  let merged = Js.Dict.empty()
  Js.Dict.entries(logger.context)->Array.forEach(((k, v)) => Js.Dict.set(merged, k, v))
  Js.Dict.entries(context)->Array.forEach(((k, v)) => Js.Dict.set(merged, k, v))
  {minLevel: logger.minLevel, context: merged}
}

/// Default logger instance, configured from LOG_LEVEL environment variable.
let logger: t = {
  let minLevel = switch Deno.Env.get("LOG_LEVEL")->Js.Nullable.toOption {
  | Some("DEBUG") => DEBUG
  | _ => INFO
  }
  let ctx = Js.Dict.empty()
  Js.Dict.set(ctx, "service", Js.Json.string("kaldor-iiot"))
  make(~minLevel, ~context=ctx)
}
