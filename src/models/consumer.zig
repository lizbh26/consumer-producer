const std = @import("std");

const Monitor = @import("monitor/monitor.zig");
const Process = @import("monitor/process.zig");
const Container = @import("container.zig");

const Self = @This();

monitor: *const Monitor,
blocked_by_monitor: bool,

consumed: ?Container.CONTAINER_ELEMENT,
left_to_consume: u8,

ms_to_consume: i128,
ms_to_sleep: i128,
ms_worked: i128,

random: std.Random,

pub fn init(m: *Monitor, random: std.Random) Self {
    const self = Self{
        .monitor = m,
        .blocked_by_monitor = false,

        .consumed = null,
        .left_to_consume = 0,

        .ms_to_consume = 0,
        .ms_to_sleep = 0,
        .ms_worked = 0,

        .random = random,
    };
    self.sleep();
    return self;
}

pub fn tick(self: *Self, delta: i128) void {
    if (self.isBlocked()) return;

    if (self.isSleeping()) {
        self.tickSleep(delta);
        return;
    }

    if (self.isFinished()) {
        self.kickstartConsumption();
    }

    if (self.consumed == null) {
        if (self.monitor.take()) |e| {
            self.consumed = e;
            self.ms_to_consume = self.random.intRangeAtMost(i128, 2000, 8000);
        } else return;
    }

    if (self.isConsuming()) {
        self.tickProduction(delta);
        return;
    }

    self.left_to_consume -= 1;
    if (self.isFinished()) {
        self.sleep();
    }
}
fn tickSleep(self: *Self, delta: i128) void {
    std.debug.assert(self.isSleeping() and !self.isConsuming() and !self.isBlocked());
    self.ms_to_sleep -= delta;
}
fn tickProduction(self: *Self, delta: i128) void {
    std.debug.assert(self.ms_to_produce > 0);
    self.ms_to_consume -= delta;
    self.ms_worked += delta;
}

fn kickstartConsumption(self: *Self) void {
    std.debug.assert(!self.isConsuming());
    self.left_to_consume = self.random.intRangeAtMost(u8, 3, 6);
}
fn consume(self: *Self) void {
    std.debug.assert(self.consumed == null);
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
    self.blocked_by_monitor = false;
}
pub fn unblock(self: *Self) void {
    self.blocked_by_monitor = false;
}
