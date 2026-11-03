const std = @import("std");

const Condition = @import("condition.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

const ProcessBuffer = *[]Container.CONTAINER_ELEMENT;

alloc: std.mem.Allocator,

notfull: Condition,
notempty: Condition,

current: ?Process,
x: ProcessBuffer,
ms_left: i128,
finishFn: ?*const fn (self: *Self) void,

container: Container,
random: std.Random,

pub fn init(alloc: std.mem.Allocator, random: std.Random) !Self {
    return .{
        .alloc = alloc,
        .notempty = try .init(alloc),
        .notfull = try .init(alloc),

        .current = null,
        .ms_left = 0,
        .x = undefined,
        .finishFn = null,

        .container = .init(),
        .random = random,
    };
}

pub fn tick(self: *Self, delta: i128) void {
    if (self.current == null) return;

    self.ms_left = @max(self.ms_left - delta, 0);

    if (self.ms_left == 0 and self.finishFn != null) {
        if (self.finishFn) |fnc| {
            fnc(self);
            self.finishFn = null;
        }
        self.current = null;
    }
}

fn register(self: *Self, p: anytype) void {
    std.debug.assert(self.current == null);
    self.current = Process.implBy(p);
    self.current.?.enterMonitor();
}
fn deleteCurrent(self: *Self) void {
    if (self.current) |_| {
        self.current.?.exitMonitor();
        self.current = null;
    }
}

pub fn write(self: *Self, p: anytype, x: ProcessBuffer) void {
    if (self.current != null) return;
    self.register(p);
    self.x = x;
    self.finishFn = Self.finishWrite;

    if (self.container.len + x.len > self.container.max_len) {
        self.cwait(&self.notfull) catch {};
        return;
    }
    self.ms_left = self.random.intRangeAtMost(i128, 5000, 15000);
}
fn finishWrite(self: *Self) void {
    for (self.x.*) |e|
        self.container.write(e) catch unreachable;

    self.csignal(&self.notempty);
}

pub fn take(self: *Self, p: anytype, x: ProcessBuffer) void {
    if (self.current != null) return;
    self.register(p);
    self.x = x;
    self.finishFn = Self.finishTake;

    if (self.container.len < x.len) {
        self.cwait(&self.notempty) catch {};
        return;
    }
    self.ms_left = self.random.intRangeAtMost(i128, 4000, 8000);
}
fn finishTake(self: *Self) void {
    for (self.x.*) |*e|
        e.* = self.container.read() catch unreachable;

    self.csignal(&self.notfull);
}

fn cwait(self: *Self, c: *Condition) !void {
    const ptr = try self.alloc.create(Process);
    ptr.* = self.current orelse unreachable;
    try c.wait(ptr); // Fails if no memory is left to grow wait queue
    ptr.blockByWait();
    self.current = null;
}
fn csignal(self: *Self, c: *Condition) void {
    self.deleteCurrent();
    const ptr = c.signal() catch return; // Fails if condition is empty
    ptr.unblock();
    self.alloc.destroy(ptr);
}
