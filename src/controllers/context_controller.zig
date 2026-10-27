const std = @import("std");
const zeit = @import("zeit");

const Monitor = @import("~").models.Monitor;
const Consumer = @import("~").models.Consumer;
const Producer = @import("~").models.Producer;

const Self = @This();

monitor: Monitor,
consumer: Consumer,
producer: Producer,

randomSource: std.Random.IoSource,

prev_tick: ?zeit.Instant,
ellapsed_ms: i128,
is_paused: bool,

pub fn init(self: *Self, alloc: std.mem.Allocator, io: std.Io) !void {
    self.* = .{
        .monitor = try .init(alloc),
        .consumer = undefined,
        .producer = undefined,
        .randomSource = .{ .io = io },
        .prev_tick = null,
        .ellapsed_ms = 0,
        .is_paused = false,
    };
    self.consumer = .init(alloc, &self.monitor, self.randomSource.interface());
    self.producer = .init(alloc, &self.monitor, self.randomSource.interface());
}

pub fn tick(self: *Self, now: zeit.Instant) !void {
    if (self.prev_tick) |prev| {
        const delta_nano = now.timestamp - prev.timestamp;
        const delta_ms = zeit.instant(.{ .unix_nano = delta_nano }, &zeit.utc).milliTimestamp();

        try self.consumer.tick(delta_ms);
        try self.producer.tick(delta_ms);
    }
    self.prev_tick = now;
}
