// SPDX-License-Identifier: MPL-2.0
//! Kaldor IIoT - Sensor Management
//!
//! Manages multi-sensor data acquisition:
//! - Ultrasonic distance (Back Beam Width)
//! - Temperature (DHT22)
//! - Vibration (ADXL345 accelerometer)

const std = @import("std");
const config = @import("config.zig");
const hal = @import("hal.zig");

/// Sensor reading with all measurements
pub const SensorData = struct {
    /// Back Beam Width in millimeters
    bbw: f32 = 0,
    bbw_min: f32 = std.math.floatMax(f32),
    bbw_max: f32 = 0,
    bbw_stddev: f32 = 0,
    /// Signal quality (0-100)
    quality: u8 = 0,
    /// Temperature in Celsius
    temperature: f32 = 0,
    /// Vibration magnitude (m/s²)
    vibration: f32 = 0,
    /// Timestamp
    timestamp: u32 = 0,
};

/// Manages all sensor subsystems
pub const SensorManager = struct {
    // Ultrasonic state
    ultrasonic_initialized: bool = false,

    // Temperature state
    dht_initialized: bool = false,
    last_temp_read: u32 = 0,
    cached_temperature: f32 = 0,

    // Accelerometer state
    accel_initialized: bool = false,

    // Aggregation state
    sample_count: u32 = 0,
    bbw_sum: f64 = 0,
    bbw_sum_sq: f64 = 0,
    bbw_min: f32 = std.math.floatMax(f32),
    bbw_max: f32 = 0,
    last_bbw: f32 = 0,

    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    /// Initialize all sensors
    pub fn begin(self: *Self) bool {
        var all_ok = true;

        // Initialize ultrasonic sensor
        hal.gpio_set_output(config.ULTRASONIC_TRIG);
        hal.gpio_set_input(config.ULTRASONIC_ECHO);
        self.ultrasonic_initialized = true;

        // Initialize DHT sensor
        hal.gpio_set_input(config.DHT_PIN);
        self.dht_initialized = true;

        // Initialize accelerometer via I2C
        if (!self.initAccelerometer()) {
            all_ok = false;
        }

        return all_ok;
    }

    /// Initialize ADXL345 accelerometer
    fn initAccelerometer(self: *Self) bool {
        // Check WHO_AM_I register (0x00 should return 0xE5)
        var buf: [1]u8 = undefined;
        if (!hal.i2c_read(config.ADXL345_ADDR, 0x00, &buf)) {
            return false;
        }
        if (buf[0] != 0xE5) {
            return false;
        }

        // Set measurement mode (POWER_CTL register 0x2D)
        const power_ctl = [_]u8{ 0x2D, 0x08 };
        if (!hal.i2c_write(config.ADXL345_ADDR, &power_ctl)) {
            return false;
        }

        // Set data format (DATA_FORMAT register 0x31) - +/- 16g, full resolution
        const data_fmt = [_]u8{ 0x31, 0x0B };
        if (!hal.i2c_write(config.ADXL345_ADDR, &data_fmt)) {
            return false;
        }

        self.accel_initialized = true;
        return true;
    }

    /// Read all sensors
    pub fn read(self: *Self) SensorData {
        var data = SensorData{
            .timestamp = hal.millis(),
        };

        // Read ultrasonic (BBW)
        if (self.ultrasonic_initialized) {
            const distance = self.readUltrasonic();
            data.bbw = distance + config.BBW_OFFSET;
            data.quality = self.calculateQuality(distance);

            // Update aggregation
            self.sample_count += 1;
            self.bbw_sum += distance;
            self.bbw_sum_sq += distance * distance;
            if (distance < self.bbw_min) self.bbw_min = distance;
            if (distance > self.bbw_max) self.bbw_max = distance;
            self.last_bbw = distance;
        }

        // Read temperature (cached, DHT is slow)
        if (self.dht_initialized) {
            const now = hal.millis();
            if (now - self.last_temp_read >= 2000) { // DHT22 needs 2s between reads
                self.cached_temperature = self.readTemperature();
                self.last_temp_read = now;
            }
            data.temperature = self.cached_temperature + config.TEMP_OFFSET;
        }

        // Read accelerometer
        if (self.accel_initialized) {
            data.vibration = self.readVibration();
        }

        return data;
    }

    /// Get aggregated data and reset
    pub fn getAggregated(self: *Self) SensorData {
        var data = SensorData{
            .timestamp = hal.millis(),
            .temperature = self.cached_temperature + config.TEMP_OFFSET,
        };

        if (self.sample_count > 0) {
            const n: f64 = @floatFromInt(self.sample_count);
            const mean = self.bbw_sum / n;
            const variance = (self.bbw_sum_sq / n) - (mean * mean);
            const stddev = @sqrt(@max(0, variance));

            data.bbw = @floatCast(mean + config.BBW_OFFSET);
            data.bbw_min = self.bbw_min + config.BBW_OFFSET;
            data.bbw_max = self.bbw_max + config.BBW_OFFSET;
            data.bbw_stddev = @floatCast(stddev);
            data.quality = self.calculateQuality(@floatCast(mean));
        }

        if (self.accel_initialized) {
            data.vibration = self.readVibration();
        }

        // Reset aggregation
        self.sample_count = 0;
        self.bbw_sum = 0;
        self.bbw_sum_sq = 0;
        self.bbw_min = std.math.floatMax(f32);
        self.bbw_max = 0;

        return data;
    }

    /// Read HC-SR04 ultrasonic sensor
    fn readUltrasonic(self: *Self) f32 {
        _ = self;

        // Send 10µs trigger pulse
        hal.gpio_write(config.ULTRASONIC_TRIG, false);
        hal.delay_ms(1);
        hal.gpio_write(config.ULTRASONIC_TRIG, true);
        // Note: In real implementation, need µs delay
        hal.gpio_write(config.ULTRASONIC_TRIG, false);

        // Measure echo pulse duration
        // In freestanding, use hardware timer or pulse counter
        // Distance = (pulse_duration_us * speed_of_sound) / 2
        // speed_of_sound ≈ 343 m/s = 0.0343 cm/µs

        // Placeholder: Return simulated value
        const base_distance: f32 = 150.0; // mm
        const noise = @as(f32, @floatFromInt(hal.millis() % 100)) / 100.0 - 0.5;
        return base_distance + noise * 2.0;
    }

    /// Read DHT22 temperature sensor
    fn readTemperature(self: *Self) f32 {
        _ = self;

        // DHT22 uses a custom 1-wire protocol
        // In freestanding, implement bit-banging protocol

        // Placeholder: Return simulated value
        return 25.0 + @as(f32, @floatFromInt(hal.millis() % 100)) / 100.0;
    }

    /// Read ADXL345 accelerometer and compute vibration magnitude
    fn readVibration(self: *Self) f32 {
        _ = self;

        // Read 6 bytes starting from DATAX0 (0x32)
        var buf: [6]u8 = undefined;
        if (!hal.i2c_read(config.ADXL345_ADDR, 0x32, &buf)) {
            return 0;
        }

        // Convert to signed 16-bit (little endian)
        const x: i16 = @bitCast([2]u8{ buf[0], buf[1] });
        const y: i16 = @bitCast([2]u8{ buf[2], buf[3] });
        const z: i16 = @bitCast([2]u8{ buf[4], buf[5] });

        // Convert to m/s² (scale factor for +/- 16g mode)
        const scale: f32 = 0.004 * 9.81; // 4mg/LSB * 9.81 m/s²
        const ax: f32 = @as(f32, @floatFromInt(x)) * scale;
        const ay: f32 = @as(f32, @floatFromInt(y)) * scale;
        const az: f32 = @as(f32, @floatFromInt(z)) * scale;

        // Compute magnitude (removing gravity)
        const g: f32 = 9.81;
        const az_no_g = az - g;
        return @sqrt(ax * ax + ay * ay + az_no_g * az_no_g);
    }

    /// Calculate signal quality based on distance
    fn calculateQuality(self: *const Self, distance: f32) u8 {
        _ = self;

        // Quality degrades with distance and noise
        if (distance < 20 or distance > 400) {
            return 0; // Out of range
        }

        // Good quality in optimal range
        if (distance >= 50 and distance <= 300) {
            return 95;
        }

        // Degraded quality at edges
        if (distance < 50) {
            return @intFromFloat(50 + (distance / 50.0) * 45);
        } else {
            return @intFromFloat(95 - ((distance - 300) / 100.0) * 45);
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SensorManager initialization" {
    const sm = SensorManager.init();
    // begin() would fail without hardware, but init() should work
    try std.testing.expect(!sm.ultrasonic_initialized);
    try std.testing.expect(!sm.dht_initialized);
}

test "quality calculation" {
    const sm = SensorManager.init();
    try std.testing.expectEqual(@as(u8, 0), sm.calculateQuality(10));
    try std.testing.expectEqual(@as(u8, 95), sm.calculateQuality(150));
    try std.testing.expectEqual(@as(u8, 0), sm.calculateQuality(500));
}
