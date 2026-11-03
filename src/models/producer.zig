const std = @import("std");

const Monitor = @import("monitor.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

const MIN_TO_WRITE = 3;
const MAX_TO_WRITE = 6;

alloc: std.mem.Allocator,

monitor: *Monitor,
in_monitor: bool,
blocked: bool,

produced: []Container.CONTAINER_ELEMENT,
write_completed: bool,
elems_to_write: u8,

ms_to_sleep: i128,

random: std.Random,

pub fn init(alloc: std.mem.Allocator, m: *Monitor, random: std.Random) Self {
    return Self{
        .alloc = alloc,

        .monitor = m,
        .in_monitor = false,
        .blocked = false,

        .produced = &.{},
        .write_completed = false,
        .elems_to_write = 0,

        .ms_to_sleep = 3000,

        .random = random,
    };
}

pub fn tick(self: *Self, delta: i128) !void {
    if (self.blocked) return;

    if (self.isSleeping()) {
        self.tickSleep(delta);
        return;
    }

    if (self.isFinished()) {
        try self.produce();
        return;
    }

    if (self.isTryingToWrite()) {
        self.monitor.write(self, &self.produced);
        return;
    }
    if (self.in_monitor) return;

    self.elems_to_write = 0;
    self.sleep();
}
fn tickSleep(self: *Self, delta: i128) void {
    std.debug.assert(self.isSleeping() and !self.isWriting() and !self.in_monitor);
    self.ms_to_sleep -= delta;
}

fn produce(self: *Self) !void {
    std.debug.assert(self.isFinished());
    self.elems_to_write = self.random.intRangeAtMost(u8, MIN_TO_WRITE, MAX_TO_WRITE);

    self.produced = try self.alloc.alloc(Container.CONTAINER_ELEMENT, self.elems_to_write);
    for (self.produced) |*p|
        p.* = self.random.intRangeAtMost(
            Container.CONTAINER_ELEMENT,
            std.math.minInt(Container.CONTAINER_ELEMENT),
            std.math.maxInt(Container.CONTAINER_ELEMENT),
        );

    self.write_completed = false;
}

fn sleep(self: *Self) void {
    std.debug.assert(!self.isBlocked() and !self.isWriting() and !self.isSleeping());
    self.ms_to_sleep = self.random.intRangeAtMost(i128, 2000, 5000);
    self.alloc.free(self.produced);
    self.produced = &.{};
}

pub fn isSleeping(self: Self) bool {
    return self.ms_to_sleep > 0;
}
pub fn isTryingToWrite(self: Self) bool {
    return self.elems_to_write > 0 and !self.in_monitor and !self.write_completed;
}
pub fn isWriting(self: Self) bool {
    return self.in_monitor and !self.blocked;
}
pub fn isBlocked(self: Self) bool {
    return self.blocked;
}
fn isFinished(self: Self) bool {
    return self.elems_to_write == 0 and !self.in_monitor;
}

pub fn enterMonitor(self: *Self) void {
    std.debug.assert(!self.in_monitor and !self.blocked);
    self.in_monitor = true;
}
pub fn blockByWait(self: *Self) void {
    std.debug.assert(self.in_monitor and !self.blocked);
    self.blocked = true;
    self.in_monitor = false;
}
pub fn unblock(self: *Self) void {
    std.debug.assert(!self.in_monitor and self.blocked);
    self.blocked = false;
}
pub fn exitMonitor(self: *Self) void {
    std.debug.assert(self.in_monitor and !self.blocked);
    self.in_monitor = false;
    self.write_completed = true;
}
