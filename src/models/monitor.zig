const std = @import("std");

const Condition = @import("condition.zig");
const Process = @import("process.zig");

const Container = @import("~").models.Container;
const Queue = @import("~").utils.Queue;

const Self = @This();

notfull: Condition,
notempty: Condition,

buffer: Container,

fn init(alloc: std.mem.Allocator) !Self {
    return .{
        .notempty = try .init(alloc),
        .notfull = try .init(alloc),
        .buffer = .init(),
    };
}

pub fn append(
    self: *Self,
    p: *Process,
    x: Container.CONTAINER_ELEMENT,
) bool {
    if (self.buffer.isFull()) {
        cwait(p, self.notfull) catch void;
        return false;
    }
    self.buffer.write(x) catch unreachable;

    csignal(self.notempty) catch void;
    return true;
}
pub fn take(self: *Self, p: *Process) ?Container.CONTAINER_ELEMENT {
    if (self.buffer.isEmpty()) {
        cwait(p, self.notempty) catch void;
        return null;
    }

    csignal(self.notfull) catch void;
    return self.buffer.read() catch unreachable;
}

fn cwait(p: *Process, c: *Condition) !void {
    p.v_block();
    try c.wait(p); // Fails if no memory is left to grow wait queue
}
fn csignal(c: *Condition) !*Process {
    const p = try c.signal();
    p.v_unblock();
}
