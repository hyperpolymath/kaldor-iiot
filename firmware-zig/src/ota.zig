// SPDX-License-Identifier: PMPL-1.0-or-later
//! Kaldor IIoT - OTA Firmware Updater
//!
//! Over-the-air firmware updates with rollback support.

const std = @import("std");
const builtin = @import("builtin");
const hal = @import("hal.zig");
const config = @import("config.zig");

/// OTA update state
pub const OtaState = enum {
    idle,
    downloading,
    verifying,
    installing,
    complete,
    error_state,
};

/// OTA error codes
pub const OtaError = enum {
    none,
    network_error,
    invalid_url,
    download_failed,
    verify_failed,
    install_failed,
    insufficient_space,
    version_mismatch,
};

/// OTA Updater
pub const OtaUpdater = struct {
    device_id: []const u8,
    state: OtaState = .idle,
    error: OtaError = .none,
    progress: u8 = 0,
    current_url: ?[]const u8 = null,
    bytes_received: usize = 0,
    total_bytes: usize = 0,

    const Self = @This();

    pub fn init(device_id: []const u8) Self {
        return Self{
            .device_id = device_id,
        };
    }

    /// Start OTA update from URL
    pub fn update(self: *Self, url: []const u8) void {
        if (self.state != .idle) {
            hal.print("OTA: Already in progress\n");
            return;
        }

        hal.print("OTA: Starting update from: ");
        hal.print(url);
        hal.print("\n");

        self.current_url = url;
        self.state = .downloading;
        self.progress = 0;
        self.bytes_received = 0;
        self.error = .none;

        if (builtin.os.tag == .freestanding) {
            // ESP32: Start OTA update
            // esp_https_ota_config_t config = { ... };
            // esp_https_ota(&config);
            ota_begin(url.ptr, url.len);
        }
    }

    /// Handle OTA progress (call in main loop)
    pub fn handle(self: *Self) void {
        switch (self.state) {
            .idle => {},
            .downloading => {
                if (builtin.os.tag == .freestanding) {
                    var received: usize = 0;
                    var total: usize = 0;
                    const status = ota_get_progress(&received, &total);

                    self.bytes_received = received;
                    self.total_bytes = total;

                    if (total > 0) {
                        self.progress = @intCast((received * 100) / total);
                    }

                    if (status == 1) {
                        // Download complete
                        self.state = .verifying;
                        hal.print("OTA: Download complete, verifying...\n");
                    } else if (status < 0) {
                        // Error
                        self.state = .error_state;
                        self.error = .download_failed;
                        hal.print("OTA: Download failed\n");
                    }
                } else {
                    // Simulation: Progress over time
                    self.progress += 10;
                    if (self.progress >= 100) {
                        self.state = .verifying;
                    }
                }
            },
            .verifying => {
                if (builtin.os.tag == .freestanding) {
                    if (ota_verify()) {
                        self.state = .installing;
                        hal.print("OTA: Verification passed, installing...\n");
                    } else {
                        self.state = .error_state;
                        self.error = .verify_failed;
                        hal.print("OTA: Verification failed\n");
                    }
                } else {
                    self.state = .installing;
                }
            },
            .installing => {
                if (builtin.os.tag == .freestanding) {
                    if (ota_finish()) {
                        self.state = .complete;
                        hal.print("OTA: Update complete, rebooting...\n");
                        hal.delay_ms(1000);
                        hal.restart();
                    } else {
                        self.state = .error_state;
                        self.error = .install_failed;
                    }
                } else {
                    self.state = .complete;
                    hal.print("OTA: Update complete (simulation)\n");
                }
            },
            .complete => {
                // Reset state after completion
                self.state = .idle;
                self.current_url = null;
            },
            .error_state => {
                // Log error and reset
                hal.print("OTA: Error occurred, resetting\n");
                self.state = .idle;
                self.current_url = null;
            },
        }
    }

    /// Get current progress (0-100)
    pub fn getProgress(self: *const Self) u8 {
        return self.progress;
    }

    /// Get current state
    pub fn getState(self: *const Self) OtaState {
        return self.state;
    }

    /// Get last error
    pub fn getError(self: *const Self) OtaError {
        return self.error;
    }

    /// Check if update is in progress
    pub fn isUpdating(self: *const Self) bool {
        return self.state != .idle and self.state != .complete and self.state != .error_state;
    }

    /// Abort current update
    pub fn abort(self: *Self) void {
        if (self.isUpdating()) {
            hal.print("OTA: Aborting update\n");
            if (builtin.os.tag == .freestanding) {
                ota_abort();
            }
            self.state = .idle;
            self.current_url = null;
        }
    }

    /// Mark current firmware as valid (prevent rollback)
    pub fn markValid(self: *Self) void {
        _ = self;
        if (builtin.os.tag == .freestanding) {
            ota_mark_valid();
        }
        hal.print("OTA: Firmware marked as valid\n");
    }

    /// Rollback to previous firmware
    pub fn rollback(self: *Self) void {
        _ = self;
        hal.print("OTA: Rolling back to previous firmware...\n");
        if (builtin.os.tag == .freestanding) {
            ota_rollback();
        }
    }
};

// ============================================================================
// ESP-IDF External Declarations
// ============================================================================

extern fn ota_begin(url: [*]const u8, len: usize) void;
extern fn ota_get_progress(received: *usize, total: *usize) c_int;
extern fn ota_verify() bool;
extern fn ota_finish() bool;
extern fn ota_abort() void;
extern fn ota_mark_valid() void;
extern fn ota_rollback() void;

// ============================================================================
// Tests
// ============================================================================

test "ota updater init" {
    const ota = OtaUpdater.init("test-device");
    try std.testing.expectEqual(OtaState.idle, ota.getState());
    try std.testing.expect(!ota.isUpdating());
}
