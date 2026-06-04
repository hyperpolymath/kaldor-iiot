// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Kaldor IIoT - WiFi Management
//!
//! Handles WiFi connection, reconnection, and status monitoring.

const std = @import("std");
const builtin = @import("builtin");
const hal = @import("hal.zig");

/// WiFi connection state
pub const WifiState = enum {
    disconnected,
    connecting,
    connected,
    error_state,
};

var state: WifiState = .disconnected;
var ip_address: [16]u8 = undefined;
var ip_len: usize = 0;
var rssi: i8 = 0;
var hostname_buf: [32]u8 = undefined;
var hostname_len: usize = 0;

/// Initialize WiFi subsystem
pub fn init() void {
    state = .disconnected;
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.mode(WIFI_STA), esp_wifi_init(), etc.
    }
}

/// Set device hostname
pub fn setHostname(name: []const u8) void {
    const len = @min(name.len, hostname_buf.len);
    @memcpy(hostname_buf[0..len], name[0..len]);
    hostname_len = len;
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.setHostname()
    }
}

/// Connect to WiFi network
pub fn connect(ssid: [:0]const u8, password: [:0]const u8) void {
    _ = ssid;
    _ = password;
    state = .connecting;
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.begin(ssid, password)
        // Event handler will update state
    } else {
        // Simulation: Immediately connected
        state = .connected;
        const simulated_ip = "192.168.1.100";
        @memcpy(ip_address[0..simulated_ip.len], simulated_ip);
        ip_len = simulated_ip.len;
        rssi = -50;
    }
}

/// Disconnect from WiFi
pub fn disconnect() void {
    state = .disconnected;
    ip_len = 0;
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.disconnect()
    }
}

/// Check if connected
pub fn isConnected() bool {
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.status() == WL_CONNECTED
        return wifi_is_connected();
    }
    return state == .connected;
}

/// Get IP address as string
pub fn getIpAddress() []const u8 {
    if (ip_len == 0) {
        return "0.0.0.0";
    }
    return ip_address[0..ip_len];
}

/// Get signal strength (RSSI)
pub fn getRssi() i8 {
    if (builtin.os.tag == .freestanding) {
        // ESP32: WiFi.RSSI()
        return wifi_get_rssi();
    }
    return rssi;
}

/// Get current state
pub fn getState() WifiState {
    return state;
}

// ============================================================================
// ESP-IDF External Declarations
// ============================================================================

extern fn wifi_is_connected() bool;
extern fn wifi_get_rssi() i8;

// ============================================================================
// Tests
// ============================================================================

test "wifi init state" {
    init();
    try std.testing.expectEqual(WifiState.disconnected, getState());
}

test "wifi hostname" {
    setHostname("test-device");
    try std.testing.expectEqualStrings("test-device", hostname_buf[0..hostname_len]);
}
