const std = @import("std");

const Monitor = @import("monitor.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

const MIN_TO_WRITE = 3;
const MAX_TO_WRITE = 6;

alloc: std.mem.Allocator,

monitor: *Monitor,
process_impl: Process,

in_monitor: bool,
blocked: bool,

produced: []Container.CONTAINER_ELEMENT,
elems_to_write: u8,

ms_to_sleep: i128,
ms_to_write: i128,

random: std.Random,

pub fn init(self: *Self, alloc: std.mem.Allocator, m: *Monitor, random: std.Random) void {
    self.* = .{
        .alloc = alloc,

        .monitor = m,
        .process_impl = Process.implBy(self),

        .in_monitor = false,
        .blocked = false,

        .produced = &.{},
        .elems_to_write = 0,

        .ms_to_sleep = 3000,
        .ms_to_write = 0,

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
        self.monitor.beginWrite(&self.process_impl, &self.produced);
        return;
    }
    if (self.in_monitor) {
        self.ms_to_write = @max(self.ms_to_write - delta, 0);
        if (self.ms_to_write <= 0) self.monitor.finishWrite(&self.process_impl, &self.produced);
        return;
    }

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

    self.ms_to_write = self.random.intRangeAtMost(i128, 3000, 8000);
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
    return self.elems_to_write > 0 and !self.in_monitor and self.ms_to_write > 0;
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
    std.debug.assert(self.in_monitor and !self.blocked and self.ms_to_write <= 0);
    self.in_monitor = false;
}
