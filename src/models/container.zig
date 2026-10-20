const std = @import("std");

const Self = @This();

pub const CONTAINER_SIZE = 20;
pub const CONTAINER_ELEMENT = u32;
fn getNext(n: usize) usize {
    return if (n == CONTAINER_SIZE - 1) 0 else n + 1;
}

pub const ContainerError = error{ WriteOverFlow, ReadUnderFlow, ReadOverFlow };

container: [CONTAINER_SIZE]CONTAINER_ELEMENT = .{},
head: usize = 0,
tail: usize = 0,
len: usize = 0,

pub fn init() Self {
    return .{
        .container = .{},
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

pub fn write(self: *Self, elem: CONTAINER_ELEMENT) ContainerError.WriteOverFlow!void {
    if (self.isFull()) return ContainerError.WriteOverFlow;
    self.container[self.tail] = elem;
    self.tail = getNext(self.tail);

    self.len += 1;
    std.debug.assert(self.len < CONTAINER_SIZE);
}
pub fn read(self: *Self) ContainerError.ReadUnderFlow!CONTAINER_ELEMENT {
    if (self.isEmpty()) return ContainerError.ReadUnderFlow;
    const e = self.container[self.head];
    self.head = getNext(self.head);

    std.debug.assert(self.len > 0);
    self.len -= 1;

    return e;
}

pub fn get(self: *Self, n: usize) !CONTAINER_ELEMENT {
    if (n > self.len) return ContainerError.ReadOverFlow;

    var i = n + self.head;
    if (i >= CONTAINER_SIZE) i -= CONTAINER_SIZE;
    std.debug.assert(i <= self.tail);

    return self.container[i];
}
