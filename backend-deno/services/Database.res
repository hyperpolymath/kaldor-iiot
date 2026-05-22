// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors

/// PostgreSQL + TimescaleDB database service.
/// Manages connections and provides a query interface.

/// Database client state.
type t = {
  mutable client: option<Postgres.Client.t>,
  connectionString: string,
  mutable isConnectedFlag: bool,
}

/// Create a new database client wrapper (not yet connected).
let make = (connectionString: string): t => {
  client: None,
  connectionString,
  isConnectedFlag: false,
}

/// Connect to the PostgreSQL database and verify TimescaleDB extension.
let connect = async (db: t): unit => {
  try {
    let client = Postgres.Client.make(db.connectionString)
    await Postgres.Client.connect(client)
    db.client = Some(client)
    db.isConnectedFlag = true

    // Verify TimescaleDB extension
    let result = await Postgres.Client.queryObject(
      client,
      "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') as installed",
      None,
    )

    let rows = result["rows"]
    if Array.length(rows) > 0 {
      Logger.info(Logger.logger, "TimescaleDB extension verified")
    } else {
      Logger.warn(
        Logger.logger,
        "TimescaleDB extension not found - install with CREATE EXTENSION timescaledb",
      )
    }

    let dbName = Postgres.Client.session(client)->Postgres.Client.Session.dbName
    let meta = Js.Dict.empty()
    Js.Dict.set(meta, "database", Js.Json.string(dbName))
    Logger.info(Logger.logger, "PostgreSQL connected", ~meta)
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown")),
    )
    Logger.error(Logger.logger, "Failed to connect to PostgreSQL", ~meta)
    raise(exn)
  }
}

/// Disconnect from the database.
let disconnect = async (db: t): unit => {
  switch db.client {
  | Some(client) =>
    await Postgres.Client.end(client)
    db.isConnectedFlag = false
    Logger.info(Logger.logger, "PostgreSQL disconnected")
  | None => ()
  }
}

/// Check if the database is connected.
let isConnected = (db: t): bool => db.isConnectedFlag

/// Get the raw client, raising if not connected.
let getClient = (db: t): Postgres.Client.t => {
  switch db.client {
  | Some(client) => client
  | None => Js.Exn.raiseError("Database not connected")
  }
}

/// Execute a query and return all result rows.
let query = async (db: t, sql: string, ~params: option<array<Js.Json.t>>=?): array<Js.Json.t> => {
  let client = getClient(db)
  let result = await Postgres.Client.queryObject(client, sql, params)
  result["rows"]
}

/// Execute a query and return the first row, or None.
let queryOne = async (db: t, sql: string, ~params: option<array<Js.Json.t>>=?): option<
  Js.Json.t,
> => {
  let rows = await query(db, sql, ~params?)
  rows->Array.get(0)
}

/// Execute a query and return the affected row count.
let execute = async (db: t, sql: string, ~params: option<array<Js.Json.t>>=?): int => {
  let client = getClient(db)
  let result = await Postgres.Client.queryObject(client, sql, params)
  result["rowCount"]->Js.Nullable.toOption->Option.getOr(0)
}

/// Create a TimescaleDB hypertable.
let createHypertable = async (db: t, tableName: string, ~timeColumn: string="timestamp"): unit => {
  try {
    let _ = await execute(
      db,
      `SELECT create_hypertable('${tableName}', '${timeColumn}', if_not_exists => TRUE)`,
    )
    Logger.info(Logger.logger, `Hypertable created: ${tableName}`)
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown")),
    )
    Logger.error(Logger.logger, `Failed to create hypertable: ${tableName}`, ~meta)
    raise(exn)
  }
}

/// Set a TimescaleDB compression policy.
let setCompressionPolicy = async (
  db: t,
  tableName: string,
  ~compressAfter: string="7 days",
): unit => {
  try {
    let _ = await execute(
      db,
      `SELECT add_compression_policy('${tableName}', INTERVAL '${compressAfter}')`,
    )
    Logger.info(Logger.logger, `Compression policy set: ${tableName} after ${compressAfter}`)
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown")),
    )
    Logger.error(Logger.logger, `Failed to set compression policy: ${tableName}`, ~meta)
    raise(exn)
  }
}

/// Set a TimescaleDB data retention policy.
let setRetentionPolicy = async (
  db: t,
  tableName: string,
  ~retainFor: string="90 days",
): unit => {
  try {
    let _ = await execute(
      db,
      `SELECT add_retention_policy('${tableName}', INTERVAL '${retainFor}')`,
    )
    Logger.info(Logger.logger, `Retention policy set: ${tableName} retain ${retainFor}`)
  } catch {
  | exn =>
    let meta = Js.Dict.empty()
    Js.Dict.set(
      meta,
      "error",
      Js.Json.string(exn->Js.Exn.asJsExn->Option.flatMap(Js.Exn.message)->Option.getOr("unknown")),
    )
    Logger.error(Logger.logger, `Failed to set retention policy: ${tableName}`, ~meta)
    raise(exn)
  }
}
