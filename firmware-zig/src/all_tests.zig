// SPDX-License-Identifier: MPL-2.0
//
// Kaldor IIoT firmware — host-side test runner.
//
// Pulls in unit tests from each submodule. main.zig is excluded here because
// it contains firmware stubs (hal.*, mqtt_client, etc.) that only compile
// when targeting ESP32/freestanding; host tests would fail on those externs.

const std = @import("std");

test {
    _ = @import("buffer.zig");
    _ = @import("sensors.zig");
    _ = @import("mqtt.zig");
    _ = @import("ota.zig");
    _ = @import("wifi.zig");
}
