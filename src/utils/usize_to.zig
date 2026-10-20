const std = @import("std");
pub fn usizeTo(comptime T: type, v: usize) T {
    const min = @min(v, @as(usize, std.math.maxInt(T)));
    return @intCast(min);
}
