# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Kaldor Community Manufacturing Platform Contributors
# Kaldor IIoT - Analytics Service (Julia)

module Analytics

using HTTP
using JSON3
using LibPQ
using Redis
using Statistics
using LinearAlgebra
using DataFrames
using Dates
using Logging

# Configuration
const DB_HOST = get(ENV, "DB_HOST", "localhost")
const DB_PORT = get(ENV, "DB_PORT", "5432")
const DB_NAME = get(ENV, "DB_NAME", "kaldor_iiot")
const DB_USER = get(ENV, "DB_USER", "kaldor")
const DB_PASSWORD = get(ENV, "DB_PASSWORD", "kaldor")

const REDIS_HOST = get(ENV, "REDIS_HOST", "localhost")
const REDIS_PORT = parse(Int, get(ENV, "REDIS_PORT", "6379"))
const REDIS_PASSWORD = get(ENV, "REDIS_PASSWORD", "")

const PORT = parse(Int, get(ENV, "PORT", "5000"))

# Database connection
function get_db_connection()
    conn_string = "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
    return LibPQ.Connection(conn_string)
end

# Redis connection
function get_redis_connection()
    if isempty(REDIS_PASSWORD)
        return Redis.RedisConnection(host=REDIS_HOST, port=REDIS_PORT)
    else
        return Redis.RedisConnection(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD)
    end
end

# JSON response helper
function json_response(data; status=200)
    return HTTP.Response(status, ["Content-Type" => "application/json"], JSON3.write(data))
end

# Health check
function health_check(req::HTTP.Request)
    return json_response(Dict(
        "status" => "healthy",
        "timestamp" => string(now()),
        "service" => "analytics",
        "runtime" => "Julia $(VERSION)"
    ))
end

# Anomaly detection using z-scores
function detect_anomalies(req::HTTP.Request)
    try
        body = JSON3.read(String(req.body))
        loom_id = get(body, :loom_id, nothing)
        hours = get(body, :hours, 24)

        if isnothing(loom_id)
            return json_response(Dict("error" => "loom_id required"), status=400)
        end

        conn = get_db_connection()

        query = """
            SELECT time, bbw_avg, bbw_stddev
            FROM bbw_measurements
            WHERE loom_id = \$1
              AND time >= NOW() - INTERVAL '\$2 hours'
            ORDER BY time DESC
        """

        result = execute(conn, query, [loom_id, hours])

        if isempty(result)
            close(conn)
            return json_response(Dict("anomalies" => []))
        end

        # Convert to DataFrame
        df = DataFrame(result)
        rename!(df, [:time, :bbw_avg, :bbw_stddev])

        # Calculate z-scores
        μ = mean(df.bbw_avg)
        σ = std(df.bbw_avg)

        df.z_score = (df.bbw_avg .- μ) ./ σ

        # Detect anomalies (|z| > 3)
        anomalies = df[abs.(df.z_score) .> 3, :]

        response = Dict(
            "loom_id" => loom_id,
            "period_hours" => hours,
            "total_measurements" => nrow(df),
            "anomaly_count" => nrow(anomalies),
            "anomalies" => [Dict(pairs(row)) for row in eachrow(anomalies)],
            "statistics" => Dict(
                "mean" => μ,
                "std" => σ,
                "min" => minimum(df.bbw_avg),
                "max" => maximum(df.bbw_avg)
            )
        )

        close(conn)
        return json_response(response)

    catch e
        @error "Anomaly detection error" exception=(e, catch_backtrace())
        return json_response(Dict("error" => string(e)), status=500)
    end
end

