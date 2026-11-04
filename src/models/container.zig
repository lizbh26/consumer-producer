const std = @import("std");

const Self = @This();

pub const CONTAINER_SIZE = 20;
pub const CONTAINER_ELEMENT = u16;

pub const ContainerError = error{ WriteOverFlow, ReadUnderFlow, ReadOverFlow };

buffer: [CONTAINER_SIZE]CONTAINER_ELEMENT,
head: usize,
tail: usize,
len: usize,
max_len: usize,

pub fn init() Self {
    return .{
        .buffer = @splat(0),
        .head = 0,
        .tail = 0,
        .len = 0,
        .max_len = CONTAINER_SIZE - 1,
    };
}

pub fn isEmpty(self: Self) bool {
    return self.len == 0;
}
pub fn isFull(self: Self) bool {
    return self.len == self.max_len;
}

pub fn getNext(self: Self, n: usize) usize {
    return if (n == self.max_len) 0 else n + 1;
}

pub fn write(self: *Self, elem: CONTAINER_ELEMENT) !void {
    if (self.isFull()) return ContainerError.WriteOverFlow;
    self.buffer[self.tail] = elem;
    self.tail = self.getNext(self.tail);

    self.len += 1;
    std.debug.assert(self.len <= self.max_len);
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
    if (i > self.max_len) i -= self.max_len + 1;

    return self.buffer[i];
}

pub fn elemToHex(alloc: std.mem.Allocator, e: *const CONTAINER_ELEMENT) error{OutOfMemory}![]const u8 {
    var num = e.*;
    var chars = try alloc.alloc(u8, 4);
    chars[0] = '0';
    chars[1] = 'x';

    for (2..chars.len) |i| {
        const hex = num & 0xF;
        chars[i] = switch (hex) {
            0 => '0',
            1 => '1',
            2 => '2',
            3 => '3',
            4 => '4',
            5 => '5',
            6 => '6',
            7 => '7',
            8 => '8',
            9 => '9',
            10 => 'A',
            11 => 'B',
            12 => 'C',
            13 => 'D',
            14 => 'F',
            15 => 'E',
            else => unreachable,
        };
        num >>= 4;
    }
    return chars;
}
