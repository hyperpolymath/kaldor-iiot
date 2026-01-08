// SPDX-License-Identifier: AGPL-3.0-or-later
//! Kaldor IIoT - BBW Sensor Board Firmware
//!
//! Zig implementation of ESP32-based Back Beam Width monitoring system.
//!
//! Features:
//! - Multi-sensor data acquisition (ultrasonic, temperature, vibration)
//! - MQTT communication with TLS
//! - Local data buffering for offline operation
//! - OTA firmware updates
//! - Watchdog timer for reliability
//! - WiFi auto-reconnection

const std = @import("std");
const config = @import("config.zig");
const sensors = @import("sensors.zig");
const mqtt = @import("mqtt.zig");
const wifi = @import("wifi.zig");
const buffer = @import("buffer.zig");
const ota = @import("ota.zig");
const hal = @import("hal.zig");

// Firmware version
pub const VERSION = "1.0.0-zig";

// Timing constants (milliseconds)
const SENSOR_INTERVAL: u32 = 10; // 100Hz
const TELEMETRY_INTERVAL: u32 = 1000; // 1Hz
const WIFI_CHECK_INTERVAL: u32 = 5000;
const MQTT_CHECK_INTERVAL: u32 = 5000;
const WDT_TIMEOUT: u32 = 30000;

// GPIO pins for status LEDs
const LED_STATUS: u8 = 2;
const LED_WIFI: u8 = 4;
const LED_MQTT: u8 = 5;

// Global state
var device_id: [32]u8 = undefined;
var device_id_len: usize = 0;
var loom_id: [32]u8 = undefined;
var loom_id_len: usize = 0;

// Timing state
var last_sensor_read: u32 = 0;
var last_telemetry: u32 = 0;
var last_wifi_check: u32 = 0;
var last_mqtt_check: u32 = 0;

// Subsystem instances
var sensor_manager: sensors.SensorManager = undefined;
var data_buffer: buffer.DataBuffer = undefined;
var mqtt_client: mqtt.MqttClient = undefined;
var ota_updater: ota.OtaUpdater = undefined;

/// Main entry point
pub fn main() void {
    setup();

    while (true) {
        loop();
    }
}

/// Initialize all subsystems
fn setup() void {
    // Initialize serial for debugging
    hal.uart_init(115200);
    hal.delay_ms(1000);

    hal.print("\n\n");
    hal.print("╔═══════════════════════════════════════════╗\n");
    hal.print("║   Kaldor IIoT - BBW Sensor Board v1.0    ║\n");
    hal.print("║            (Zig Implementation)           ║\n");
    hal.print("╚═══════════════════════════════════════════╝\n");
    hal.print("\n");

    // Initialize status LEDs
    hal.gpio_set_output(LED_STATUS);
    hal.gpio_set_output(LED_WIFI);
    hal.gpio_set_output(LED_MQTT);
    hal.gpio_write(LED_STATUS, true);

    // Initialize flash storage
    if (!hal.spiffs_init()) {
        hal.print("ERROR: SPIFFS mount failed\n");
        hal.restart();
    }
    hal.print("✓ SPIFFS initialized\n");

    // Load configuration
    loadConfiguration();

    // Generate device ID if not set
    if (device_id_len == 0) {
        const chip_id = hal.get_chip_id();
        device_id_len = std.fmt.bufPrint(&device_id, "BBW-{X:0>8}", .{chip_id}) catch 0;
        hal.nvs_set_string("deviceId", device_id[0..device_id_len]);
    }
    hal.print("✓ Device ID: ");
    hal.print(device_id[0..device_id_len]);
    hal.print("\n");

    // Initialize I2C bus
    hal.i2c_init(config.I2C_SDA, config.I2C_SCL);
    hal.print("✓ I2C initialized\n");

    // Initialize sensors
    sensor_manager = sensors.SensorManager.init();
    if (!sensor_manager.begin()) {
        hal.print("WARNING: Some sensors failed to initialize\n");
    } else {
        hal.print("✓ All sensors initialized\n");
    }

    // Initialize data buffer
    data_buffer = buffer.DataBuffer.init(100);
    hal.print("✓ Data buffer initialized\n");

    // Setup WiFi
    setupWiFi();

    // Setup MQTT
    setupMqtt();

    // Initialize OTA
    ota_updater = ota.OtaUpdater.init(device_id[0..device_id_len]);
    hal.print("✓ OTA updater ready\n");

    // Configure watchdog
    hal.wdt_init(WDT_TIMEOUT);
    hal.print("✓ Watchdog timer configured\n");

    // Ready!
    blinkLed(LED_STATUS, 3);
    hal.print("\n✓ System ready - entering main loop\n\n");
}