# Predictive maintenance
function predict_maintenance(req::HTTP.Request)
    try
        body = JSON3.read(String(req.body))
        loom_id = get(body, :loom_id, nothing)

        if isnothing(loom_id)
            return json_response(Dict("error" => "loom_id required"), status=400)
        end

        conn = get_db_connection()

        query = """
            SELECT
                time_bucket('1 hour', time) as hour,
                AVG(bbw_avg) as avg_bbw,
                AVG(bbw_stddev) as avg_stddev,
                AVG(temperature) as avg_temp,
                AVG(vibration) as avg_vib
            FROM bbw_measurements
            WHERE loom_id = \$1
              AND time >= NOW() - INTERVAL '30 days'
            GROUP BY hour
            ORDER BY hour
        """

        result = execute(conn, query, [loom_id])

        if isempty(result)
            close(conn)
            return json_response(Dict("error" => "No data found"), status=404)
        end

        df = DataFrame(result)
        rename!(df, [:hour, :avg_bbw, :avg_stddev, :avg_temp, :avg_vib])

        # Linear trend analysis on stddev
        x = collect(1:nrow(df))
        y = df.avg_stddev

        # Simple linear regression: y = mx + b
        n = length(x)
        trend = (n * sum(x .* y) - sum(x) * sum(y)) / (n * sum(x.^2) - sum(x)^2)

        # Calculate health score (0-100)
        health_score = 100 - min(100, abs(trend) * 10000)

        # Determine maintenance needs
        maintenance_needed = health_score < 70
        urgency = if health_score < 50
            "high"
        elseif health_score < 70
            "medium"
        else
            "low"
        end

        recommendation = get_maintenance_recommendation(health_score, trend)

        response = Dict(
            "loom_id" => loom_id,
            "health_score" => round(health_score, digits=2),
            "maintenance_needed" => maintenance_needed,
            "urgency" => urgency,
            "trend" => trend > 0 ? "increasing" : "decreasing",
            "recommendation" => recommendation
        )

        close(conn)
        return json_response(response)

    catch e
        @error "Predictive maintenance error" exception=(e, catch_backtrace())
        return json_response(Dict("error" => string(e)), status=500)
    end
end

# Quality report generation
function generate_quality_report(req::HTTP.Request)
    try
        body = JSON3.read(String(req.body))
        loom_id = get(body, :loom_id, nothing)
        start_time = get(body, :start_time, nothing)
        end_time = get(body, :end_time, string(now()))

        if isnothing(loom_id) || isnothing(start_time)
            return json_response(Dict("error" => "loom_id and start_time required"), status=400)
        end

        conn = get_db_connection()

        query = """
            SELECT
                COUNT(*) as total_measurements,
                AVG(bbw_avg) as avg_bbw,
                STDDEV(bbw_avg) as stddev_bbw,
                MIN(bbw_min) as min_bbw,
                MAX(bbw_max) as max_bbw,
                AVG(quality_flag) as avg_quality
            FROM bbw_measurements
            WHERE loom_id = \$1
              AND time >= \$2
              AND time <= \$3
        """

        result = execute(conn, query, [loom_id, start_time, end_time])
        row = first(result)

        report = Dict(
            "loom_id" => loom_id,
            "period" => Dict(
                "start" => start_time,
                "end" => end_time
            ),
            "measurements" => Dict(
                "total_count" => something(row[1], 0),
                "average_bbw" => round(something(row[2], 0.0), digits=2),
                "std_deviation" => round(something(row[3], 0.0), digits=2),
                "min_bbw" => round(something(row[4], 0.0), digits=2),
                "max_bbw" => round(something(row[5], 0.0), digits=2),
                "quality_score" => round(something(row[6], 0.0), digits=2)
            )
        )

        close(conn)
        return json_response(report)

    catch e
        @error "Quality report error" exception=(e, catch_backtrace())
        return json_response(Dict("error" => string(e)), status=500)
    end
end

# Maintenance recommendation helper
function get_maintenance_recommendation(health_score::Real, trend::Real)
    if health_score < 50
        return "Immediate maintenance required. Schedule inspection within 24 hours."
    elseif health_score < 70
        return "Maintenance recommended within the next week. Monitor closely."
    elseif trend > 0.001
        return "Increasing variability detected. Schedule preventive maintenance."
    else
        return "System operating normally. Continue regular monitoring."
    end
end

# CORS middleware
function cors_middleware(handler)
    return function(req::HTTP.Request)
        # Handle preflight
        if req.method == "OPTIONS"
            return HTTP.Response(204, [
                "Access-Control-Allow-Origin" => "*",
                "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers" => "Content-Type, Authorization"
            ])
        end

        response = handler(req)

        # Add CORS headers
        push!(response.headers, "Access-Control-Allow-Origin" => "*")

        return response
    end
end

# Router
function route_request(req::HTTP.Request)
    path = HTTP.URI(req.target).path
    method = req.method

    if path == "/health" && method == "GET"
        return health_check(req)
    elseif path == "/api/v1/analytics/anomaly-detection" && method == "POST"
        return detect_anomalies(req)
    elseif path == "/api/v1/analytics/predict-maintenance" && method == "POST"
        return predict_maintenance(req)
    elseif path == "/api/v1/analytics/quality-report" && method == "POST"
        return generate_quality_report(req)
    else
        return json_response(Dict("error" => "Not found"), status=404)
    end
end

# Main server function
function serve()
    @info "Starting Kaldor IIoT Analytics Service (Julia)" port=PORT

    handler = cors_middleware(route_request)

    HTTP.serve(handler, "0.0.0.0", PORT)
end

# Entry point
function main()
    serve()
end

end # module
