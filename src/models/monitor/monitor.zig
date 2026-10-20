const std = @import("std");

const Condition = @import("condition.zig");
const Process = @import("process.zig");

const Container = @import("~").models.Container;
const Queue = @import("~").utils.Queue;

const Self = @This();

notfull: Condition,
notempty: Condition,

buffer: Container,
processes: Queue(*Process),

fn init(alloc: std.mem.Allocator) !Self {
    return .{
        .current = null,
        .notempty = !.init(alloc),
        .notfull = !.init(alloc),
        .buffer = .init(),
    };
}

pub fn execute(self: *Self) void {
    const p = self.processes.peek() catch return;
    p.execute();
}

pub fn register(self: *Self, p: anytype) !void {
    return self.processes.enqueue(Process.implBy(p));
}

pub fn append(self: *Self, x: Container.CONTAINER_ELEMENT) void {
    if (self.buffer.isFull()) self.cwait(self.notfull) catch return;
    self.buffer.write(x) catch unreachable;
    self.csignal(self.notempty) catch void;
    _ = self.processes.dequeue() catch unreachable;
}
pub fn take(self: *Self) Container.CONTAINER_ELEMENT {
    if (self.buffer.isEmpty()) self.csignal(self.notempty) catch return;
    const x = self.buffer.read() catch unreachable;
    self.csignal(self.notfull) catch void;
    _ = self.processes.dequeue() catch unreachable;
    return x;
}

fn cwait(self: *Self, c: *Condition) !void {
    return c.wait(self.processes.dequeue() catch return);
}
fn csignal(self: *Self, c: *Condition) !void {
    return self.processes.enqueue(c.signal() catch return);
}