/// Main loop - called repeatedly
fn loop() void {
    const current_time = hal.millis();

    // Reset watchdog
    hal.wdt_reset();

    // Check WiFi connection
    if (current_time - last_wifi_check >= WIFI_CHECK_INTERVAL) {
        last_wifi_check = current_time;
        if (!wifi.isConnected()) {
            hal.gpio_write(LED_WIFI, false);
            reconnectWiFi();
        } else {
            hal.gpio_write(LED_WIFI, true);
        }
    }

    // Check MQTT connection
    if (current_time - last_mqtt_check >= MQTT_CHECK_INTERVAL) {
        last_mqtt_check = current_time;
        if (!mqtt_client.isConnected()) {
            hal.gpio_write(LED_MQTT, false);
            reconnectMqtt();
        } else {
            hal.gpio_write(LED_MQTT, true);
        }
    }

    // Process MQTT messages
    mqtt_client.loop();

    // Read sensors at high frequency
    if (current_time - last_sensor_read >= SENSOR_INTERVAL) {
        last_sensor_read = current_time;
        readSensors();
    }

    // Publish telemetry at lower frequency
    if (current_time - last_telemetry >= TELEMETRY_INTERVAL) {
        last_telemetry = current_time;
        publishTelemetry();
    }

    // Handle OTA updates
    ota_updater.handle();

    // Small delay
    hal.delay_ms(1);
}

/// Setup WiFi connection
fn setupWiFi() void {
    hal.print("Connecting to WiFi: ");
    hal.print(config.WIFI_SSID);
    hal.print(" ");

    wifi.init();
    wifi.setHostname(device_id[0..device_id_len]);
    wifi.connect(config.WIFI_SSID, config.WIFI_PASSWORD);

    var attempts: u32 = 0;
    while (!wifi.isConnected() and attempts < 30) {
        hal.delay_ms(500);
        hal.print(".");
        attempts += 1;
    }

    if (wifi.isConnected()) {
        hal.print(" Connected!\n");
        hal.print("✓ IP Address: ");
        hal.print(wifi.getIpAddress());
        hal.print("\n");
        hal.gpio_write(LED_WIFI, true);
    } else {
        hal.print(" Failed!\n");
        hal.print("WARNING: Running in offline mode\n");
        hal.gpio_write(LED_WIFI, false);
    }
}

/// Reconnect WiFi if disconnected
fn reconnectWiFi() void {
    hal.print("Attempting WiFi reconnection...\n");
    wifi.disconnect();
    hal.delay_ms(100);
    wifi.connect(config.WIFI_SSID, config.WIFI_PASSWORD);

    var attempts: u32 = 0;
    while (!wifi.isConnected() and attempts < 10) {
        hal.delay_ms(500);
        attempts += 1;
    }

    if (wifi.isConnected()) {
        hal.print("✓ WiFi reconnected\n");
        hal.gpio_write(LED_WIFI, true);
    }
}

/// Setup MQTT client
fn setupMqtt() void {
    mqtt_client = mqtt.MqttClient.init(
        config.MQTT_BROKER,
        config.MQTT_PORT,
        mqttCallback,
    );
    mqtt_client.setCredentials(config.MQTT_USER, config.MQTT_PASSWORD);
    reconnectMqtt();
}

