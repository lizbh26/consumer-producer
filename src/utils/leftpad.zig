const std = @import("std");

const countUtf8 = @import("count_utf8.zig").countUtf8;

pub fn leftpad(str: []const u8, by: usize, with: u8, alloc: std.mem.Allocator) []const u8 {
    const distinct_chars = countUtf8(str);
    const whitespaces = str.len - distinct_chars + by;

    const new_str = alloc.alloc(u8, str.len + whitespaces) catch return str;

    for (0..whitespaces) |i| new_str[i] = with;
    for (str, 0..) |char, i| new_str[i + whitespaces] = char;
    return new_str;
}
