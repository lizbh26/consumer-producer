const std = @import("std");

const Monitor = @import("monitor.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

alloc: std.mem.Allocator,

monitor: *Monitor,
blocked_by_monitor: bool,

consumed: ?Container.CONTAINER_ELEMENT,
left_to_consume: u8,

ms_to_consume: i128,
ms_to_sleep: i128,
ms_worked: i128,

random: std.Random,

pub fn init(alloc: std.mem.Allocator, m: *Monitor, random: std.Random) Self {
    return Self{
        .alloc = alloc,

        .monitor = m,
        .blocked_by_monitor = false,

        .consumed = null,
        .left_to_consume = 0,

        .ms_to_consume = 0,
        .ms_to_sleep = 0,
        .ms_worked = 0,

        .random = random,
    };
}

pub fn tick(self: *Self, delta: i128) !void {
    if (self.isBlocked()) return;

    if (self.isSleeping()) {
        self.tickSleep(delta);
        return;
    }

    if (self.isFinished()) {
        try self.kickstartConsumption();
    }

    if (self.isConsuming()) {
        self.tickConsumption(delta);
        return;
    }

    self.left_to_consume -= 1;
    if (self.isFinished()) {
        self.sleep();
    } else {
        try self.consume();
    }
}
fn tickSleep(self: *Self, delta: i128) void {
    std.debug.assert(self.isSleeping() and !self.isConsuming() and !self.isBlocked());
    self.ms_to_sleep -= delta;
}
fn tickConsumption(self: *Self, delta: i128) void {
    std.debug.assert(self.ms_to_consume > 0);
    self.ms_to_consume -= delta;
    self.ms_worked += delta;
}

fn kickstartConsumption(self: *Self) !void {
    std.debug.assert(!self.isConsuming());
    self.left_to_consume = self.random.intRangeAtMost(u8, 3, 6);
    try self.consume();
}
fn consume(self: *Self) !void {
    const ok = try self.criticalTake();
    if (ok)
        self.ms_to_consume = self.random.intRangeAtMost(i128, 2000, 8000);
}
fn criticalTake(self: *Self) !bool {
    const ptr = try self.alloc.create(Process);
    ptr.* = Process.implBy(self);
    self.consumed = self.monitor.take(ptr);
    return self.consumed == null;
}

fn sleep(self: *Self) void {
    std.debug.assert(!self.isBlocked() and !self.isConsuming() and !self.isSleeping());
    self.ms_to_sleep = self.random.intRangeAtMost(i128, 2000, 8000);
    self.consumed = null;
}

fn isFinished(self: Self) bool {
    return self.left_to_consume == 0;
}
pub fn isConsuming(self: Self) bool {
    return self.left_to_consume > 0 and self.ms_to_consume > 0;
}
pub fn isSleeping(self: Self) bool {
    return self.ms_to_sleep > 0;
}

pub fn isBlocked(self: Self) bool {
    return self.blocked_by_monitor;
}
pub fn block(self: *Self) void {
    self.blocked_by_monitor = true;
}
pub fn unblock(self: *Self) void {
    self.blocked_by_monitor = false;
}