/// Reconnect MQTT if disconnected
fn reconnectMqtt() void {
    if (!wifi.isConnected()) return;

    hal.print("Attempting MQTT connection...");

    var client_id_buf: [64]u8 = undefined;
    const client_id_len = std.fmt.bufPrint(&client_id_buf, "kaldor-{s}", .{device_id[0..device_id_len]}) catch 0;

    if (mqtt_client.connect(client_id_buf[0..client_id_len])) {
        hal.print(" Connected!\n");
        hal.gpio_write(LED_MQTT, true);

        // Subscribe to command topics
        var topic_buf: [128]u8 = undefined;
        const cmd_topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/config", .{loom_id[0..loom_id_len]}) catch 0;
        mqtt_client.subscribe(topic_buf[0..cmd_topic_len]);

        const ota_topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/ota", .{loom_id[0..loom_id_len]}) catch 0;
        mqtt_client.subscribe(topic_buf[0..ota_topic_len]);

        hal.print("✓ Subscribed to topics\n");

        // Publish online status
        publishStatus("online");
    } else {
        hal.print(" Failed!\n");
        hal.gpio_write(LED_MQTT, false);
    }
}

/// Read sensors and buffer data
fn readSensors() void {
    const data = sensor_manager.read();
    data_buffer.add(data);

    // Publish raw data if connected
    if (mqtt_client.isConnected()) {
        var topic_buf: [128]u8 = undefined;
        const topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/bbw/raw", .{loom_id[0..loom_id_len]}) catch 0;

        var payload_buf: [256]u8 = undefined;
        const payload_len = std.fmt.bufPrint(&payload_buf,
            \\{{"timestamp":{d},"device_id":"{s}","bbw":{d:.2},"quality":{d}}}
        , .{
            hal.millis(),
            device_id[0..device_id_len],
            data.bbw,
            data.quality,
        }) catch 0;

        mqtt_client.publish(topic_buf[0..topic_len], payload_buf[0..payload_len]);
    }
}

/// Publish aggregated telemetry
fn publishTelemetry() void {
    if (!mqtt_client.isConnected()) return;

    const data = sensor_manager.getAggregated();

    var topic_buf: [128]u8 = undefined;
    const topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/bbw/processed", .{loom_id[0..loom_id_len]}) catch 0;

    var payload_buf: [512]u8 = undefined;
    const payload_len = std.fmt.bufPrint(&payload_buf,
        \\{{"timestamp":{d},"device_id":"{s}","loom_id":"{s}",
        \\"measurements":{{"bbw_avg":{d:.2},"bbw_min":{d:.2},"bbw_max":{d:.2},
        \\"bbw_stddev":{d:.4},"temperature":{d:.1},"vibration":{d:.3}}},
        \\"system":{{"uptime":{d},"free_heap":{d},"wifi_rssi":{d},"buffer_size":{d}}}}}
    , .{
        hal.millis(),
        device_id[0..device_id_len],
        loom_id[0..loom_id_len],
        data.bbw,
        data.bbw_min,
        data.bbw_max,
        data.bbw_stddev,
        data.temperature,
        data.vibration,
        hal.millis() / 1000,
        hal.getFreeHeap(),
        wifi.getRssi(),
        data_buffer.size(),
    }) catch 0;

    mqtt_client.publish(topic_buf[0..topic_len], payload_buf[0..payload_len]);

    // Check for alerts
    if (data.bbw < config.BBW_MIN_THRESHOLD or data.bbw > config.BBW_MAX_THRESHOLD) {
        publishAlert("bbw_out_of_range", data.bbw);
    }
}

