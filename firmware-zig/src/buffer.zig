// SPDX-License-Identifier: MPL-2.0
//! Kaldor IIoT - Data Buffer
//!
//! Ring buffer for offline data storage.
//! Buffers sensor readings when MQTT is unavailable.

const std = @import("std");
const sensors = @import("sensors.zig");

/// Maximum buffer capacity
const MAX_CAPACITY: usize = 1000;

/// Ring buffer for sensor data
pub const DataBuffer = struct {
    data: [MAX_CAPACITY]sensors.SensorData = undefined,
    head: usize = 0,
    tail: usize = 0,
    count: usize = 0,
    capacity: usize = 100,
    overflow_count: u32 = 0,

    const Self = @This();

    /// Initialize buffer with given capacity
    pub fn init(capacity: usize) Self {
        return Self{
            .capacity = @min(capacity, MAX_CAPACITY),
        };
    }

    /// Add reading to buffer
    pub fn add(self: *Self, data: sensors.SensorData) void {
        self.data[self.head] = data;
        self.head = (self.head + 1) % self.capacity;

        if (self.count < self.capacity) {
            self.count += 1;
        } else {
            // Buffer full, overwrite oldest
            self.tail = (self.tail + 1) % self.capacity;
            self.overflow_count += 1;
        }
    }

    /// Get oldest reading (FIFO)
    pub fn get(self: *Self) ?sensors.SensorData {
        if (self.count == 0) {
            return null;
        }

        const data = self.data[self.tail];
        self.tail = (self.tail + 1) % self.capacity;
        self.count -= 1;

        return data;
    }

    /// Peek at oldest reading without removing
    pub fn peek(self: *const Self) ?sensors.SensorData {
        if (self.count == 0) {
            return null;
        }
        return self.data[self.tail];
    }

    /// Get current buffer size
    pub fn size(self: *const Self) usize {
        return self.count;
    }

    /// Check if buffer is empty
    pub fn isEmpty(self: *const Self) bool {
        return self.count == 0;
    }

    /// Check if buffer is full
    pub fn isFull(self: *const Self) bool {
        return self.count >= self.capacity;
    }

    /// Clear buffer
    pub fn clear(self: *Self) void {
        self.head = 0;
        self.tail = 0;
        self.count = 0;
    }

    /// Get overflow count
    pub fn getOverflowCount(self: *const Self) u32 {
        return self.overflow_count;
    }

    /// Get all buffered readings as slice (for batch upload)
    pub fn getAll(self: *Self, out: []sensors.SensorData) usize {
        var i: usize = 0;
        while (i < out.len) {
            if (self.get()) |data| {
                out[i] = data;
                i += 1;
            } else {
                break;
            }
        }
        return i;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "buffer add and get" {
    var buf = DataBuffer.init(10);
    try std.testing.expect(buf.isEmpty());

    const data1 = sensors.SensorData{ .bbw = 100.0, .timestamp = 1 };
    buf.add(data1);

    try std.testing.expectEqual(@as(usize, 1), buf.size());
    try std.testing.expect(!buf.isEmpty());

    const retrieved = buf.get();
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqual(@as(f32, 100.0), retrieved.?.bbw);
    try std.testing.expect(buf.isEmpty());
}

test "buffer overflow" {
    var buf = DataBuffer.init(3);

    buf.add(sensors.SensorData{ .bbw = 1.0, .timestamp = 1 });
    buf.add(sensors.SensorData{ .bbw = 2.0, .timestamp = 2 });
    buf.add(sensors.SensorData{ .bbw = 3.0, .timestamp = 3 });
    try std.testing.expectEqual(@as(usize, 3), buf.size());

    // Add one more, should overwrite oldest
    buf.add(sensors.SensorData{ .bbw = 4.0, .timestamp = 4 });
    try std.testing.expectEqual(@as(usize, 3), buf.size());
    try std.testing.expectEqual(@as(u32, 1), buf.getOverflowCount());

    // Should get 2.0 (oldest remaining), not 1.0
    const first = buf.get();
    try std.testing.expectEqual(@as(f32, 2.0), first.?.bbw);
}

test "buffer peek" {
    var buf = DataBuffer.init(5);
    buf.add(sensors.SensorData{ .bbw = 42.0, .timestamp = 1 });

    const peeked = buf.peek();
    try std.testing.expectEqual(@as(f32, 42.0), peeked.?.bbw);
    try std.testing.expectEqual(@as(usize, 1), buf.size()); // Still in buffer
}
