const std = @import("std");

const Monitor = @import("monitor.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

const MIN_TO_READ = 3;
const MAX_TO_READ = 6;

alloc: std.mem.Allocator,

monitor: *Monitor,
process_impl: Process,

in_monitor: bool,
blocked: bool,

consumed: []Container.CONTAINER_ELEMENT,
elems_to_read: u8,

ms_to_sleep: i128,
ms_to_read: i128,

random: std.Random,

pub fn init(self: *Self, alloc: std.mem.Allocator, m: *Monitor, random: std.Random) void {
    self.* = .{
        .alloc = alloc,

        .monitor = m,
        .process_impl = Process.implBy(self),

        .in_monitor = false,
        .blocked = false,

        .consumed = &.{},
        .elems_to_read = 0,

        .ms_to_sleep = 0,
        .ms_to_read = 0,

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
        try self.prepareConsumption();
        return;
    }

    if (self.isTryingToRead()) {
        self.monitor.beginTake(&self.process_impl, &self.consumed);
        return;
    }
    if (self.in_monitor) {
        self.ms_to_read = @max(self.ms_to_read - delta, 0);
        if (self.ms_to_read <= 0) self.monitor.finishTake(&self.process_impl, &self.consumed);
        return;
    }

    self.elems_to_read = 0;
    self.sleep();
}
fn tickSleep(self: *Self, delta: i128) void {
    std.debug.assert(self.isSleeping() and !self.isReading() and !self.in_monitor);
    self.ms_to_sleep -= delta;
}

fn prepareConsumption(self: *Self) !void {
    std.debug.assert(self.isFinished());
    self.elems_to_read = self.random.intRangeAtMost(u8, MIN_TO_READ, MAX_TO_READ);
    self.consumed = try self.alloc.alloc(Container.CONTAINER_ELEMENT, self.elems_to_read);
    self.ms_to_read = self.random.intRangeAtMost(i128, 2000, 6000);
}

fn sleep(self: *Self) void {
    std.debug.assert(!self.isBlocked() and !self.isReading() and !self.isSleeping());
    self.ms_to_sleep = self.random.intRangeAtMost(i128, 2000, 5000);
    self.alloc.free(self.consumed);
    self.consumed = &.{};
}

pub fn isSleeping(self: Self) bool {
    return self.ms_to_sleep > 0;
}
pub fn isTryingToRead(self: Self) bool {
    return self.elems_to_read > 0 and !self.in_monitor and self.ms_to_read > 0;
}
pub fn isReading(self: Self) bool {
    return self.in_monitor and !self.blocked;
}
pub fn isBlocked(self: Self) bool {
    return self.blocked;
}
fn isFinished(self: Self) bool {
    return self.elems_to_read == 0 and !self.in_monitor;
}

pub fn enterMonitor(self: *Self) void {
    std.debug.assert(!self.in_monitor and !self.blocked);
    self.in_monitor = true;
}
pub fn blockByWait(self: *Self) void {
    std.debug.assert(!self.in_monitor and !self.blocked);
    self.blocked = true;
}
pub fn unblock(self: *Self) void {
    std.debug.assert(!self.in_monitor and self.blocked);
    self.blocked = false;
}
pub fn exitMonitor(self: *Self) void {
    std.debug.assert(self.in_monitor and !self.blocked and self.ms_to_read <= 0);
    self.in_monitor = false;
}
