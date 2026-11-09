const std = @import("std");

const Condition = @import("condition.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Self = @This();

const ProcessBuffer = *[]Container.CONTAINER_ELEMENT;

alloc: std.mem.Allocator,

notfull: Condition,
notempty: Condition,

container: Container,

pub fn init(alloc: std.mem.Allocator) !Self {
    return .{
        .alloc = alloc,

        .notempty = try .init(alloc),
        .notfull = try .init(alloc),

        .container = .init(),
    };
}

pub fn beginWrite(self: *Self, p: *Process, x: ProcessBuffer) void {
    if (self.container.len + x.len > self.container.max_len) {
        cwait(&self.notfull, p) catch {};
        return;
    }
    p.enterMonitor();
}
pub fn finishWrite(self: *Self, p: *Process, x: ProcessBuffer) void {
    for (x.*) |e|
        self.container.write(e) catch unreachable;

    csignal(&self.notempty);
    p.exitMonitor();
}

pub fn beginTake(self: *Self, p: *Process, x: ProcessBuffer) void {
    if (self.container.len < x.len) {
        cwait(&self.notempty, p) catch {};
        return;
    }
    p.enterMonitor();
}
pub fn finishTake(self: *Self, p: *Process, x: ProcessBuffer) void {
    for (x.*) |*e|
        e.* = self.container.read() catch unreachable;

    csignal(&self.notfull);
    p.exitMonitor();
}

fn cwait(c: *Condition, p: *Process) !void {
    try c.wait(p); // Fails if no memory is left to grow wait queue
    p.blockByWait();
}
fn csignal(c: *Condition) void {
    const ptr = c.signal() catch return; // Fails if condition is empty
    ptr.unblock();
}
