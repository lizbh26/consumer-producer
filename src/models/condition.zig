const std = @import("std");

const Queue = @import("../utils/queue.zig").Queue;
const Process = @import("process.zig");

const CSelf = @This();

len: usize,
waitQ: Queue(Process),

pub fn init(alloc: std.mem.Allocator) !CSelf {
    return .{
        .len = 0,
        .waitQ = try .init(alloc),
    };
}

pub fn wait(self: *CSelf, p: *Process) !void {
    try self.waitQ.enqueue(p); // Fails if no memory is left to enqueue
    self.len += 1;
}
pub fn signal(self: *CSelf) !*Process {
    const p = try self.waitQ.dequeue(); // Fails if no processes are waiting
    self.len -= 1;
    return p;
}