/// Publish alert
fn publishAlert(alert_type: []const u8, value: f32) void {
    var topic_buf: [128]u8 = undefined;
    const topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/alerts", .{loom_id[0..loom_id_len]}) catch 0;

    var payload_buf: [256]u8 = undefined;
    const payload_len = std.fmt.bufPrint(&payload_buf,
        \\{{"timestamp":{d},"device_id":"{s}","loom_id":"{s}","alert_type":"{s}","value":{d:.2},"severity":"warning"}}
    , .{
        hal.millis(),
        device_id[0..device_id_len],
        loom_id[0..loom_id_len],
        alert_type,
        value,
    }) catch 0;

    mqtt_client.publishRetained(topic_buf[0..topic_len], payload_buf[0..payload_len]);
}

/// Publish device status
fn publishStatus(status: []const u8) void {
    var topic_buf: [128]u8 = undefined;
    const topic_len = std.fmt.bufPrint(&topic_buf, "kaldor/loom/{s}/status", .{loom_id[0..loom_id_len]}) catch 0;

    var payload_buf: [256]u8 = undefined;
    const payload_len = std.fmt.bufPrint(&payload_buf,
        \\{{"device_id":"{s}","loom_id":"{s}","status":"{s}","firmware_version":"{s}","ip":"{s}"}}
    , .{
        device_id[0..device_id_len],
        loom_id[0..loom_id_len],
        status,
        VERSION,
        wifi.getIpAddress(),
    }) catch 0;

    mqtt_client.publishRetained(topic_buf[0..topic_len], payload_buf[0..payload_len]);
}

/// MQTT message callback
fn mqttCallback(topic: []const u8, payload: []const u8) void {
    hal.print("Message received [");
    hal.print(topic);
    hal.print("]\n");

    // Handle configuration updates
    if (std.mem.indexOf(u8, topic, "/config")) |_| {
        hal.print("Configuration update received\n");
        // Parse JSON and update config
        saveConfiguration();
    }

    // Handle OTA requests
    if (std.mem.indexOf(u8, topic, "/ota")) |_| {
        hal.print("OTA update requested\n");
        // Extract URL and trigger OTA
        if (extractJsonString(payload, "url")) |url| {
            ota_updater.update(url);
        }
    }
}

/// Load configuration from NVS
fn loadConfiguration() void {
    loom_id_len = hal.nvs_get_string("loomId", &loom_id) orelse blk: {
        @memcpy(loom_id[0..8], "LOOM-001");
        break :blk 8;
    };
    device_id_len = hal.nvs_get_string("deviceId", &device_id) orelse 0;
}

/// Save configuration to NVS
fn saveConfiguration() void {
    hal.nvs_set_string("loomId", loom_id[0..loom_id_len]);
    hal.nvs_set_string("deviceId", device_id[0..device_id_len]);
}

/// Blink LED n times
fn blinkLed(pin: u8, times: u32) void {
    var i: u32 = 0;
    while (i < times) : (i += 1) {
        hal.gpio_write(pin, true);
        hal.delay_ms(100);
        hal.gpio_write(pin, false);
        hal.delay_ms(100);
    }
}

/// Extract string value from JSON (simple parser)
fn extractJsonString(json: []const u8, key: []const u8) ?[]const u8 {
    // Simple JSON string extraction
    // In production, use a proper JSON parser
    var search_buf: [64]u8 = undefined;
    const search_len = std.fmt.bufPrint(&search_buf, "\"{s}\":\"", .{key}) catch return null;

    if (std.mem.indexOf(u8, json, search_buf[0..search_len])) |start| {
        const value_start = start + search_len;
        if (std.mem.indexOfPos(u8, json, value_start, "\"")) |end| {
            return json[value_start..end];
        }
    }
    return null;
}

// ============================================================================
// Tests
// ============================================================================

test "extractJsonString" {
    const json = "{\"url\":\"https://example.com/firmware.bin\",\"version\":\"1.0.1\"}";
    const url = extractJsonString(json, "url");
    try std.testing.expect(url != null);
    try std.testing.expectEqualStrings("https://example.com/firmware.bin", url.?);
}

test "blinkLed does not crash" {
    // Would need HAL mock for real test
}
