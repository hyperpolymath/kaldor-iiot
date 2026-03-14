// SPDX-License-Identifier: PMPL-1.0-or-later
//! Kaldor IIoT - Hardware Abstraction Layer
//!
//! Abstracts ESP32 hardware access for portability and testing.
//! In production, this wraps ESP-IDF functions via @cImport.
//! For simulation/testing, stubs are provided.

const std = @import("std");
const builtin = @import("builtin");

// ============================================================================
// Time Functions
// ============================================================================

var boot_time: i64 = 0;

pub fn millis() u32 {
    if (builtin.os.tag == .freestanding) {
        // ESP32: Use esp_timer_get_time() / 1000
        return @intCast(@as(u64, @intCast(esp_timer_get_time())) / 1000);
    } else {
        // Simulation: Use std.time
        const now = std.time.milliTimestamp();
        if (boot_time == 0) boot_time = now;
        return @intCast(now - boot_time);
    }
}

pub fn delay_ms(ms: u32) void {
    if (builtin.os.tag == .freestanding) {
        vTaskDelay(ms / portTICK_PERIOD_MS);
    } else {
        std.time.sleep(@as(u64, ms) * std.time.ns_per_ms);
    }
}

// ============================================================================
// GPIO Functions
// ============================================================================

pub fn gpio_set_output(pin: u8) void {
    if (builtin.os.tag == .freestanding) {
        _ = gpio_set_direction(pin, GPIO_MODE_OUTPUT);
    }
}

pub fn gpio_set_input(pin: u8) void {
    if (builtin.os.tag == .freestanding) {
        _ = gpio_set_direction(pin, GPIO_MODE_INPUT);
    }
}

pub fn gpio_write(pin: u8, value: bool) void {
    if (builtin.os.tag == .freestanding) {
        _ = gpio_set_level(pin, if (value) 1 else 0);
    }
}

pub fn gpio_read(pin: u8) bool {
    if (builtin.os.tag == .freestanding) {
        return gpio_get_level(pin) != 0;
    }
    return false;
}

// ============================================================================
// UART Functions
// ============================================================================

var uart_initialized = false;

pub fn uart_init(baud: u32) void {
    _ = baud;
    uart_initialized = true;
    if (builtin.os.tag == .freestanding) {
        // ESP32: Configure UART0 for serial output
        // uart_config_t uart_config = { .baud_rate = baud, ... };
        // uart_driver_install(UART_NUM_0, ...);
    }
}

pub fn print(msg: []const u8) void {
    if (builtin.os.tag == .freestanding) {
        // ESP32: Use uart_write_bytes or printf
        _ = printf("%.*s", msg.len, msg.ptr);
    } else {
        // Simulation: Use std.debug
        std.debug.print("{s}", .{msg});
    }
}

// ============================================================================
// I2C Functions
// ============================================================================

pub fn i2c_init(sda: u8, scl: u8) void {
    _ = sda;
    _ = scl;
    if (builtin.os.tag == .freestanding) {
        // ESP32: i2c_param_config, i2c_driver_install
    }
}

pub fn i2c_write(addr: u7, data: []const u8) bool {
    _ = addr;
    _ = data;
    if (builtin.os.tag == .freestanding) {
        // ESP32: i2c_master_write_to_device
        return true;
    }
    return true;
}

pub fn i2c_read(addr: u7, reg: u8, buf: []u8) bool {
    _ = addr;
    _ = reg;
    _ = buf;
    if (builtin.os.tag == .freestanding) {
        // ESP32: i2c_master_write_read_device
        return true;
    }
    return true;
}

// ============================================================================
// SPIFFS Functions
// ============================================================================

pub fn spiffs_init() bool {
    if (builtin.os.tag == .freestanding) {
        // ESP32: esp_vfs_spiffs_register
        return true;
    }
    return true;
}

// ============================================================================
// NVS Functions
// ============================================================================

pub fn nvs_get_string(key: []const u8, buf: []u8) ?usize {
    _ = key;
    _ = buf;
    if (builtin.os.tag == .freestanding) {
        // ESP32: nvs_get_str
    }
    return null;
}

pub fn nvs_set_string(key: []const u8, value: []const u8) void {
    _ = key;
    _ = value;
    if (builtin.os.tag == .freestanding) {
        // ESP32: nvs_set_str, nvs_commit
    }
}

// ============================================================================
// System Functions
// ============================================================================

pub fn get_chip_id() u32 {
    if (builtin.os.tag == .freestanding) {
        // ESP32: ESP.getEfuseMac() lower 32 bits
        var mac: [6]u8 = undefined;
        _ = esp_efuse_mac_get_default(&mac);
        return @as(u32, mac[0]) | (@as(u32, mac[1]) << 8) |
            (@as(u32, mac[2]) << 16) | (@as(u32, mac[3]) << 24);
    }
    return 0xDEADBEEF;
}

pub fn getFreeHeap() u32 {
    if (builtin.os.tag == .freestanding) {
        return esp_get_free_heap_size();
    }
    return 0;
}

pub fn restart() noreturn {
    if (builtin.os.tag == .freestanding) {
        esp_restart();
    }
    unreachable;
}

// ============================================================================
// Watchdog Functions
// ============================================================================

pub fn wdt_init(timeout_ms: u32) void {
    _ = timeout_ms;
    if (builtin.os.tag == .freestanding) {
        // ESP32: esp_task_wdt_init
    }
}

pub fn wdt_reset() void {
    if (builtin.os.tag == .freestanding) {
        // ESP32: esp_task_wdt_reset
    }
}

// ============================================================================
// ESP-IDF External Declarations (freestanding only)
// ============================================================================

const GPIO_MODE_OUTPUT: c_int = 2;
const GPIO_MODE_INPUT: c_int = 1;
const portTICK_PERIOD_MS: u32 = 1;

extern fn esp_timer_get_time() i64;
extern fn vTaskDelay(ticks: u32) void;
extern fn gpio_set_direction(pin: u8, mode: c_int) c_int;
extern fn gpio_set_level(pin: u8, level: u32) c_int;
extern fn gpio_get_level(pin: u8) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn esp_efuse_mac_get_default(mac: *[6]u8) c_int;
extern fn esp_get_free_heap_size() u32;
extern fn esp_restart() noreturn;
