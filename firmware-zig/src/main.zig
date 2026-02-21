// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * Kaldor IIoT — Back Beam Width (BBW) Sensor Firmware.
 *
 * This Zig module implements the firmware for an ESP32-based monitoring 
 * system. It is designed for high-reliability industrial environments, 
 * featuring local data buffering, watchdog enforcement, and secure telemetry.
 *
 * SUBSYSTEMS:
 * 1. SENSORS: High-frequency (100Hz) acquisition of physical metrics.
 * 2. BUFFER: Circular memory buffer to prevent data loss during WiFi outages.
 * 3. TELEMETRY: MQTT client for publishing processed metrics and alerts.
 * 4. MAINTENANCE: OTA (Over-The-Air) update listener for remote management.
 */

const std = @import("std");
const config = @import("config.zig");
const sensors = @import("sensors.zig");
const mqtt = @import("mqtt.zig");
const wifi = @import("wifi.zig");
const buffer = @import("buffer.zig");
const ota = @import("ota.zig");
const hal = @import("hal.zig");

pub const VERSION = "1.0.0-zig";

/// CORE LIFECYCLE: Initialization and Main Execution Loop.
pub fn main() void {
    // SETUP: Initialize UART, GPIO, SPIFFS (Flash), and I2C sensors.
    setup();

    // LOOP: Service watchdog, check network health, and process IO.
    while (true) {
        loop();
    }
}

/// TELEMETRY: Aggregates buffered data and publishes to the loom controller.
fn publishTelemetry() void {
    if (!mqtt_client.isConnected()) return;

    const data = sensor_manager.getAggregated();
    // ... [Serialization into JSON payload]
    mqtt_client.publish(topic, payload);

    // CRITICAL ALERT: Out-of-bounds metrics trigger immediate retained messages.
    if (data.bbw < config.BBW_MIN_THRESHOLD or data.bbw > config.BBW_MAX_THRESHOLD) {
        publishAlert("bbw_out_of_range", data.bbw);
    }
}
