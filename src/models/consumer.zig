const std = @import("std");

const Monitor = @import("monitor.zig");
const Container = @import("container.zig");

const Self = @This();

const MIN_TO_READ = 3;
const MAX_TO_READ = 6;

alloc: std.mem.Allocator,

monitor: *Monitor,
in_monitor: bool,
blocked: bool,

consumed: []Container.CONTAINER_ELEMENT,
read_completed: bool,
elems_to_read: u8,

ms_to_sleep: i128,

random: std.Random,

pub fn init(alloc: std.mem.Allocator, m: *Monitor, random: std.Random) Self {
    return Self{
        .alloc = alloc,

        .monitor = m,
        .in_monitor = false,
        .blocked = false,

        .consumed = &.{},
        .read_completed = false,
        .elems_to_read = 0,

        .ms_to_sleep = 0,

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

    // std.log.debug("{}{}", .{ self.in_monitor, self.blocked });
    if (self.isTryingToRead()) {
        self.monitor.take(self, &self.consumed);
        return;
    }
    if (self.in_monitor) return;

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
    self.read_completed = false;
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
    return self.elems_to_read > 0 and !self.in_monitor and !self.read_completed;
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
    self.read_completed = true;
}
