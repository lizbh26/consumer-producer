const std = @import("std");

const Condition = @import("condition.zig");
const Process = @import("process.zig");
const Container = @import("container.zig");

const Queue = @import("../utils/queue.zig").Queue;

const Self = @This();

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

pub fn append(
    self: *Self,
    p: *Process,
    x: Container.CONTAINER_ELEMENT,
) bool {
    if (self.container.isFull()) {
        cwait(p, &self.notfull) catch {};
        return false;
    }
    self.container.write(x) catch unreachable;

    csignal(self.alloc, &self.notempty) catch {};
    return true;
}
pub fn take(self: *Self, p: *Process) ?Container.CONTAINER_ELEMENT {
    if (self.container.isEmpty()) {
        cwait(p, &self.notempty) catch {};
        return null;
    }

    csignal(self.alloc, &self.notfull) catch {};
    return self.container.read() catch unreachable;
}

fn cwait(p: *Process, c: *Condition) !void {
    p.block();
    try c.wait(p); // Fails if no memory is left to grow wait queue
}
fn csignal(alloc: std.mem.Allocator, c: *Condition) !void {
    const p = try c.signal();
    p.unblock();
    alloc.destroy(p);
}
