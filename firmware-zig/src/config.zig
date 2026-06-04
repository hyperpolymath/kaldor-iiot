// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Kaldor IIoT - Configuration Constants
//!
//! Build-time configuration for the BBW sensor board.
//! For production, these should be loaded from NVS or provisioned via secure boot.

// WiFi Configuration
pub const WIFI_SSID: [:0]const u8 = "KaldorIIoT";
pub const WIFI_PASSWORD: [:0]const u8 = ""; // Set via provisioning

// MQTT Configuration
pub const MQTT_BROKER: [:0]const u8 = "mqtt.kaldor.io";
pub const MQTT_PORT: u16 = 8883; // TLS port
pub const MQTT_USER: [:0]const u8 = "";
pub const MQTT_PASSWORD: [:0]const u8 = "";

// I2C Configuration
pub const I2C_SDA: u8 = 21;
pub const I2C_SCL: u8 = 22;
pub const I2C_FREQ: u32 = 400_000; // 400kHz

// Ultrasonic Sensor (HC-SR04)
pub const ULTRASONIC_TRIG: u8 = 12;
pub const ULTRASONIC_ECHO: u8 = 13;

// DHT Temperature Sensor
pub const DHT_PIN: u8 = 14;
pub const DHT_TYPE: DhtType = .dht22;

pub const DhtType = enum {
    dht11,
    dht22,
};

// Accelerometer (ADXL345) I2C Address
pub const ADXL345_ADDR: u7 = 0x53;

// BBW Thresholds (millimeters)
pub const BBW_MIN_THRESHOLD: f32 = 10.0;
pub const BBW_MAX_THRESHOLD: f32 = 500.0;

// Calibration offsets
pub const BBW_OFFSET: f32 = 0.0;
pub const TEMP_OFFSET: f32 = 0.0;

// Buffer sizes
pub const DATA_BUFFER_SIZE: usize = 100;
pub const MQTT_BUFFER_SIZE: usize = 1024;

// Timing (milliseconds)
pub const SENSOR_SAMPLE_INTERVAL: u32 = 10; // 100Hz
pub const TELEMETRY_PUBLISH_INTERVAL: u32 = 1000; // 1Hz
pub const WIFI_RECONNECT_INTERVAL: u32 = 10_000;
pub const MQTT_RECONNECT_INTERVAL: u32 = 5_000;
pub const WATCHDOG_TIMEOUT: u32 = 30_000;

// OTA Configuration
pub const OTA_PARTITION_LABEL: [:0]const u8 = "ota_0";
pub const OTA_BUFFER_SIZE: usize = 4096;
