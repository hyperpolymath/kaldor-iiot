// SPDX-License-Identifier: AGPL-3.0-or-later
// Kaldor IIoT - BBW Sensor Board Firmware (Zig)
// Build configuration for ESP32 target

const std = @import("std");

pub fn build(b: *std.Build) void {
    // ESP32 target (Xtensa LX6)
    // For ESP32-C3/S3, use riscv32 instead
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .xtensa,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    // Main firmware executable
    const exe = b.addExecutable(.{
        .name = "kaldor-bbw-firmware",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link with ESP-IDF components (when available)
    // exe.linkSystemLibrary("esp_wifi");
    // exe.linkSystemLibrary("esp_event");
    // exe.linkSystemLibrary("nvs_flash");

    b.installArtifact(exe);

    // Unit tests (run on host)
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Generate binary for flashing
    const bin = b.addObjCopy(exe.getEmittedBin(), .{
        .format = .bin,
    });
    bin.step.dependOn(&exe.step);

    const copy_bin = b.addInstallBinFile(bin.getOutput(), "kaldor-bbw-firmware.bin");
    b.default_step.dependOn(&copy_bin.step);
}
