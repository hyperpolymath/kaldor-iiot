// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
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

    // Main firmware executable (Zig 0.15+: use root_module)
    const exe = b.addExecutable(.{
        .name = "kaldor-bbw-firmware",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link with ESP-IDF components (when available)
    // exe.linkSystemLibrary("esp_wifi");
    // exe.linkSystemLibrary("esp_event");
    // exe.linkSystemLibrary("nvs_flash");

    b.installArtifact(exe);

    // Unit tests (run on host — Zig 0.15+: use root_module).
    // Uses all_tests.zig as root to avoid main.zig's freestanding-only externs.
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/all_tests.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
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
