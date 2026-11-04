const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn array_to_str(
    comptime T: type,
    alloc: Allocator,
    arr: []const T,
    toStr: *const fn (alloc: Allocator, x: *const T) error{OutOfMemory}![]const u8,
) ![]const u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    const our_alloc = arena.allocator();

    var str: []u8 = "";
    for (arr, 0..) |x, i| {
        str = try our_alloc.print("{s}{s}{s}", .{
            if (i == 0) "[ " else str,
            try toStr(our_alloc, &x),
            if (i != arr.len - 1) ", " else " ]",
        });
    }
    const res = try alloc.print("{s}", .{str});

    arena.deinit();
    return res;
}
