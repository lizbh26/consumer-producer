const std = @import("std");

const Queue = @import("~").utils.Queue;
const Process = @import("process.zig");

const CSelf = @This();

len: usize,
waitQ: Queue(*Process),

pub fn init(alloc: std.mem.Allocator) !CSelf {
    return .{
        .len = 0,
        .entryQ = try .init(alloc),
        .waitQ = try .init(alloc),
        .signalQ = try .init(alloc),
    };
}

pub fn register(self: *CSelf, p: *Process) !void {
    try self.entryQ.enqueue(p);
    self.len += 1;
}
pub fn wait(self: *CSelf, p: *Process) !void {
    try self.waitQ.enqueue(p);
    self.len += 1;
}
pub fn signal(self: *CSelf) !Process {
    const p = try self.waitQ.dequeue();
    self.len -= 1;
    return p;
}
