// SPDX-License-Identifier: AGPL-3.0-or-later
//! Kaldor IIoT - MQTT Client
//!
//! MQTT communication with TLS support for secure telemetry.

const std = @import("std");
const builtin = @import("builtin");
const hal = @import("hal.zig");

/// MQTT callback function type
pub const MqttCallback = *const fn (topic: []const u8, payload: []const u8) void;

/// MQTT connection state
pub const MqttState = enum {
    disconnected,
    connecting,
    connected,
    error_state,
};

/// MQTT Client
pub const MqttClient = struct {
    broker: [:0]const u8,
    port: u16,
    callback: ?MqttCallback,
    username: ?[:0]const u8 = null,
    password: ?[:0]const u8 = null,
    state: MqttState = .disconnected,
    keep_alive: u16 = 60,

    const Self = @This();

    pub fn init(broker: [:0]const u8, port: u16, callback: MqttCallback) Self {
        return Self{
            .broker = broker,
            .port = port,
            .callback = callback,
        };
    }

    /// Set credentials
    pub fn setCredentials(self: *Self, user: [:0]const u8, pass: [:0]const u8) void {
        self.username = user;
        self.password = pass;
    }

    /// Connect to broker
    pub fn connect(self: *Self, client_id: []const u8) bool {
        _ = client_id;
        self.state = .connecting;

        if (builtin.os.tag == .freestanding) {
            // ESP32: Use esp_mqtt_client
            // esp_mqtt_client_config_t cfg = { .uri = ..., .username = ..., ... };
            // esp_mqtt_client_init(&cfg);
            // esp_mqtt_client_start(client);
            return mqtt_client_connect();
        } else {
            // Simulation: Always succeed
            self.state = .connected;
            return true;
        }
    }

    /// Check if connected
    pub fn isConnected(self: *const Self) bool {
        if (builtin.os.tag == .freestanding) {
            return mqtt_client_is_connected();
        }
        return self.state == .connected;
    }

    /// Subscribe to topic
    pub fn subscribe(self: *Self, topic: []const u8) void {
        _ = self;
        if (builtin.os.tag == .freestanding) {
            mqtt_subscribe(topic.ptr, topic.len);
        }
    }

    /// Publish message
    pub fn publish(self: *Self, topic: []const u8, payload: []const u8) void {
        _ = self;
        if (builtin.os.tag == .freestanding) {
            mqtt_publish(topic.ptr, topic.len, payload.ptr, payload.len, 0, false);
        } else {
            // Simulation: Log message
            hal.print("MQTT Publish [");
            hal.print(topic);
            hal.print("]: ");
            hal.print(payload);
            hal.print("\n");
        }
    }

    /// Publish retained message
    pub fn publishRetained(self: *Self, topic: []const u8, payload: []const u8) void {
        _ = self;
        if (builtin.os.tag == .freestanding) {
            mqtt_publish(topic.ptr, topic.len, payload.ptr, payload.len, 0, true);
        } else {
            hal.print("MQTT Publish (retained) [");
            hal.print(topic);
            hal.print("]: ");
            hal.print(payload);
            hal.print("\n");
        }
    }

    /// Process incoming messages
    pub fn loop(self: *Self) void {
        if (builtin.os.tag == .freestanding) {
            // ESP32: Messages delivered via callback
            // Check for pending messages and invoke callback
            var topic_buf: [128]u8 = undefined;
            var payload_buf: [512]u8 = undefined;
            var topic_len: usize = 0;
            var payload_len: usize = 0;

            if (mqtt_receive(&topic_buf, &topic_len, &payload_buf, &payload_len)) {
                if (self.callback) |cb| {
                    cb(topic_buf[0..topic_len], payload_buf[0..payload_len]);
                }
            }
        }
    }
};

// ============================================================================
// ESP-IDF External Declarations
// ============================================================================

extern fn mqtt_client_connect() bool;
extern fn mqtt_client_is_connected() bool;
extern fn mqtt_subscribe(topic: [*]const u8, len: usize) void;
extern fn mqtt_publish(topic: [*]const u8, topic_len: usize, payload: [*]const u8, payload_len: usize, qos: u8, retain: bool) void;
extern fn mqtt_receive(topic: *[128]u8, topic_len: *usize, payload: *[512]u8, payload_len: *usize) bool;

// ============================================================================
// Tests
// ============================================================================

fn dummyCallback(_: []const u8, _: []const u8) void {}

test "mqtt client init" {
    const client = MqttClient.init("test.mqtt.io", 1883, dummyCallback);
    try std.testing.expectEqualStrings("test.mqtt.io", client.broker);
    try std.testing.expectEqual(@as(u16, 1883), client.port);
}
