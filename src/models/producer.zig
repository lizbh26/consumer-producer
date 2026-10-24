const std = @import("std");

const Monitor = @import("monitor/monitor.zig");
const Process = @import("monitor/process.zig");
const Container = @import("container.zig");

const Self = @This();

monitor: *const Monitor,
blocked_by_monitor: bool,

produced: ?Container.CONTAINER_ELEMENT,
left_to_produce: u8,

ms_to_produce: i128,
ms_to_sleep: i128,
ms_worked: i128,

random: std.Random,

pub fn init(m: *Monitor, random: std.Random) Self {
    const self = Self{
        .monitor = m,
        .blocked_by_monitor = false,

        .produced = null,
        .left_to_produce = 0,

        .ms_to_produce = 0,
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
        self.kickstartProduction();
    }

    if (self.isProducing()) {
        self.tickProduction(delta);
        return;
    }

    if (self.produced == null)
        self.produce();

    if (!self.monitor.append(self.produced.?))
        return;

    self.left_to_produce -= 1;
    if (self.isFinished()) {
        self.sleep();
    } else {
        self.beginProducing();
    }
}
fn tickSleep(self: *Self, delta: i128) void {
    std.debug.assert(self.isSleeping() and !self.isProducing() and !self.isBlocked());
    self.ms_to_sleep -= delta;
}
fn tickProduction(self: *Self, delta: i128) void {
    std.debug.assert(self.ms_to_produce > 0);
    self.ms_to_produce -= delta;
    self.ms_worked += delta;
}

fn kickstartProduction(self: *Self) void {
    std.debug.assert(!self.isProducing());
    self.left_to_produce = self.random.intRangeAtMost(u8, 3, 6);
    self.beginProducing();
}
fn beginProducing(self: *Self) void {
    self.ms_to_produce = self.random.intRangeAtMost(i128, 2000, 8000);
    self.produced = null;
}
fn produce(self: *Self) void {
    std.debug.assert(self.produced == null);
    self.produced = self.random.intRangeAtMost(
        Container.CONTAINER_ELEMENT,
        std.math.minInt(Container.CONTAINER_ELEMENT),
        std.math.maxInt(Container.CONTAINER_ELEMENT),
    );
}

fn sleep(self: *Self) void {
    std.debug.assert(!self.isBlocked() and !self.isProducing() and !self.isSleeping());
    self.ms_to_sleep = self.random.intRangeAtMost(i128, 2000, 8000);
    self.produced = null;
}

fn isFinished(self: *Self) bool {
    return self.left_to_produce == 0;
}
pub fn isProducing(self: *Self) bool {
    return self.left_to_produce > 0 and self.ms_to_produce > 0;
}
pub fn isSleeping(self: *Self) bool {
    return self.ms_to_sleep > 0;
}

pub fn isBlocked(self: *Self) bool {
    return self.blocked_by_monitor;
}
pub fn block(self: *Self) void {
    self.blocked_by_monitor = false;
}
pub fn unblock(self: *Self) void {
    self.blocked_by_monitor = false;
}

pub fn getState(self: *Self) enum { Producing, Blocked, Sleeping } {
    if (self.isBlocked()) return .Blocked;
    if (self.isProducing()) return .Producing;
    if (self.isSleeping()) return .Sleeping;
    unreachable;
}
