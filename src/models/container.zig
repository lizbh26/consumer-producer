const std = @import("std");

const Self = @This();

pub const CONTAINER_SIZE = 20;
pub const CONTAINER_ELEMENT = u32;

pub const ContainerError = error{ WriteOverFlow, ReadUnderFlow, ReadOverFlow };

buffer: [CONTAINER_SIZE]CONTAINER_ELEMENT,
head: usize,
tail: usize,
len: usize,

pub fn init() Self {
    return .{
        .buffer = [_]CONTAINER_ELEMENT{0} ** CONTAINER_SIZE,
        .head = 0,
        .tail = 0,
        .len = 0,
    };
}

pub fn isEmpty(self: Self) bool {
    return self.len == 0;
}
pub fn isFull(self: Self) bool {
    return self.len == CONTAINER_SIZE - 1;
}

pub fn getNext(_: Self, n: usize) usize {
    return if (n == CONTAINER_SIZE - 1) 0 else n + 1;
}

pub fn write(self: *Self, elem: CONTAINER_ELEMENT) !void {
    if (self.isFull()) return ContainerError.WriteOverFlow;
    self.buffer[self.tail] = elem;
    self.tail = self.getNext(self.tail);

    self.len += 1;
    std.debug.assert(self.len < CONTAINER_SIZE);
}
pub fn read(self: *Self) !CONTAINER_ELEMENT {
    if (self.isEmpty()) return ContainerError.ReadUnderFlow;
    const e = self.buffer[self.head];
    self.head = self.getNext(self.head);

    std.debug.assert(self.len > 0);
    self.len -= 1;

    return e;
}

pub fn get(self: *Self, n: usize) !CONTAINER_ELEMENT {
    if (n > self.len) return ContainerError.ReadOverFlow;

    var i = n + self.head;
    if (i >= CONTAINER_SIZE) i -= CONTAINER_SIZE;

    return self.buffer[i];
}
